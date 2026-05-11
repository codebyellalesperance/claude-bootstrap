# Sales Copilot

An enterprise sales assistant for a Nasdaq, Inc. salesperson. Bridges
Salesforce, Outlook, and an Excel prospect list stored in OneDrive.
GitHub Copilot is the AI layer; see `.github/copilot-instructions.md`
for the persona and behavior rules.

## What it does

Three workflows, one per endpoint:

| Endpoint        | Purpose                                                      |
| --------------- | ------------------------------------------------------------ |
| `POST /research`   | Pull account, opportunities, contacts, and prospect-list row; surface deltas. |
| `POST /draft`      | Compose an Outlook draft email tailored to a goal. Drafts only, never sent. |
| `POST /update-crm` | Log an activity and (optionally) update opportunity stage atomically.       |

## Stack

- Python 3.11+, FastAPI, httpx
- Microsoft Graph (delegated permissions): `Mail.ReadWrite`, `Files.ReadWrite.All`
- Salesforce REST API via OAuth2 client credentials
- GitHub Copilot for in-editor AI assistance (see `.github/copilot-instructions.md`)

## Project layout

```
sales-copilot/
  .github/
    copilot-instructions.md   # Copilot persona, tone, task instructions
  api/
    main.py                   # FastAPI app and three endpoints
  config/
    settings.py               # Pydantic Settings, .env loader
  plugins/
    salesforce.py             # SOQL + REST + composite writes
    outlook.py                # Graph mail drafts
    excel.py                  # Graph Excel workbook session API
    graph_auth.py             # Shared Graph OAuth2 token cache
  prompts/
    system.md                 # Sales agent persona (long form)
  .env.example
  .gitignore
  requirements.txt
  README.md
```

## Setup

### 1. Clone and install

```
git clone <this repo>
cd sales-copilot
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Fill in `.env` using the steps below.

### 2. Azure AD app (Microsoft Graph)

1. Go to <https://portal.azure.com> -> **Microsoft Entra ID** ->
   **App registrations** -> **New registration**.
2. Pick "Accounts in this organizational directory only" and add the
   redirect URI `http://localhost:8000/auth/callback` (Web platform).
3. On the app **Overview**, copy:
   - **Application (client) ID** -> `GRAPH_CLIENT_ID`
   - **Directory (tenant) ID** -> `GRAPH_TENANT_ID`
4. **Certificates & secrets** -> **New client secret**. Copy the **Value**
   (not the ID) into `GRAPH_CLIENT_SECRET`. You will not be able to view it again.
5. **API permissions** -> **Add a permission** -> **Microsoft Graph** ->
   **Delegated permissions**. Add:
   - `Mail.ReadWrite`
   - `Files.ReadWrite.All`
   - `offline_access`
6. Click **Grant admin consent** for the tenant.

### 3. First-run Microsoft Graph sign-in

The app uses a refresh token for the Graph delegated flow. To obtain one:

```
python -m scripts.graph_signin   # not included; minimal helper to run locally
```

Or do it manually via the device code flow with `msal`:

```python
import msal, os
app = msal.PublicClientApplication(
    os.environ["GRAPH_CLIENT_ID"],
    authority=f"https://login.microsoftonline.com/{os.environ['GRAPH_TENANT_ID']}",
)
flow = app.initiate_device_flow(scopes=os.environ["GRAPH_SCOPES"].split())
print(flow["message"])
result = app.acquire_token_by_device_flow(flow)
print("refresh_token:", result["refresh_token"])
```

Copy the printed `refresh_token` into `GRAPH_REFRESH_TOKEN` in `.env`.

### 4. Salesforce Connected App

1. In Salesforce, **Setup** -> **App Manager** -> **New Connected App**.
2. Enable OAuth Settings with callback `http://localhost` (unused but
   required) and scopes:
   - `Manage user data via APIs (api)`
   - `Perform requests at any time (refresh_token, offline_access)`
3. After save, **Manage Consumer Details** -> copy:
   - **Consumer Key** -> `SALESFORCE_CLIENT_ID`
   - **Consumer Secret** -> `SALESFORCE_CLIENT_SECRET`
4. **Manage** -> **Edit Policies**:
   - Permitted Users: **Admin approved users are pre-authorized**
   - OAuth Policies: set the **Run As** user to a dedicated integration user
     with read/write access to `Account`, `Opportunity`, `Contact`, and `Task`.
5. **My Domain URL** (Setup -> My Domain) -> `SALESFORCE_INSTANCE_URL`.

### 5. Excel prospect list

The Excel plugin expects a workbook in the seller's OneDrive with a
formatted table named `Prospects` containing at least these columns:

- `Account Name`
- `Salesforce Account ID`
- `Stage Estimate`
- `Next Touch Date`
- `Owner Notes`

To find the workbook's drive item ID, open it in Excel for the web and
inspect the URL, or call `GET /me/drive/root:/path/to/Prospects.xlsx`.

## Running locally

```
uvicorn api.main:app --reload --port 8000
```

Open <http://localhost:8000/docs> for the interactive API explorer.

## Example calls

Research:

```
curl -X POST http://localhost:8000/research \
  -H "Content-Type: application/json" \
  -d '{"salesforce_account_id":"001XXXXXXXXXXXX","workbook_item_id":"01ABCD..."}'
```

Draft (using the brief returned by `/research`):

```
curl -X POST http://localhost:8000/draft \
  -H "Content-Type: application/json" \
  -d '{
        "goal":"intro_meeting",
        "to_email":"cfo@example.com",
        "to_name":"Jordan Lee",
        "brief": { ... output of /research ... }
      }'
```

Update CRM:

```
curl -X POST http://localhost:8000/update-crm \
  -H "Content-Type: application/json" \
  -d '{
        "opportunity_id":"006XXXXXXXXXXXX",
        "activity_subject":"Discovery call",
        "activity_description":"Confirmed budget owner; next step is technical demo.",
        "current_stage":"Qualification",
        "new_stage":"Discovery"
      }'
```

## Security and operational notes

- Secrets live only in `.env`, which is gitignored. The `pydantic-settings`
  layer prevents accidental serialization (`SecretStr` is used for client secrets).
- Outlook integration only creates **drafts**. There is no code path
  that calls `sendMail`.
- `/update-crm` rejects backward stage transitions unless
  `allow_backward=true` is passed. The Task insert and Opportunity
  update use the Salesforce `composite` endpoint with `allOrNone=true`
  so partial writes cannot occur.
- All logging goes through the stdlib `logging` module; no secrets are
  ever logged.

## License

Internal tooling, not for redistribution.
