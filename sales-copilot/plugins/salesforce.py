"""Salesforce REST API plugin.

Provides typed access to the records Sales Copilot reads and writes:
``Account``, ``Opportunity``, ``Contact``, and ``Task`` (used to log
activities). Uses the OAuth2 client credentials grant configured on a
Salesforce Connected App.

All public functions are async and reuse a single ``httpx.AsyncClient``
acquired per ``SalesforceClient`` instance.
"""

from __future__ import annotations

import logging
import time
from dataclasses import dataclass
from typing import Any

import httpx
from pydantic import BaseModel, Field

from config.settings import SalesforceSettings, get_settings

logger = logging.getLogger(__name__)


class SalesforceError(Exception):
    """Base exception for Salesforce plugin errors."""


class SalesforceAuthError(SalesforceError):
    """Raised when the OAuth2 token exchange fails."""


class SalesforceAPIError(SalesforceError):
    """Raised when a Salesforce REST call returns a non-2xx response."""

    def __init__(self, status_code: int, body: str) -> None:
        """Create a Salesforce API error.

        Args:
            status_code: HTTP status code returned by Salesforce.
            body: Raw response body (truncated by caller if needed).
        """
        super().__init__(f"Salesforce API error {status_code}: {body}")
        self.status_code = status_code
        self.body = body


class Account(BaseModel):
    """A subset of the Salesforce ``Account`` object relevant to outreach."""

    id: str = Field(..., alias="Id")
    name: str = Field(..., alias="Name")
    industry: str | None = Field(default=None, alias="Industry")
    website: str | None = Field(default=None, alias="Website")
    annual_revenue: float | None = Field(default=None, alias="AnnualRevenue")
    number_of_employees: int | None = Field(default=None, alias="NumberOfEmployees")
    billing_country: str | None = Field(default=None, alias="BillingCountry")

    model_config = {"populate_by_name": True}


class Opportunity(BaseModel):
    """A subset of the Salesforce ``Opportunity`` object."""

    id: str = Field(..., alias="Id")
    name: str = Field(..., alias="Name")
    account_id: str = Field(..., alias="AccountId")
    stage_name: str = Field(..., alias="StageName")
    amount: float | None = Field(default=None, alias="Amount")
    close_date: str | None = Field(default=None, alias="CloseDate")
    last_modified_date: str | None = Field(default=None, alias="LastModifiedDate")

    model_config = {"populate_by_name": True}


class Contact(BaseModel):
    """A subset of the Salesforce ``Contact`` object."""

    id: str = Field(..., alias="Id")
    account_id: str | None = Field(default=None, alias="AccountId")
    first_name: str | None = Field(default=None, alias="FirstName")
    last_name: str = Field(..., alias="LastName")
    title: str | None = Field(default=None, alias="Title")
    email: str | None = Field(default=None, alias="Email")

    model_config = {"populate_by_name": True}


@dataclass
class _Token:
    """Cached OAuth2 access token with expiry tracking."""

    access_token: str
    expires_at: float


