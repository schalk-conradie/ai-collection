---
name: document-branium
description: Create or update project and Home notes in the user's Obsidian vault, The Brainium, at ~/Documents/The Brainium. Use when the user says "document this in the branium", "add this to my second brain", or asks to capture project or client context, implementation notes, decisions, fixes, meeting notes, or household information such as todos, shopping lists, documents, maintenance, or inventory.
---

# Document Branium

Turn the current work or conversation into one short note in the right place in the vault. The note should still be useful in six months and should not duplicate an existing note.

## Vault layout

The vault root is `~/Documents/The Brainium` on every machine. `BRAINIUM_VAULT` or `--vault` overrides it.

| Path | Purpose |
| --- | --- |
| `10 Clients/<Client>/Projects/<Client code> - <Project>/` | Client and project work. Notes go in `Changes`, `Decisions`, or `Notes` under the project. |
| `100 Home/` | Household second brain. Not a client or project. |
| `90 Templates/` | Note templates. Home templates are under `90 Templates/Home` and are prefixed with `Home`. |
| `99 Meta/project-registry.json` | Routing registry for project notes. Maps `repoPath` to `client`, `project`, and `projectFolder`. |
| `AGENTS.md` | Vault conventions. Read it when a convention here is unclear. |

Client codes in folder names:

| Code | Client |
| --- | --- |
| AGR | Allan Gray Retail |
| AGI | Allan Gray Institutional |
| E6 | Element 6 |
| EC | Enterprise cloud |
| SBS | SBS (Stellenbosch Business School is an accepted alias) |

When clear repo, folder, or vault evidence reveals a new code, update this table, the same table in `~/.agents/skills/personal/search-branium/SKILL.md`, and the vault `AGENTS.md`. Never infer a mapping from the code alone.

## Home notes

Home content goes into the existing register or list. Only create a new note for a multi-step project or a capture with no clear destination yet.

| Content | Note |
| --- | --- |
| Dashboard | `100 Home/00 Home Dashboard.md` |
| Current actions | `100 Home/Tasks/Current Todo.md` |
| Shopping and restock | `100 Home/Lists/Shopping List.md` |
| Household reference info | `100 Home/Important Information/Important Information.md` |
| Document locations and renewals | `100 Home/Documents/Document Register.md` |
| Repairs, service history, recurring care | `100 Home/Maintenance/Maintenance Log.md` |
| Valuables, serials, warranties | `100 Home/Inventory/Home Inventory.md` |
| Multi-step household efforts | `100 Home/Projects/Home Projects.md` plus a `Home Project` note |
| Unsorted capture | `100 Home/Quick Notes/Home Quick Notes.md` |

Never store passwords, recovery codes, or sensitive IDs in Home notes. Point to the password manager instead.

## Routing

Home when the user talks about home, household, personal admin, todos, shopping, documents, maintenance, inventory, providers, or routines. Project when the context is a repo, client, implementation change, delivery decision, or work meeting. If both fit and the user did not say, ask one question.

For project notes, the registry is the source of truth. Routing works in this order:

1. `--client` and `--project` naming an existing registry entry.
2. The current directory matching a registry `repoPath` by prefix.
3. The current directory, or one of its parents, matching the last folder name of a registry `repoPath`. This is what routes on macOS, because the registry records Windows paths such as `C:\Users\Schalk\Code\AGR - SWOT Rewrite`.

If none of those match, stop. Do not invent a route. Registering a new project in `99 Meta/project-registry.json` and creating its folder is a separate, deliberate step you should confirm with the user first.

## Note types

Project types and where they land. Default to `change`.

| Type | Folder | Use |
| --- | --- | --- |
| `change` | Changes | Implementation notes and fixes |
| `decision`, `adr` | Decisions | Delivery, design, or architecture decisions |
| `note`, `meeting`, `investigation`, `incident`, `plan`, `architecture`, `technical-design`, `as-built`, `handoff`, `conversation` | Notes | Use when the request is clearly that kind of note |

Home types: `home-todo`, `home-shopping-list`, `home-document-register`, `home-important-information`, `home-maintenance-log`, `home-inventory`, `home-project`, `home-service-provider`, `home-routine`, `home-quick-note`, `home-note`. The script derives folder, default status, and tags from the type. `--status` overrides the default.

## Creating the note

Edit an existing Home register or list directly. For a new note, run the script so frontmatter, links, and filenames stay consistent. Use `--dry-run` first when the route is uncertain. Run it from the repo so `--cwd` defaults correctly, or pass `--cwd` explicitly.

```bash
python3 ~/.agents/skills/personal/document-branium/scripts/create_branium_note.py --title "Fix rich text field save binding" --note-type change --body-file note-body.md
```

```bash
python3 ~/.agents/skills/personal/document-branium/scripts/create_branium_note.py --area home --note-type home-quick-note --title "Garage shelf measurements" --body "## Note
- 120 cm x 40 cm

## Next Action
- [ ] Order brackets"
```

On Windows use `python` or `py` with the same flags. Write the body to a temporary file and pass `--body-file` when it contains quotes or is longer than a few lines. The script prints the created path. Source provenance records an external `--cwd` unchanged. From inside the vault it uses the registered `repoPath` or omits the source.

## Content

Write only what was observed or supplied. Do not invent Dataverse, client, repo, provider, warranty, or document facts.

Project change shape:

```markdown
## Context
- What triggered the work.

## What Changed
- The concrete behaviour or implementation change.

## Files Touched
- `path/to/file`

## Verification
- Command or manual check. Say explicitly what was not run.

## Follow Up
- Anything unresolved.
```

Home shape:

```markdown
## Context
- What this is about.

## Details
- Facts needed to act later: date, provider, location, cost, renewal, status.

## Next Action
- [ ] The next household action, if any.

## Links
- [[100 Home/00 Home Dashboard|Home Dashboard]]
```

For a specialized project type, follow the matching template in `90 Templates` (`ADR.md`, `Meeting Note.md`, `Investigation Note.md`, `Incident RCA.md`, and so on). Link the note to its client and project pages, or to the Home dashboard.
