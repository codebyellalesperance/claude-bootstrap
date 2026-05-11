"""Shared Microsoft Graph OAuth2 authentication helper.

Outlook and Excel plugins both authenticate against Microsoft Graph with
the same delegated permissions. This module owns the token cache so they
share a single refresh path.

The flow is OAuth2 authorization code with PKCE. The initial sign-in is
done out of band (e.g. via a CLI helper or a dedicated ``/auth`` route)
and the resulting refresh token is persisted in the seller's local
keyring or an equivalent secret store. In this codebase the refresh
token is loaded from ``GRAPH_REFRESH_TOKEN`` for simplicity; production
deployments should swap in a real secret store.
"""

from __future__ import annotations

import logging
import os
import time
from dataclasses import dataclass

import httpx

from config.settings import GraphSettings, get_settings

logger = logging.getLogger(__name__)


class GraphAuthError(Exception):
    """Raised when token acquisition or refresh fails."""


@dataclass
class _CachedToken:
    """In-memory cached access token plus expiry."""

    access_token: str
    expires_at: float


class GraphAuth:
    """Acquire and cache Microsoft Graph access tokens for the seller."""

    def __init__(self, settings: GraphSettings | None = None) -> None:
        """Create the auth helper.

        Args:
            settings: Optional pre-built Graph settings. Defaults to
                ``get_settings().graph``.
        """
        self._settings = settings or get_settings().graph
        self._http = httpx.AsyncClient(timeout=30.0)
        self._cached: _CachedToken | None = None

    async def aclose(self) -> None:
        """Close the underlying HTTP client."""
        await self._http.aclose()

    async def get_access_token(self) -> str:
        """Return a valid Graph access token, refreshing if needed.

        Returns:
            A bearer token suitable for the ``Authorization`` header.

        Raises:
            GraphAuthError: If no refresh token is configured or the
                refresh request fails.
        """
        now = time.time()
        if self._cached and self._cached.expires_at - 60 > now:
            return self._cached.access_token

        refresh_token = os.environ.get("GRAPH_REFRESH_TOKEN")
        if not refresh_token:
            raise GraphAuthError(
                "GRAPH_REFRESH_TOKEN is not set. Run the sign-in flow "
                "described in README.md to obtain one."
            )

        token_url = (
            f"{self._settings.authority}/oauth2/v2.0/token"
        )
        response = await self._http.post(
            token_url,
            data={
                "grant_type": "refresh_token",
                "client_id": self._settings.client_id,
                "client_secret": self._settings.client_secret.get_secret_value(),
                "refresh_token": refresh_token,
                "scope": self._settings.scopes,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        if response.status_code != 200:
            raise GraphAuthError(
                f"Token refresh failed ({response.status_code})"
            )
        payload = response.json()
        expires_in = float(payload.get("expires_in", 3600))
        self._cached = _CachedToken(
            access_token=payload["access_token"],
            expires_at=now + expires_in,
        )
        # Graph rotates refresh tokens. Persist the new one if returned.
        new_refresh = payload.get("refresh_token")
        if new_refresh:
            os.environ["GRAPH_REFRESH_TOKEN"] = new_refresh
        return self._cached.access_token