class SalesforceClient:
    """Thin async wrapper over the Salesforce REST API.

    The client is intended to live for the lifetime of the FastAPI app and
    be injected as a dependency. It caches its access token until ~30s
    before expiry.
    """

    def __init__(self, settings: SalesforceSettings | None = None) -> None:
        """Create a Salesforce client.

        Args:
            settings: Optional pre-built settings. Defaults to global config.
        """
        self._settings = settings or get_settings().salesforce
        self._http = httpx.AsyncClient(timeout=30.0)
        self._token: _Token | None = None

    async def aclose(self) -> None:
        """Close the underlying HTTP client."""
        await self._http.aclose()

    async def _get_token(self) -> str:
        """Return a valid access token, fetching a new one if needed.

        Returns:
            A valid Salesforce OAuth2 access token.

        Raises:
            SalesforceAuthError: If the token endpoint rejects the request.
        """
        now = time.time()
        if self._token and self._token.expires_at - 30 > now:
            return self._token.access_token

        token_url = f"{self._settings.instance_url}/services/oauth2/token"
        response = await self._http.post(
            str(token_url),
            data={
                "grant_type": "client_credentials",
                "client_id": self._settings.client_id,
                "client_secret": self._settings.client_secret.get_secret_value(),
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        if response.status_code != 200:
            raise SalesforceAuthError(
                f"Token request failed ({response.status_code})"
            )
        payload = response.json()
        # Salesforce returns issued_at and a fixed lifetime via JWT;
        # client credentials tokens default to ~30 minutes. Assume 25 to be safe.
        expires_in = float(payload.get("expires_in", 1500))
        self._token = _Token(
            access_token=payload["access_token"],
            expires_at=now + expires_in,
        )
        return self._token.access_token

    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json_body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Issue an authenticated REST call.

        Args:
            method: HTTP verb (``GET``, ``POST``, ``PATCH``).
            path: Path relative to ``/services/data/<version>``, with leading slash.
            params: Optional query parameters.
            json_body: Optional JSON request body.

        Returns:
            Parsed JSON response body.

        Raises:
            SalesforceAPIError: For any non-2xx response.
        """
        token = await self._get_token()
        url = (
            f"{self._settings.instance_url}/services/data/"
            f"{self._settings.api_version}{path}"
        )
        response = await self._http.request(
            method,
            url,
            params=params,
            json=json_body,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        if response.status_code >= 300:
            raise SalesforceAPIError(response.status_code, response.text[:2000])
        if not response.content:
            return {}
        return response.json()

    async def query(self, soql: str) -> list[dict[str, Any]]:
        """Run a SOQL query and return the records list.

        Args:
            soql: A SOQL query string.

        Returns:
            The list of records (without paging continuation).
        """
        payload = await self._request("GET", "/query", params={"q": soql})
        return list(payload.get("records", []))

    async def get_account(self, account_id: str) -> Account:
        """Fetch a single account by ID.

        Args:
            account_id: Salesforce 15- or 18-character Account ID.

        Returns:
            The parsed ``Account`` model.
        """
        soql = (
            "SELECT Id, Name, Industry, Website, AnnualRevenue, "
            "NumberOfEmployees, BillingCountry "
            f"FROM Account WHERE Id = '{account_id}' LIMIT 1"
        )
        records = await self.query(soql)
        if not records:
            raise SalesforceAPIError(404, f"Account {account_id} not found")
        return Account.model_validate(records[0])

    async def get_open_opportunities(self, account_id: str) -> list[Opportunity]:
        """Return open opportunities for an account.

        Excludes ``Closed Won`` and ``Closed Lost`` stages.

        Args:
            account_id: Salesforce Account ID.

        Returns:
            List of ``Opportunity`` models, ordered by most recently modified.
        """
        soql = (
            "SELECT Id, Name, AccountId, StageName, Amount, CloseDate, "
            "LastModifiedDate FROM Opportunity "
            f"WHERE AccountId = '{account_id}' "
            "AND StageName NOT IN ('Closed Won', 'Closed Lost') "
            "ORDER BY LastModifiedDate DESC"
        )
        records = await self.query(soql)
        return [Opportunity.model_validate(r) for r in records]

    async def get_contacts(self, account_id: str) -> list[Contact]:
        """Return contacts associated with an account.

        Args:
            account_id: Salesforce Account ID.

        Returns:
            List of ``Contact`` models.
        """
        soql = (
            "SELECT Id, AccountId, FirstName, LastName, Title, Email "
            f"FROM Contact WHERE AccountId = '{account_id}' "
            "ORDER BY LastName ASC"
        )
        records = await self.query(soql)
        return [Contact.model_validate(r) for r in records]

    async def log_activity_and_update_stage(
        self,
        *,
        opportunity_id: str,
        subject: str,
        description: str,
        new_stage: str | None,
    ) -> dict[str, Any]:
        """Log a Task and (optionally) update opportunity stage atomically.

        Uses the Salesforce composite endpoint so either both writes
        succeed or both fail.

        Args:
            opportunity_id: Opportunity to attach the activity to.
            subject: Short subject for the Task (max 255 chars).
            description: Long-form notes from the seller.
            new_stage: New ``StageName`` value, or ``None`` to leave unchanged.

        Returns:
            The composite endpoint response payload.
        """
        sub_requests: list[dict[str, Any]] = [
            {
                "method": "POST",
                "url": f"/services/data/{self._settings.api_version}/sobjects/Task",
                "referenceId": "newTask",
                "body": {
                    "WhatId": opportunity_id,
                    "Subject": subject[:255],
                    "Description": description,
                    "Status": "Completed",
                    "Priority": "Normal",
                },
            }
        ]
        if new_stage is not None:
            sub_requests.append(
                {
                    "method": "PATCH",
                    "url": (
                        f"/services/data/{self._settings.api_version}"
                        f"/sobjects/Opportunity/{opportunity_id}"
                    ),
                    "referenceId": "updateOpp",
                    "body": {"StageName": new_stage},
                }
            )
        return await self._request(
            "POST",
            "/composite",
            json_body={"allOrNone": True, "compositeRequest": sub_requests},
        )
