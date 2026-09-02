---
name: dynamics-webapi
description: Read-only Dynamics 365 and Dataverse Web API access from the shell. Use for WhoAmI and health checks, listing entity sets, reading entity metadata, and querying records with OData. Reuses local tokens first (./token.json, OpenDataverse, ~/.dynamics), then falls back to Azure CLI login.
---

# Dynamics 365 Web API

Read-only GET access to a Dataverse environment through one Python script that needs only the standard library. It never creates, updates, or deletes records.

```bash
python3 ~/.agents/skills/personal/dynamics-webapi/scripts/dynamics_api.py <org-url-or-host> <action> [resource]
```

On Windows use `python` or `py`. The TypeScript twin, `npx tsx .../scripts/dynamics-api.ts`, behaves the same and is only worth using when Node tooling is already warm.

## Environment URL

The first argument is the organisation. `contoso.crm.dynamics.com`, `https://contoso.crm.dynamics.com`, and `https://contoso.crm.dynamics.com/api/data/v9.2` all normalise to `https://contoso.crm.dynamics.com`.

When the user names an environment instead of a URL ("AGI UAT", "E6 Prod"), look it up in `~/.OpenDataverse/config.json`. Its `environments` list maps display names to URLs. Several clients have Dev, UAT, QA, and Prod entries, so confirm which one when the user's wording does not pin it down.

## Actions

| Action | Does |
| --- | --- |
| `whoami` | Returns `UserId`, `BusinessUnitId`, `OrganizationId`. Fastest way to confirm auth. |
| `health` | WhoAmI, token expiry and tenant, and an entity-set count. |
| `get <path>` | GET a collection, record, or absolute URL. Prints `Records: n`, the JSON, and `Next page: <url>` when more exist. |
| `list` | All entity set names and URLs. |
| `metadata [logicalname]` | All entity definitions, or one entity's full definition. |

`get` prepends `/api/data/v9.2/` unless the path starts with `http` or `api/`. Paging: pass the printed `@odata.nextLink` back to `get`.

```bash
python3 ~/.agents/skills/personal/dynamics-webapi/scripts/dynamics_api.py contoso.crm.dynamics.com whoami
python3 ~/.agents/skills/personal/dynamics-webapi/scripts/dynamics_api.py contoso.crm.dynamics.com get 'accounts?$select=name,accountid&$orderby=createdon desc&$top=5'
python3 ~/.agents/skills/personal/dynamics-webapi/scripts/dynamics_api.py contoso.crm.dynamics.com get 'accounts(00000000-0000-0000-0000-000000000000)?$select=name'
python3 ~/.agents/skills/personal/dynamics-webapi/scripts/dynamics_api.py contoso.crm.dynamics.com metadata account
```

Quote the query in single quotes so the shell leaves `$select` alone. Spaces and other unsafe characters are percent-encoded by the script, so write OData as you would in a browser. Common parameters: `$select`, `$filter`, `$orderby`, `$top`, `$expand`, `$count=true`. Keep `$top` small on large tables; Dataverse throttles.

## Authentication

Token sources, in order. The first valid one wins.

1. `./token.json` in the current directory, Azure CLI shape, not expired.
2. `~/.OpenDataverse/config.json` matched by environment URL, with the token in `~/.OpenDataverse/tokens/token-<environmentId>.json`. An expired token is refreshed with its stored `refreshToken` against the Entra token endpoint using scope `<org-url>/user_impersonation offline_access`, and the file is rewritten.
3. `~/.dynamics/token.json`, Azure CLI shape.
4. Azure CLI. Runs `az login --allow-no-subscriptions` (pass `--tenant <id-or-domain>` to the script when the account spans tenants), then `az account get-access-token --resource <org-url>`. The result is written to `~/.dynamics/token.json` if that file existed, otherwise to `./token.json`.

Azure CLI login opens a browser and blocks until the user finishes signing in. Say so before triggering it. If no expiry can be read from a token file, the script treats the token as expired.

Azure CLI token shape:

```json
{ "accessToken": "...", "expiresOn": "2026-05-11 11:46:39.000000", "expires_on": 0, "tokenType": "Bearer", "tenant": "", "subscription": "" }
```

OpenDataverse token shape:

```json
{ "accessToken": "...", "refreshToken": "...", "expiresAt": 1781874173 }
```

## Limits

- Read-only. For writes, or for anything that touches solutions or components, stop and follow the Dynamics rules in `~/.agents/AGENTS.md`.
- Never paste tokens into notes, chat, or commits. Token files may already sit in the repo root as `token.json`; do not add them to git.
