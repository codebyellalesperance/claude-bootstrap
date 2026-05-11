"""FastAPI entry point for Sales Copilot.

Exposes three endpoints that mirror the seller's three core workflows:

* ``POST /research``     -- assemble a prospect brief
* ``POST /draft``        -- create an Outlook draft email
* ``POST /update-crm``   -- log activity and update opportunity stage

Business logic lives in the plugins; this module wires them together,
parses requests, and shapes responses.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator, Literal

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, EmailStr, Field

from config.settings import get_settings
from plugins.excel import ExcelClient, ProspectRow
from plugins.graph_auth import GraphAuth
from plugins.outlook import DraftEmail, DraftRecipient, OutlookClient
from plugins.salesforce import (
    Account,
    Contact,
    Opportunity,
    SalesforceAPIError,
    SalesforceClient,
)

logger = logging.getLogger(__name__)


# Stage transitions that are considered forward progress. The list is
# deliberately conservative; the seller can pass ``allow_backward=True``
# to override.
_FORWARD_STAGES: list[str] = [
    "Prospecting",
    "Qualification",
    "Discovery",
    "Proposal",
    "Negotiation",
    "Closed Won",
]


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Initialise and tear down shared plugin clients."""
    settings = get_settings()
    logging.basicConfig(level=settings.log_level)
    graph_auth = GraphAuth(settings.graph)
    app.state.graph_auth = graph_auth
    app.state.salesforce = SalesforceClient(settings.salesforce)
    app.state.outlook = OutlookClient(graph_auth)
    app.state.excel = ExcelClient(graph_auth)
    try:
        yield
    finally:
        await app.state.salesforce.aclose()
        await app.state.outlook.aclose()
        await app.state.excel.aclose()
        await graph_auth.aclose()


app = FastAPI(
    title="Sales Copilot",
    version="0.1.0",
    description=(
        "Sales assistant for a Nasdaq salesperson. Bridges Salesforce, "
        "Outlook, and an Excel prospect list."
    ),
    lifespan=lifespan,
)


def get_salesforce() -> SalesforceClient:
    """FastAPI dependency: shared Salesforce client."""
    return app.state.salesforce


def get_outlook() -> OutlookClient:
    """FastAPI dependency: shared Outlook client."""
    return app.state.outlook


def get_excel() -> ExcelClient:
    """FastAPI dependency: shared Excel client."""
    return app.state.excel


# ---------------------------------------------------------------------------
# /research
# ---------------------------------------------------------------------------


class ResearchRequest(BaseModel):
    """Request body for ``POST /research``."""

    salesforce_account_id: str = Field(
        ..., description="15- or 18-character Salesforce Account ID."
    )
    workbook_item_id: str | None = Field(
        default=None,
        description=(
            "Drive item ID of the prospect-list workbook. If omitted the "
            "Excel section of the brief is skipped."
        ),
    )


class ProspectBrief(BaseModel):
    """Response body for ``POST /research``."""

    account: Account
    open_opportunities: list[Opportunity]
    contacts: list[Contact]
    prospect_row: ProspectRow | None
    deltas: list[str] = Field(
        default_factory=list,
        description=(
            "Human-readable notes describing differences between the "
            "Salesforce snapshot and the prospect-list row."
        ),
    )


def _compute_deltas(
    *,
    opportunities: list[Opportunity],
    row: ProspectRow | None,
) -> list[str]:
    """Compare the latest opportunity stage against the prospect row.

    Args:
        opportunities: Open opportunities for the account.
        row: Prospect-list row for the account, if any.

    Returns:
        A list of human-readable delta strings (empty if nothing notable).
    """
    deltas: list[str] = []
    if row is None or not opportunities:
        return deltas
    latest = opportunities[0]
    if row.stage_estimate and row.stage_estimate != latest.stage_name:
        deltas.append(
            f"Stage drift: Excel says '{row.stage_estimate}', "
            f"Salesforce says '{latest.stage_name}' on opportunity "
            f"{latest.name}."
        )
    return deltas


