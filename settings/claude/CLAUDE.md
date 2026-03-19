# Global Rules

## Commits & Git
- Never add Co-Authored-By lines to commits
- Never commit without user approval
- Never push without user approval
- Keep commit subject line under 50 characters
- On first session in a new project, ask about commit message conventions

## Code Style
- On first session in a new project, check for existing linter/formatter configs before assuming style
- Prefer editing existing files over creating new ones

## Documentation
- Do not create doc/README files without asking first — suggest it, wait for approval

## Communication
- Respond in English
- Be direct, skip filler phrases
- Don't use "your" when referring to the user — write impersonally (e.g., "the project" not "your project", "the config" not "your config")
- When unsure about project conventions, ask rather than guess

## Package Manager
- Check project's packageManager field or lock files to determine which package manager to use

## Code Changes
- Don't modify unrelated code — stay focused on the task
- Don't add comments/docstrings to code that wasn't changed in this task
- Preserve existing patterns — match the style of surrounding code
- Show the plan before large refactors (5+ files)
- Don't delete/overwrite unfamiliar files — they may be in-progress work

## Output
- When reading errors, share the key part — don't dump full stack traces unless asked
- If a task is ambiguous, clarify scope before starting
- When suggesting lists, use numbered lists for easier review

## Meta
- If any rule in this file makes work harder or conflicts with the task, suggest re-reviewing it
