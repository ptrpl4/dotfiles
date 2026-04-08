# Global Rules

## Commits & Git
- Never add Co-Authored-By lines to commits
- Never commit without user approval
- Never push without user approval
- Keep commit subject line short

## Code Style
- On first session in a new project, check for existing linter/formatter configs before assuming style

## Documentation
- Do not create doc/README files without asking first — suggest it, wait for approval

## Communication
- Respond in English by default — if the user writes in another language, match it
- Write impersonally — never use "you" or "your" when describing code, configs, or the project ("the config" not "your config")
- When unsure about project conventions, ask one focused question rather than guess or assume

## ENV
- Check project's packageManager field or lock files to determine which package manager to use
- Check ~/dotfiles/ if some installed tools are not running

## Permissions & Access
- On first session in a new project, suggest setting up `.claude/settings.json` with project-specific allowed tools — analyze what commands will likely be needed and propose an `allow` list
- If the same command type is approved more than twice, suggest adding it to `.claude/settings.json`
- Remind the user to add `.claude/settings.local.json` to `.gitignore` if it contains machine-specific paths

## Code Changes
- If a request is too broad or ambiguous, ask one focused clarifying question before starting — suggest scope options if helpful
- Show the plan before changes touching more than one file or rewriting more than ~20 lines — wait for confirmation
- If the plan turns out wrong mid-execution, stop and re-confirm rather than self-correct silently

## Model & Effort
- Default: `/effort auto`. Use `opus` + `/effort high` for architecture, research, or complex multi-file work
- Avoid: `opus/low` (expensive model, minimum thinking), `haiku/high` (effort ceiling on cheapest model)
- When context fills up: `/compact`. Check spend: `/cost`. Check limits: `/usage`

## Output
- Do not use emoji unless the task explicitly involves them
- Do not repeat content already established in CLAUDE.md or prior context
- Use numbered lists when suggesting options — easier to reference by number
- When a task is complete, state what was done concisely — do not restate the original request
- When reading errors, share the key part — do not dump full stack traces unless asked
- At the end of a work session with significant decisions, summarize key points worth remembering

## Skills
Available via `/skill-name`:
- `/claude-init` — project setup: detect type, scaffold config, set model/effort
- `/agent-md` — create or audit CLAUDE.md files using research-backed principles
- `/session` — show current session state (model, effort, context, hooks)
- `/release-summary` — summarize recent Claude Code release notes
- `/explain` — explain current file or code selection
- `/simplify` — review changed code for reuse, quality, efficiency
- `/update-config` — configure settings.json and hooks

## Meta
- If any rule here conflicts with the task, surface the conflict immediately — do not attempt the task first
- Rules are context, not enforced config. If consistently ignored, make the rule more concrete

## Machine-specific config
This CLAUDE.md is shared across machines via dotfiles. Machine-specific context
(MCP servers, env quirks, account-specific integrations) lives in `~/.claude/local.md`,
which is not tracked in git. The install script creates a starter file if missing.

@RTK.md
@~/.claude/local.md
