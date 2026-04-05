---
name: session
description: Show current Claude session state — model, context window usage, memory index, active tasks, and configured hooks. Fast orientation snapshot, no commentary.
---

Produce a compact session snapshot. Output only the formatted result — no preamble, no trailing commentary.

Steps:

1. **Model & context** — state the model name and context window usage as `used / total tokens (X%)`

2. **Memory** — derive the project memory path:
   - Take the current working directory
   - Encode it: replace each `/` with `-` (e.g. `/Users/foo/bar` → `-Users-foo-bar`)
   - Read `~/.claude/projects/<encoded>/memory/MEMORY.md`
   - List each bullet entry (name + one-line description); if file missing, print "none"

3. **Tasks** — call TaskList; show id, status, and title for each; if none, print "none"

4. **Hooks** — read `~/.claude/settings.json`, extract any `hooks` keys and their trigger events; if no hooks configured, print "none"

Output format — use plain headers, keep total output under 30 lines:

```
── Model ────────────────────────────────
<model>  <used>/<total> tokens (<pct>%)

── Memory ──────────────────────────────
• <name> — <description>

── Tasks ───────────────────────────────
[id] <status>  <title>

── Hooks ───────────────────────────────
<event>: <command>
```
