"""Outlook plugin -- draft outbound emails via Microsoft Graph.

This module never sends mail. All operations create or update an
Outlook **draft** under the seller's ``Drafts`` folder. The seller
reviews and sends manually from Outlook.
"""

from __future__ import annotations

import logging
from typing import Any

import httpx
from pydantic import BaseModel, EmailStr, Field

from plugins.graph_auth import GraphAuth

logger = logging.getLogger(__name__)

_GRAPH_BASE = "https://graph.microsoft.com/v1.0"


class OutlookError(Exception):
    """Base exception for Outlook plugin errors."""


class OutlookAPIError(OutlookError):
    """Raised when a Graph mail call returns a non-2xx response."""

    def __init__(self, status_code: int, body: str) -> None:
        """Create an Outlook API error.

        Args:
            status_code: HTTP status from Graph.
            body: Response body (truncated).
        """
        super().__init__(f"Outlook API error {status_code}: {body}")
        self.status_code = status_code
        self.body = body


class DraftRecipient(BaseModel):
    """One recipient on a draft message."""

    email: EmailStr
    name: str | None = None


class DraftEmail(BaseModel):
    """A draft email created in the seller's Outlook drafts folder."""

    id: str = Field(..., description="Graph message ID of the created draft.")
    web_link: str | None = Field(
        default=None,
        description="Deep link to open the draft in Outlook on the web.",
    )
    subject: str
    body_preview: str


class OutlookClient:
    """Async client for creating Outlook drafts via Microsoft Graph."""

    def __init__(self, auth: GraphAuth) -> None:
        """Create an Outlook client.

        Args:
            auth: Shared ``GraphAuth`` instance.
        """
        self._auth = auth
        self._http = httpx.AsyncClient(timeout=30.0)

    async def aclose(self) -> None:
        """Close the underlying HTTP client."""
        await self._http.aclose()

    async def _request(
        self,
        method: str,
        path: str,
        *,
        json_body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Issue an authenticated Graph request.

        Args:
            method: HTTP method.
            path: Path relative to ``/v1.0`` (with leading slash).
            json_body: Optional JSON body.

        Returns:
            Parsed JSON response.

        Raises:
            OutlookAPIError: For any non-2xx response.
        """
        token = await self._auth.get_access_token()
        response = await self._http.request(
            method,
            f"{_GRAPH_BASE}{path}",
            json=json_body,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        if response.status_code >= 300:
            raise OutlookAPIError(response.status_code, response.text[:2000])
        if not response.content:
            return {}
        return response.json()

    async def create_draft(
        self,
        *,
        subject: str,
        body_text: str,
        to: list[DraftRecipient],
        cc: list[DraftRecipient] | None = None,
    ) -> DraftEmail:
        """Create an Outlook draft message.

        Args:
            subject: Subject line. Caller is responsible for length.
            body_text: Plain-text body. Newlines are preserved.
            to: At least one ``DraftRecipient``.
            cc: Optional list of CC recipients.

        Returns:
            A ``DraftEmail`` describing the created draft.

        Raises:
            OutlookError: If ``to`` is empty.
        """
        if not to:
            raise OutlookError("Draft requires at least one To recipient.")

        message: dict[str, Any] = {
            "subject": subject,
            "body": {
                "contentType": "text",
                "content": body_text,
            },
            "toRecipients": [
                {"emailAddress": {"address": r.email, "name": r.name or r.email}}
                for r in to
            ],
        }
        if cc:
            message["ccRecipients"] = [
                {"emailAddress": {"address": r.email, "name": r.name or r.email}}
                for r in cc
            ]

        payload = await self._request(
            "POST",
            "/me/messages",
            json_body=message,
        )
        return DraftEmail(
            id=payload["id"],
            web_link=payload.get("webLink"),
            subject=payload.get("subject", subject),
            body_preview=payload.get("bodyPreview", body_text[:255]),
        )

    async def update_draft_body(self, draft_id: str, body_text: str) -> DraftEmail:
        """Replace the body text of an existing draft.

        Args:
            draft_id: Graph message ID returned by ``create_draft``.
            body_text: New plain-text body.

        Returns:
            The updated ``DraftEmail``.
        """
        payload = await self._request(
            "PATCH",
            f"/me/messages/{draft_id}",
            json_body={
                "body": {"contentType": "text", "content": body_text},
            },
        )
        return DraftEmail(
            id=payload["id"],
            web_link=payload.get("webLink"),
            subject=payload.get("subject", ""),
            body_preview=payload.get("bodyPreview", body_text[:255]),
        )
