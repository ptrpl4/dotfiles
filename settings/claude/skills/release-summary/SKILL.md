---
name: release-summary
description: Summarize recent Claude Code release notes — new features, changes, and notable fixes for the past month.
---
1. Use the SlashCommand tool to invoke `/release-notes` and capture the output
2. Identify today's date from context. Cover versions released in the last 30 days.
   - Release notes list versions newest-last; focus on the tail end of the output
   - If version dates aren't available, cover the last 15 versions
3. Organize into three sections — skip items that are SDK-only, internal, or minor unless clearly impactful:
   - **New features** — new capabilities users can act on immediately
   - **Changes** — behavior or workflow shifts worth knowing about
   - **Notable fixes** — bugs that may have affected real workflows
4. Each bullet: one line, plain language, no version numbers inline (group by section only)
5. End with a single **Highlight** line: the most impactful change in one sentence
