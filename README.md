# Personal agent configuration

Personal configuration shared across coding agents. The repo currently tracks:

- agent working instructions in [`AGENTS.md`](AGENTS.md)
- Claude's global loader in [`CLAUDE.md`](CLAUDE.md)
- personal coding standards in [`CODING.md`](CODING.md)
- locally authored [Agent Skills](https://agentskills.io) under [`skills/personal/`](skills/personal/)

## Bootstrap a machine

The installers clone this repository to `~/.agents`, create `~/.codex` and
`~/.claude`, then add these links:

```text
~/.codex/AGENTS.md   -> ~/.agents/AGENTS.md
~/.claude/CLAUDE.md  -> ~/.agents/CLAUDE.md
~/.claude/skills/*   -> ~/.agents/skills/personal/*
```

`CLAUDE.md` imports `~/.agents/AGENTS.md`, so both agents use the same shared
instructions. Each personal skill is linked separately so Claude-specific skills
remain in place. `~/.agents` remains the place to edit shared instructions and
personal skills.

On macOS or Linux, download and inspect the installer, then run it:

```sh
curl -fsSL https://raw.githubusercontent.com/schalk-conradie/skills/main/install.sh \
  -o /tmp/install-agents.sh
sh /tmp/install-agents.sh
```

On Windows, use PowerShell:

```powershell
$installer = Join-Path $env:TEMP "install-agents.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/schalk-conradie/skills/main/install.ps1" -OutFile $installer
& $installer
```

Run either installer again to verify or repair the links. Existing files stop
the install. Pass `--force` on macOS or Linux, or `-Force` on Windows, to move
conflicting files to timestamped backups before creating the links.

Windows may require Developer Mode or an administrator shell for symbolic
links. The PowerShell installer falls back to hard links for files and directory
junctions for skills.

If you already cloned the repository, run `~/.agents/install.sh` or
`~/.agents/install.ps1` directly. The installer reuses the checkout and does not
pull, reset, commit, or push it.

The installer removes stale skill links only when they point into
`~/.agents/skills/personal` and their source skill no longer exists. It does not
remove Claude-only skills, plugin skills, or links managed by another tool.

## Install skills

The bootstrap already exposes every tracked `skills/personal` skill to Claude.
Use the Agent Skills CLI below when you want to install skills into other agents
or choose a different scope.

### Whole collection

```bash
# Interactive (choose agents and install method)
npx skills add schalk-conradie/skills

# List skill names in this repo without installing
npx skills add schalk-conradie/skills --list

# Install everything, globally, non-interactive
npx skills add schalk-conradie/skills --all -g -y
```

### Specific skills

Use the skill `name` from each skill’s `SKILL.md` frontmatter (see table below):

```bash
npx skills add schalk-conradie/skills --skill dynamics-webapi --skill search-branium

# Shorthand: repo@skill
npx skills add schalk-conradie/skills@microsoft-exam-docs

# Target one agent (e.g. Cursor)
npx skills add schalk-conradie/skills --skill create-study-guide -a cursor -y
```

### Local clone

```bash
git clone https://github.com/schalk-conradie/skills.git
cd skills

npx skills add .
npx skills add ./skills/personal/microsoft-exam-docs
```

### Install scope

| Scope | Flag | Location | Use case |
|-------|------|----------|----------|
| Project | (default) | `./.agents/skills/` (agent-specific; see [CLI docs](https://github.com/vercel-labs/skills#installation-scope)) | Shared with the repo / team |
| Global | `-g` | `~/.agents/skills/` (and agent-specific global paths) | Available across all projects |

Symlink installs are recommended when the CLI prompts you; they keep a single copy easy to update with `npx skills update`.

## Repository layout

```
.
├── AGENTS.md        # Shared agent instructions
├── CLAUDE.md        # Claude loader for the shared instructions
├── CODING.md        # Personal coding standards
├── install.sh       # macOS and Linux bootstrap
├── install.ps1      # Windows PowerShell bootstrap
├── pets/            # Codex pet assets and configuration
└── skills/
    └── personal/    # Tracked, locally authored skills
```

## Personal skills

| Skill | Path | Description |
|-------|------|-------------|
| [adf-triage](skills/personal/adf-triage/SKILL.md) | `personal/adf-triage` | Triage Azure Data Factory load failures with live run, SQL, and Dataverse evidence |
| [auth-dynamics](skills/personal/auth-dynamics/SKILL.md) | `personal/auth-dynamics` | Get or refresh a Dynamics 365 / Dataverse Web API bearer token |
| [bro](skills/personal/bro/SKILL.md) | `personal/bro` | Restate the previous response in plain language |
| [create-custom-ui-registry](skills/personal/create-custom-ui-registry/SKILL.md) | `personal/create-custom-ui-registry` | Create and publish a custom shadcn/ui registry for create-ec-app |
| [create-study-guide](skills/personal/create-study-guide/SKILL.md) | `personal/create-study-guide` | Turn downloaded `CONTENT.md` into a concise `STUDY_GUIDE.md` |
| [document-branium](skills/personal/document-branium/SKILL.md) | `personal/document-branium` | Create or update project and Home notes in the Brainium vault |
| [dynamics-webapi](skills/personal/dynamics-webapi/SKILL.md) | `personal/dynamics-webapi` | Read-only Dynamics 365 / Dataverse Web API queries |
| [exam-qa-generator](skills/personal/exam-qa-generator/SKILL.md) | `personal/exam-qa-generator` | Generate multiple-choice / multiple-select practice Q&A JSON from Learn material |
| [grounded-engineering](skills/personal/grounded-engineering/SKILL.md) | `personal/grounded-engineering` | Make code changes from observed behavior and direct verification |
| [microsoft-exam-docs](skills/personal/microsoft-exam-docs/SKILL.md) | `personal/microsoft-exam-docs` | Download Microsoft Learn training material for a certification exam code |
| [search-branium](skills/personal/search-branium/SKILL.md) | `personal/search-branium` | Search and retrieve project or Home context from the Brainium vault |
| [teach](skills/personal/teach/SKILL.md) | `personal/teach` | Explain what a body of work is, how it works, and why it is built that way |
| [technical-writing](skills/personal/technical-writing/SKILL.md) | `personal/technical-writing` | Apply the personal technical-writing standard |
| [unslop](skills/personal/unslop/SKILL.md) | `personal/unslop` | Remove AI writing patterns and add a human voice |
| [update-standards](skills/personal/update-standards/SKILL.md) | `personal/update-standards` | Capture coding preferences as durable personal standards |

Typical study workflow: `microsoft-exam-docs` → `create-study-guide` → `exam-qa-generator`.

## Managing installed skills

```bash
npx skills list
npx skills find microsoft
npx skills update
npx skills update dynamics-webapi
npx skills remove dynamics-webapi
```