@app.post("/research", response_model=ProspectBrief)
async def research(
    payload: ResearchRequest,
    salesforce: SalesforceClient = Depends(get_salesforce),
    excel: ExcelClient = Depends(get_excel),
) -> ProspectBrief:
    """Assemble a prospect brief for a single account.

    Pulls the account, its open opportunities, and its contacts from
    Salesforce. If a workbook is provided, also pulls the seller's
    prospect-list row and surfaces deltas.

    Args:
        payload: Parsed request body.
        salesforce: Injected Salesforce client.
        excel: Injected Excel client.

    Returns:
        A populated ``ProspectBrief``.
    """
    try:
        account = await salesforce.get_account(payload.salesforce_account_id)
        opportunities = await salesforce.get_open_opportunities(
            payload.salesforce_account_id
        )
        contacts = await salesforce.get_contacts(payload.salesforce_account_id)
    except SalesforceAPIError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc

    row: ProspectRow | None = None
    if payload.workbook_item_id:
        row = await excel.find_prospect(
            payload.workbook_item_id,
            salesforce_account_id=payload.salesforce_account_id,
        )

    return ProspectBrief(
        account=account,
        open_opportunities=opportunities,
        contacts=contacts,
        prospect_row=row,
        deltas=_compute_deltas(opportunities=opportunities, row=row),
    )


# ---------------------------------------------------------------------------
# /draft
# ---------------------------------------------------------------------------


class DraftRequest(BaseModel):
    """Request body for ``POST /draft``."""

    goal: Literal[
        "intro_meeting",
        "follow_up_demo",
        "reengage_stalled",
        "executive_escalation",
    ] = Field(..., description="Intent of the outreach.")
    brief: ProspectBrief = Field(
        ..., description="Output of ``/research`` for the target account."
    )
    to_email: EmailStr = Field(..., description="Primary recipient email.")
    to_name: str | None = Field(default=None, description="Display name for To.")
    cc_emails: list[EmailStr] = Field(
        default_factory=list, description="Optional CC recipients."
    )


_GOAL_SUBJECT: dict[str, str] = {
    "intro_meeting": "Quick intro: Nasdaq",
    "follow_up_demo": "Following up on our Nasdaq demo",
    "reengage_stalled": "Checking back in on Nasdaq",
    "executive_escalation": "Nasdaq -- executive sync request",
}

_GOAL_OPENER: dict[str, str] = {
    "intro_meeting": (
        "I lead the Nasdaq account team for {industry} issuers and wanted to "
        "introduce myself."
    ),
    "follow_up_demo": (
        "Thanks again for the time on the demo. I wanted to share the next "
        "step we discussed."
    ),
    "reengage_stalled": (
        "I know things have been quiet on our side -- circling back as the "
        "quarter closes."
    ),
    "executive_escalation": (
        "Given the scope of what we discussed, I would like to bring our "
        "executive sponsor into the next conversation."
    ),
}


def _compose_body(goal: str, brief: ProspectBrief) -> str:
    """Compose a plain-text draft body for the given goal and brief.

    The body is intentionally short and references at least one concrete
    data point from the brief. The seller is expected to edit before sending.

    Args:
        goal: One of the supported draft goals.
        brief: The prospect brief returned by ``/research``.

    Returns:
        A plain-text email body.
    """
    industry = brief.account.industry or "growth"
    opener = _GOAL_OPENER[goal].format(industry=industry)

    data_point: str
    if brief.open_opportunities:
        opp = brief.open_opportunities[0]
        amount = (
            f" (~${opp.amount:,.0f})" if opp.amount is not None else ""
        )
        data_point = (
            f"On our side, {opp.name}{amount} is currently at "
            f"'{opp.stage_name}'."
        )
    else:
        data_point = (
            f"We do not yet have an active opportunity on file for "
            f"{brief.account.name}."
        )

    call_to_action = {
        "intro_meeting": "Would a 20-minute intro next week work on your side?",
        "follow_up_demo": "Are you open to a working session to scope the pilot?",
        "reengage_stalled": (
            "Is the original use case still in play, or has the priority shifted?"
        ),
        "executive_escalation": (
            "Could we hold 30 minutes with your executive sponsor in the next "
            "two weeks?"
        ),
    }[goal]

    compliance_note = ""
    if (brief.account.industry or "").lower() in {
        "banking",
        "broker-dealer",
        "insurance",
        "financial services",
    }:
        compliance_note = (
            "\n\nHappy to align the timeline with your compliance review cycle."
        )

    return (
        f"Hi {{first_name}},\n\n"
        f"{opener} {data_point}\n\n"
        f"{call_to_action}{compliance_note}\n\n"
        "Best,\n"
    )


