"""Excel plugin -- read and write prospect lists stored in OneDrive.

Backed by the Microsoft Graph Excel workbook session API
(``/me/drive/items/{id}/workbook``). A workbook session is opened
per-request so concurrent edits do not collide.

The seller keeps a working sheet (typically named ``Prospects``) where
each row represents one account and columns capture the seller's notes,
next-touch dates, and stage estimates that have not yet been written
back to Salesforce.
"""

from __future__ import annotations

import logging
from typing import Any

import httpx
from pydantic import BaseModel

from plugins.graph_auth import GraphAuth

logger = logging.getLogger(__name__)

_GRAPH_BASE = "https://graph.microsoft.com/v1.0"


class ExcelError(Exception):
    """Base exception for Excel plugin errors."""


class ExcelAPIError(ExcelError):
    """Raised when a Graph Excel call returns a non-2xx response."""

    def __init__(self, status_code: int, body: str) -> None:
        """Create an Excel API error.

        Args:
            status_code: HTTP status from Graph.
            body: Response body (truncated).
        """
        super().__init__(f"Excel API error {status_code}: {body}")
        self.status_code = status_code
        self.body = body


class ProspectRow(BaseModel):
    """One row from the seller's prospect list.

    Column names are normalized to snake_case. Unknown columns are
    captured in ``extra`` so the caller can surface them without losing
    fidelity.
    """

    account_name: str
    salesforce_account_id: str | None = None
    stage_estimate: str | None = None
    next_touch_date: str | None = None
    owner_notes: str | None = None
    extra: dict[str, Any] = {}


class ExcelClient:
    """Async client for reading and writing prospect rows via Graph."""

    def __init__(self, auth: GraphAuth) -> None:
        """Create an Excel client.

        Args:
            auth: Shared ``GraphAuth`` instance for token acquisition.
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
        session_id: str | None = None,
    ) -> dict[str, Any]:
        """Issue an authenticated Graph request.

        Args:
            method: HTTP method.
            path: Path relative to ``/v1.0``, starting with ``/``.
            json_body: Optional JSON body.
            session_id: Optional ``workbook-session-id`` header value.

        Returns:
            Parsed JSON response, or empty dict for 204 responses.

        Raises:
            ExcelAPIError: For any non-2xx response.
        """
        token = await self._auth.get_access_token()
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        if session_id:
            headers["workbook-session-id"] = session_id
        response = await self._http.request(
            method, f"{_GRAPH_BASE}{path}", json=json_body, headers=headers
        )
        if response.status_code >= 300:
            raise ExcelAPIError(response.status_code, response.text[:2000])
        if response.status_code == 204 or not response.content:
            return {}
        return response.json()

    async def _open_session(self, workbook_item_id: str) -> str:
        """Open a workbook session and return its ID.

        Args:
            workbook_item_id: The Drive item ID of the .xlsx file.

        Returns:
            The session ID to pass on subsequent calls.
        """
        payload = await self._request(
            "POST",
            f"/me/drive/items/{workbook_item_id}/workbook/createSession",
            json_body={"persistChanges": True},
        )
        return str(payload["id"])

    async def list_prospects(
        self, workbook_item_id: str, table_name: str = "Prospects"
    ) -> list[ProspectRow]:
        """Read all rows of the prospect table.

        The workbook is expected to contain a formatted table (Insert >
        Table) named ``Prospects`` with columns: ``Account Name``,
        ``Salesforce Account ID``, ``Stage Estimate``, ``Next Touch Date``,
        and ``Owner Notes``. Additional columns are preserved in
        ``ProspectRow.extra``.

        Args:
            workbook_item_id: Drive item ID of the workbook.
            table_name: Name of the Excel table to read.

        Returns:
            A list of ``ProspectRow`` records.
        """
        session_id = await self._open_session(workbook_item_id)
        columns = await self._request(
            "GET",
            (
                f"/me/drive/items/{workbook_item_id}/workbook/tables/"
                f"{table_name}/columns"
            ),
            session_id=session_id,
        )
        column_names: list[str] = [c["name"] for c in columns.get("value", [])]

        rows = await self._request(
            "GET",
            (
                f"/me/drive/items/{workbook_item_id}/workbook/tables/"
                f"{table_name}/rows"
            ),
            session_id=session_id,
        )

        result: list[ProspectRow] = []
        for row in rows.get("value", []):
            values = row.get("values", [[]])[0]
            mapped = dict(zip(column_names, values, strict=False))
            known = {
                "account_name": mapped.pop("Account Name", "") or "",
                "salesforce_account_id": mapped.pop("Salesforce Account ID", None),
                "stage_estimate": mapped.pop("Stage Estimate", None),
                "next_touch_date": mapped.pop("Next Touch Date", None),
                "owner_notes": mapped.pop("Owner Notes", None),
            }
            result.append(ProspectRow(**known, extra=mapped))
        return result

    async def find_prospect(
        self,
        workbook_item_id: str,
        *,
        salesforce_account_id: str,
        table_name: str = "Prospects",
    ) -> ProspectRow | None:
        """Locate a single prospect row by Salesforce Account ID.

        Args:
            workbook_item_id: Drive item ID of the workbook.
            salesforce_account_id: Salesforce Account ID to match.
            table_name: Name of the Excel table to scan.

        Returns:
            The matching ``ProspectRow``, or ``None`` if not found.
        """
        for row in await self.list_prospects(workbook_item_id, table_name):
            if row.salesforce_account_id == salesforce_account_id:
                return row
        return None

    async def append_note(
        self,
        workbook_item_id: str,
        *,
        salesforce_account_id: str,
        note: str,
        table_name: str = "Prospects",
    ) -> None:
        """Append a dated note to the ``Owner Notes`` cell for a prospect.

        Notes are append-only so the seller's prior context is not lost.
        If the row does not exist, ``ExcelError`` is raised; row creation
        is a deliberate caller decision and is not done implicitly here.

        Args:
            workbook_item_id: Drive item ID of the workbook.
            salesforce_account_id: Salesforce Account ID to locate.
            note: Free-form note to append.
            table_name: Name of the Excel table.

        Raises:
            ExcelError: If the prospect row is not found.
        """
        session_id = await self._open_session(workbook_item_id)
        columns = await self._request(
            "GET",
            (
                f"/me/drive/items/{workbook_item_id}/workbook/tables/"
                f"{table_name}/columns"
            ),
            session_id=session_id,
        )
        column_names: list[str] = [c["name"] for c in columns.get("value", [])]
        rows = await self._request(
            "GET",
            (
                f"/me/drive/items/{workbook_item_id}/workbook/tables/"
                f"{table_name}/rows"
            ),
            session_id=session_id,
        )

        sf_index = column_names.index("Salesforce Account ID")
        notes_index = column_names.index("Owner Notes")

        for row in rows.get("value", []):
            values = row.get("values", [[]])[0]
            if values[sf_index] != salesforce_account_id:
                continue
            existing = values[notes_index] or ""
            updated = f"{existing}\n{note}".strip()
            row_index = row["index"]
            new_values = list(values)
            new_values[notes_index] = updated
            await self._request(
                "PATCH",
                (
                    f"/me/drive/items/{workbook_item_id}/workbook/tables/"
                    f"{table_name}/rows/itemAt(index={row_index})"
                ),
                json_body={"values": [new_values]},
                session_id=session_id,
            )
            return
        raise ExcelError(
            f"No prospect row found for Salesforce ID {salesforce_account_id}"
        )
