# Global Rules

## Commits & Git
- Never add Co-Authored-By lines to commits
- Never commit without user approval
- Never push without user approval
- Keep commit subject line under 50 characters

## Code Style
- On first session in a new project, check for existing linter/formatter configs before assuming style
- Prefer editing existing files over creating new ones
- Match the style and patterns of surrounding code

## Documentation
- Do not create doc/README files without asking first — suggest it, wait for approval

## Communication
- Respond in English by default — if the user writes in another language, match it
- Be direct, skip filler phrases and preamble
- Write impersonally — never use "you" or "your" when describing code, configs, or the project ("the config" not "your config")
- When unsure about project conventions, ask one focused question rather than guess or assume

## ENV
- Check project's packageManager field or lock files to determine which package manager to use
- Check ~/.dotfiles/ if some installed tools are not running

## Code Changes
- Do not modify unrelated code — stay focused on the task
- Do not add comments or docstrings to code that was not changed in this task
- If a request is too broad or ambiguous, ask one focused clarifying question before starting — suggest scope options if helpful ("security, performance, or readability?")
- Show the plan before changes touching more than one file or rewriting more than ~20 lines — wait for confirmation before proceeding
- If the plan turns out wrong mid-execution, stop and re-confirm rather than self-correct silently
- Do not delete or overwrite unfamiliar files — they may be in-progress work

## Context & Tokens
- Keep responses lean — share key information, not exhaustive detail unless asked
- Do not use emoji in output unless the task explicitly involves them
- Do not repeat content already established in CLAUDE.md or prior context
- At the end of a work session with significant decisions or discoveries, summarize key points worth remembering — save to CLAUDE.md, auto-memory, or follow project entrypoint.md memory strategy if defined

## Output
- When reading errors, share the key part — do not dump full stack traces unless asked
- Use numbered lists when suggesting options — easier to reference by number
- When a task is complete, state what was done concisely — do not restate the original request

## Meta
- If any rule in this file conflicts with the task or makes work harder, surface the conflict immediately — do not attempt the task first. Suggest re-reviewing the rule.
- Rules in this file are loaded as context, not enforced configuration. Compliance improves with specificity and examples. If a rule is consistently ignored, make it more concrete or add an example.