@app.post("/draft", response_model=DraftEmail)
async def draft(
    payload: DraftRequest,
    outlook: OutlookClient = Depends(get_outlook),
) -> DraftEmail:
    """Create an Outlook draft email for the given brief and goal.

    The draft is **never** sent; the seller reviews it in Outlook.

    Args:
        payload: Parsed request body.
        outlook: Injected Outlook client.

    Returns:
        The created ``DraftEmail`` (Graph message ID and web link).
    """
    subject = _GOAL_SUBJECT[payload.goal]
    body = _compose_body(payload.goal, payload.brief)
    to = [DraftRecipient(email=payload.to_email, name=payload.to_name)]
    cc = [DraftRecipient(email=e) for e in payload.cc_emails]
    return await outlook.create_draft(
        subject=subject,
        body_text=body,
        to=to,
        cc=cc or None,
    )


# ---------------------------------------------------------------------------
# /update-crm
# ---------------------------------------------------------------------------


class CrmUpdateRequest(BaseModel):
    """Request body for ``POST /update-crm``."""

    opportunity_id: str = Field(..., description="Salesforce Opportunity ID.")
    activity_subject: str = Field(
        ..., description="Short subject for the logged activity (Task)."
    )
    activity_description: str = Field(
        ..., description="Long-form notes captured by the seller."
    )
    new_stage: str | None = Field(
        default=None,
        description="Optional new ``StageName`` value. Omit to leave unchanged.",
    )
    current_stage: str | None = Field(
        default=None,
        description=(
            "Current stage as observed by the caller. Used to validate that "
            "the proposed transition is forward unless ``allow_backward`` is "
            "set."
        ),
    )
    allow_backward: bool = Field(
        default=False,
        description="Set true to permit a backward stage transition.",
    )


class CrmUpdateResponse(BaseModel):
    """Response body for ``POST /update-crm``."""

    opportunity_id: str
    new_stage: str | None
    task_id: str | None
    composite_response: dict


def _validate_stage_transition(
    *, current: str | None, target: str | None, allow_backward: bool
) -> None:
    """Reject backward transitions unless explicitly allowed.

    Args:
        current: Stage the caller believes is current.
        target: Proposed new stage.
        allow_backward: Override flag.

    Raises:
        HTTPException: 400 if a backward transition is attempted without
            the override flag.
    """
    if target is None or current is None or allow_backward:
        return
    if target not in _FORWARD_STAGES or current not in _FORWARD_STAGES:
        return
    if _FORWARD_STAGES.index(target) < _FORWARD_STAGES.index(current):
        raise HTTPException(
            status_code=400,
            detail=(
                f"Refusing backward stage transition "
                f"'{current}' -> '{target}'. Pass allow_backward=true to override."
            ),
        )


@app.post("/update-crm", response_model=CrmUpdateResponse)
async def update_crm(
    payload: CrmUpdateRequest,
    salesforce: SalesforceClient = Depends(get_salesforce),
) -> CrmUpdateResponse:
    """Log an activity and optionally advance the opportunity stage.

    Uses the Salesforce composite endpoint so the Task insert and the
    Opportunity update succeed or fail together.

    Args:
        payload: Parsed request body.
        salesforce: Injected Salesforce client.

    Returns:
        A ``CrmUpdateResponse`` describing what changed.
    """
    _validate_stage_transition(
        current=payload.current_stage,
        target=payload.new_stage,
        allow_backward=payload.allow_backward,
    )
    try:
        result = await salesforce.log_activity_and_update_stage(
            opportunity_id=payload.opportunity_id,
            subject=payload.activity_subject,
            description=payload.activity_description,
            new_stage=payload.new_stage,
        )
    except SalesforceAPIError as exc:
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc

    task_id: str | None = None
    for sub in result.get("compositeResponse", []):
        if sub.get("referenceId") == "newTask":
            task_id = sub.get("body", {}).get("id")
    return CrmUpdateResponse(
        opportunity_id=payload.opportunity_id,
        new_stage=payload.new_stage,
        task_id=task_id,
        composite_response=result,
    )


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    """Liveness probe.

    Returns:
        A small status payload.
    """
    return {"status": "ok"}
