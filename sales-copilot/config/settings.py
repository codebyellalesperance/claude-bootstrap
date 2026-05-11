"""Application configuration loaded from environment variables.

All secrets and tenant-specific identifiers live here. Nothing else in the
codebase should read `os.environ` directly. Values come from a local `.env`
file in development and from the deployment environment in production.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, HttpUrl, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class GraphSettings(BaseSettings):
    """Microsoft Graph (Outlook + Excel) OAuth2 configuration.

    The app uses the OAuth2 authorization code flow with delegated
    permissions so emails are drafted as the signed-in seller. Required
    scopes: ``Mail.ReadWrite`` and ``Files.ReadWrite.All``.
    """

    model_config = SettingsConfigDict(env_prefix="GRAPH_", extra="ignore")

    tenant_id: str = Field(..., description="Azure AD tenant identifier (GUID).")
    client_id: str = Field(..., description="Azure AD app registration client ID.")
    client_secret: SecretStr = Field(..., description="Azure AD app client secret.")
    redirect_uri: HttpUrl = Field(
        ...,
        description="OAuth2 redirect URI registered on the Azure AD app.",
    )
    scopes: str = Field(
        default="Mail.ReadWrite Files.ReadWrite.All offline_access",
        description="Space-delimited list of Graph delegated scopes.",
    )

    @property
    def authority(self) -> str:
        """Return the Azure AD authority URL for this tenant."""
        return f"https://login.microsoftonline.com/{self.tenant_id}"

    @property
    def scope_list(self) -> list[str]:
        """Return scopes as a list, suitable for MSAL calls."""
        return [s for s in self.scopes.split() if s]


class SalesforceSettings(BaseSettings):
    """Salesforce Connected App credentials (client credentials flow).

    Uses the OAuth2 client credentials grant so the service can authenticate
    without an interactive user. The Connected App must have its "Run As"
    user set to an integration user with read/write access to Account,
    Opportunity, Contact, and Task objects.
    """

    model_config = SettingsConfigDict(env_prefix="SALESFORCE_", extra="ignore")

    instance_url: HttpUrl = Field(
        ...,
        description="My Domain URL, e.g. https://yourorg.my.salesforce.com",
    )
    client_id: str = Field(..., description="Connected App consumer key.")
    client_secret: SecretStr = Field(..., description="Connected App consumer secret.")
    api_version: str = Field(
        default="v60.0",
        description="Salesforce REST API version, e.g. v60.0",
    )


class AppSettings(BaseSettings):
    """Top-level application settings.

    Composes Graph and Salesforce settings plus runtime knobs (log level,
    environment). The whole object is built once and cached.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: Literal["development", "staging", "production"] = Field(
        default="development",
        description="Runtime environment; controls logging verbosity.",
    )
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = Field(
        default="INFO",
        description="Root logger level.",
    )
    graph: GraphSettings = Field(default_factory=GraphSettings)
    salesforce: SalesforceSettings = Field(default_factory=SalesforceSettings)


@lru_cache(maxsize=1)
def get_settings() -> AppSettings:
    """Return the cached application settings instance.

    Returns:
        The singleton ``AppSettings`` object. Reads ``.env`` on first call.
    """
    return AppSettings()
