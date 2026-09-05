# Personal agent configuration

One repository, cloned to `~/.agents`, that every coding agent on every machine reads from. It tracks:

- shared working instructions in [`AGENTS.md`](AGENTS.md)
- personal coding standards in [`CODING.md`](CODING.md) and the writing guide in [`STYLE.md`](STYLE.md)
- personal [Agent Skills](https://agentskills.io) under [`skills/personal/`](skills/personal/)
- worker agent definitions under [`agents/`](agents/)
- pet assets under [`pets/`](pets/)

`~/.agents` is the only place to edit. Harness folders such as `~/.claude` or `~/.codex` only ever hold links into it. The repo works the same on Windows and macOS: paths use `~`, scripts run under `python3` on macOS and `python` on Windows, and each installer does exactly the same thing.

## Bootstrap a machine

macOS or Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/schalk-conradie/skills/main/install.sh -o /tmp/install-agents.sh
sh /tmp/install-agents.sh
```

Windows (PowerShell 7 or Windows PowerShell 5.1):

```powershell
$installer = Join-Path $env:TEMP "install-agents.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/schalk-conradie/skills/main/install.ps1" -OutFile $installer
& $installer
```

Both installers clone the repo to `~/.agents` (or reuse an existing clone without pulling or resetting it), then create links. Rerun either one at any time to add new skills, repair links, or remove links whose source skill was deleted. Existing files that are not already the right link stop the install; pass `--force` (sh) or `-Force` (PowerShell) to move them to timestamped backups first.

### What gets linked

The installers never name a skill. They loop over whatever is in the folders.

| Link | Points to | When |
| --- | --- | --- |
| `~/.agents/skills/<name>` | `~/.agents/skills/personal/<name>` | Always. `~/.agents/skills` is the cross-agent convention that Codex, Cursor, Grok, OpenCode, and Copilot scan natively. |
| `~/.claude/CLAUDE.md` | `~/.agents/AGENTS.md` | `~/.claude` exists |
| `~/.claude/skills/<name>` | `~/.agents/skills/personal/<name>` | `~/.claude` exists. Claude Code does not read `~/.agents/skills`. |
| `~/.codex/AGENTS.md` | `~/.agents/AGENTS.md` | `~/.codex` exists |
| `~/.codex/agents/<file>` | `~/.agents/agents/<file>` | `~/.codex` exists |

The harness table sits at the top of each installer. Adding a harness is one row. Installers only remove links that point into `~/.agents` and no longer resolve; links owned by other tools are left alone.

Windows needs Developer Mode or an administrator shell for symbolic links. The PowerShell installer falls back to hard links for files and junctions for directories.

## Skills

Personal skills live in `skills/personal/<name>/SKILL.md`. Third-party skills installed by tools land directly in `~/.agents/skills/<name>` and are ignored by git.

| Skill | Use |
| --- | --- |
| [bro](skills/personal/bro/SKILL.md) | Restate the previous reply in plain language |
| [create-custom-ui-registry](skills/personal/create-custom-ui-registry/SKILL.md) | Create and publish a static shadcn/ui registry for create-ec-app |
| [document-branium](skills/personal/document-branium/SKILL.md) | Create or update project and Home notes in the Brainium vault |
| [dynamics-webapi](skills/personal/dynamics-webapi/SKILL.md) | Read-only Dynamics 365 and Dataverse Web API queries |
| [search-branium](skills/personal/search-branium/SKILL.md) | Find project or Home context in the Brainium vault |
| [update-standards](skills/personal/update-standards/SKILL.md) | Capture coding preferences in `CODING.md` |

To add a skill, create `skills/personal/<name>/SKILL.md` and rerun the installer. To install these skills into another agent or scope, the [Agent Skills CLI](https://github.com/vercel-labs/skills) works with this repo:

```bash
npx skills add schalk-conradie/skills --all -g -y
npx skills add schalk-conradie/skills --skill dynamics-webapi
```

Skill scripts are Python standard library only (`python3` on macOS, `python` or `py` on Windows) or Node, and have unit tests under `tests/` where behaviour is non-trivial:

```bash
python3 -m unittest discover -s skills/personal/document-branium/tests
python3 -m unittest discover -s skills/personal/search-branium/tests
```

## Worker agents

`agents/` holds two optional worker definitions: `grunt_worker` for bounded file discovery, log collection, repetitive checks, and extraction, and `browser_worker` for read-only browser navigation and data collection. Request delegation explicitly in your prompt and name a worker when you want that role. Browser work stays in the main session so you can follow it unless you specifically request a browser worker.

The definitions use the Codex custom-agent format, so the installer links them only where `~/.codex` exists. Other harnesses follow the same instruction to delegate only when explicitly requested, using their available capabilities.

## Repository layout

```
.
├── AGENTS.md        # Shared agent instructions
├── CODING.md        # Personal coding standards
├── STYLE.md         # Writing guide
├── agents/          # Worker agent definitions
├── install.sh       # macOS and Linux bootstrap
├── install.ps1      # Windows bootstrap, same behaviour
├── pets/            # Pet assets
└── skills/
    └── personal/    # Tracked skills; everything else under skills/ is ignored
```
