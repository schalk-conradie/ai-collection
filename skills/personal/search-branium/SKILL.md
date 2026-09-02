---
name: search-branium
description: Search and read notes from the user's Obsidian vault, The Brainium, at ~/Documents/The Brainium. Use when the user asks to look up, recall, or find notes from Brainium or "branium", when starting work in a client or project repo that may have prior decisions or change notes, or when a Home question involves todos, shopping, documents, maintenance, inventory, or household information.
---

# Search Branium

Find the Brainium notes that matter before answering a project or Home question or making a change. Read the notes you rely on. Search results are a locator, not an answer.

## Vault layout

The vault root is `~/Documents/The Brainium` on every machine. `BRAINIUM_VAULT` or `--vault` overrides it.

| Path | Purpose |
| --- | --- |
| `10 Clients/<Client>/Projects/<Client code> - <Project>/` | Client and project notes in `Changes`, `Decisions`, and `Notes`. |
| `100 Home/` | Household notes. Active registers beat archived or dated notes when both match. |
| `20 Research`, `30 Study`, `00 Inbox` | General knowledge notes. Included in whole-vault search. |
| `99 Meta/project-registry.json` | Maps `repoPath` to `client`, `project`, and `projectFolder`. Used for scope routing. |

Home entry points:

| Content | Note |
| --- | --- |
| Dashboard | `100 Home/00 Home Dashboard.md` |
| Current actions | `100 Home/Tasks/Current Todo.md` |
| Shopping and restock | `100 Home/Lists/Shopping List.md` |
| Household reference info | `100 Home/Important Information/Important Information.md` |
| Document locations and renewals | `100 Home/Documents/Document Register.md` |
| Repairs, service history, recurring care | `100 Home/Maintenance/Maintenance Log.md` |
| Valuables, serials, warranties | `100 Home/Inventory/Home Inventory.md` |
| Multi-step household efforts | `100 Home/Projects/Home Projects.md` |
| Unsorted capture | `100 Home/Quick Notes/Home Quick Notes.md` |

Client codes in folder names:

| Code | Client |
| --- | --- |
| AGR | Allan Gray Retail |
| AGI | Allan Gray Institutional |
| E6 | Element 6 |
| EC | Enterprise cloud |
| SBS | SBS (Stellenbosch Business School is an accepted alias) |

When clear repo, folder, or vault evidence reveals a new code, update this table, the same table in `~/.agents/skills/personal/document-branium/SKILL.md`, and the vault `AGENTS.md`. Never infer a mapping from the code alone.

## Searching

Search the narrowest scope that can hold the answer, then widen. Home first for household questions. The current project folder when the repo is registered. Then the client folder. Then the whole vault. Do not ask the user to pick a project when the registry can infer it.

```bash
python3 ~/.agents/skills/personal/search-branium/scripts/search_branium.py --query "audit history rich text field"
python3 ~/.agents/skills/personal/search-branium/scripts/search_branium.py --scope home --query "insurance renewal"
python3 ~/.agents/skills/personal/search-branium/scripts/search_branium.py --client "Element 6" --scope client --query "JDE"
python3 ~/.agents/skills/personal/search-branium/scripts/search_branium.py --scope all --query "PRP2 Product Group" --json
```

On Windows use `python` or `py` with the same flags. `--cwd` defaults to the current directory, so run from the repo or pass it explicitly. An empty `--query` lists the most recent notes in scope.

Pull search terms from the real context: repo and client names, table or entity names, file names, error text, routes, business terms, provider names, item names. Multi-word queries need at least two terms to match a note unless the exact phrase appears.

`--scope auto` (the default) picks Home when `--cwd` is under `100 Home` or `--client Home` is passed, the project when `--cwd` matches the registry, the client when only `--client` is given, and the whole vault otherwise. Registry `repoPath` values are often Windows paths. The script matches them by prefix first, then by the last folder name against `--cwd` and its parents, which is how routing works on macOS.

The script skips `AGENTS.md`, `99 Meta`, `90 Templates`, `.obsidian`, and `*.excalidraw.md`. If a registry entry points to a missing project folder, it reports the client, project, and path instead of silently widening the search.

## Answering

Open the full note for anything you rely on. Cite vault-relative paths and line numbers when they help the user find the note. Say plainly when nothing relevant was found, then continue from repo evidence or the current Home structure.
