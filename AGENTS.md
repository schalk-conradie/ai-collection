# Working Style

- Always read and follow `~/.agents/STYLE.md` when replying, writing, reporting, or producing other prose. Apply it to explanations, status updates, documentation, code comments, and other user-facing text.
- Lead with the outcome. Default to concise answers, short paragraphs, and useful bullets. Avoid walls of text; expand when asked or when risk requires it.
- Solve the real problem with the smallest clear change. Read the relevant code path before editing; do not guess.

# Autonomy

- Use subagents for bounded, independent grunt work when delegation will save time or model usage. Keep small tasks local when the handoff would cost more than the work.
- Delegate routine browser navigation, repetitive tool use, status checks, polling, data collection, extraction, and similar execution work to the cheapest available worker model at high reasoning effort. Where the `grunt_worker` and `browser_worker` agents from `~/.agents/agents` are installed, use them. Do not use fast or low-effort modes for this work. For example with codex, use `gpt-5.6-luna` with `high` reasoning in Standard mode.
- Give grunt-work subagents a focused prompt and the minimum necessary conversation history. Prefer no inherited history when the prompt contains all required context.
- Keep root-cause diagnosis, architecture, destructive changes, production-risk decisions, and cross-system synthesis on the main agent, or escalate them to the strongest available model. Use the lowest-cost model that can complete the task reliably.
- For review, explanation, diagnosis, or planning, inspect and report; do not edit.
- For change, build, or fix requests, make only the requested in-scope changes and run the smallest relevant checks.
- Ask before destructive actions, external writes, production dependency changes, or materially expanding scope. Do not commit or push unless asked.

# Engineering

- Apply YAGNI: prefer existing code, the standard library, platform features, and installed dependencies before adding code.
- Fix root causes without unrelated refactoring. Preserve meaningful errors.
- For version-sensitive behavior, inspect pinned versions, local types/source, and existing tests. When external verification is needed, use official documentation appropriate to the pinned version.
- Add the smallest useful test for non-trivial behavior changes. Report any relevant checks that were not run.
- Before modifying code, read and follow `~/.agents/CODING.md`. Repository instructions and established project conventions take precedence.

# Environment

- **OS & package managers**: Detect the current operating system before selecting commands or installation steps. Check whether `mise`, `brew`, and `winget` are installed, and use only a package manager that is available and appropriate for that OS.
- **Shells**: On Windows, use PowerShell 7 where possible instead of CMD. On macOS, always use `zsh` when it is available.
- **Tool precedence**: Prefer `mise` for managing runtimes and development tools when it is available.
- **Portable files**: Anything written for this configuration must run on both Windows and macOS. Use `~` and forward slashes in paths, `python3` on macOS and `python` on Windows, and give shell examples that work in both `zsh` and PowerShell or give both forms.
- **Canonical location**: `~/.agents` holds all shared instructions, standards, skills, and agent definitions. Harness folders such as `~/.claude`, `~/.codex`, and `~/.cursor` only hold links into it. Read from and write to `~/.agents`, never to a harness copy.
- **Personal skills**: Create personal skills only in `~/.agents/skills/personal/<name>`, then run `~/.agents/install.sh` or `~/.agents/install.ps1` to expose them.

# Dynamics 365 and Power Automate
- **Solutions**: Whenever you are working with changes within Dynamics 365 and make.powerapps.com (and powerautomate.com), Please ensure that you are working in the correct solution and only pull in components needed by your change. It should almost never be necessary to pull in the entire component and all dependencies. If you have any questions, please ask the user first, and also ask the user what solution to be used.
