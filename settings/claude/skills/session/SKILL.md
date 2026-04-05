---
name: session
description: Show current Claude session state — model, effort, context window usage, project config status, memory index, active tasks, and configured hooks. Fast orientation snapshot, no commentary.
---

Produce a compact session snapshot. Output only the formatted result — no preamble, no trailing commentary.

Steps:

1. **Model & context** — state the model name, effort level, and context window usage as `used / total tokens (X%)`

2. **Project** — check the current working directory for:
   - `CLAUDE.md` or `.claude/CLAUDE.md` — show path if found, "none" if missing
   - `.claude/settings.json` — show "found" with allow-list count, or "none"
   - `.claude/settings.local.json` — show "found" or "none"
   - Project memory path: `~/.claude/projects/<encoded>/memory/` — show file count or "none"

3. **Memory** — derive the project memory path:
   - Take the current working directory
   - Encode it: replace each `/` with `-` (e.g. `/Users/foo/bar` → `-Users-foo-bar`)
   - Read `~/.claude/projects/<encoded>/memory/MEMORY.md`
   - List each bullet entry (name + one-line description); if file missing, print "none"

4. **Tasks** — call TaskList; show id, status, and title for each; if none, print "none"

5. **Hooks** — read `~/.claude/settings.json`, extract any `hooks` keys and their trigger events; if no hooks configured, print "none"

Output format — use plain headers, keep total output under 40 lines:

```
── Model ────────────────────────────────
<model>  effort:<level>  <used>/<total> tokens (<pct>%)  /cost /usage

── Project ─────────────────────────────
CLAUDE.md: <path or none>
settings:  <found (N rules) or none>
local:     <found or none>
memory:    ~/.claude/projects/<encoded>/memory/ (<N files>)

── Memory ──────────────────────────────
• <name> — <description>

── Tasks ───────────────────────────────
[id] <status>  <title>

── Hooks ───────────────────────────────
<event>: <command>
```
