# Personal agent configuration

Personal configuration shared across coding agents. The repo currently tracks:

- agent working instructions in [`AGENTS.md`](AGENTS.md)
- personal coding standards in [`CODING.md`](CODING.md)
- locally authored [Agent Skills](https://agentskills.io) under [`skills/personal/`](skills/personal/)

## Install skills

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
├── CODING.md        # Personal coding standards
├── pets/            # Codex pet assets and configuration
└── skills/
    └── personal/    # Tracked, locally authored skills
```

## Personal skills

| Skill | Path | Description |
|-------|------|-------------|
| [auth-dynamics](skills/personal/auth-dynamics/SKILL.md) | `personal/auth-dynamics` | Get or refresh a Dynamics 365 / Dataverse Web API bearer token |
| [create-custom-ui-registry](skills/personal/create-custom-ui-registry/SKILL.md) | `personal/create-custom-ui-registry` | Create and publish a custom shadcn/ui registry for create-ec-app |
| [create-study-guide](skills/personal/create-study-guide/SKILL.md) | `personal/create-study-guide` | Turn downloaded `CONTENT.md` into a concise `STUDY_GUIDE.md` |
| [document-branium](skills/personal/document-branium/SKILL.md) | `personal/document-branium` | Create or update project and Home notes in the Brainium vault |
| [dynamics-webapi](skills/personal/dynamics-webapi/SKILL.md) | `personal/dynamics-webapi` | Read-only Dynamics 365 / Dataverse Web API queries |
| [exam-qa-generator](skills/personal/exam-qa-generator/SKILL.md) | `personal/exam-qa-generator` | Generate multiple-choice / multiple-select practice Q&A JSON from Learn material |
| [microsoft-exam-docs](skills/personal/microsoft-exam-docs/SKILL.md) | `personal/microsoft-exam-docs` | Download Microsoft Learn training material for a certification exam code |
| [search-branium](skills/personal/search-branium/SKILL.md) | `personal/search-branium` | Search and retrieve project or Home context from the Brainium vault |
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