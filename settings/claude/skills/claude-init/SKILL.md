---
name: claude-init
description: Interactive Claude setup for the current project. Detects project type, scaffolds .claude/ config, sets model/effort for the task, and surfaces all active Claude context. Run at the start of a session in a new or existing project.
---

Run an interactive Claude setup for the current project. Work through each step in order — ask one question at a time, wait for a response before proceeding. Be concise; skip steps where nothing is needed (print "✓ skipped").

---

## Step 1: Global config — show what's active

Print a summary of the global Claude config in effect:
- Global CLAUDE.md: confirm `~/.claude/CLAUDE.md` exists (show path or "missing")
- Rules: list files in `~/.claude/rules/` and their path patterns (from frontmatter `paths:` field); note which apply to this project based on file extensions present
- Skills: list names from `~/.claude/skills/`
- Hooks: read `~/.claude/settings.json`, show any `hooks` entries; if none, print "none"
- Model: current model name
- Effort: current effort level

---

## Step 2: Project type detection

Check for these files in the current directory (non-recursively first, then one level deep):

| File | Type |
|---|---|
| `package.json` | Node / JS / TS |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pyproject.toml` / `requirements.txt` / `setup.py` | Python |
| `Package.swift` / `*.xcodeproj` / `*.xcworkspace` | Swift / Xcode |
| `Makefile` | Make-based |
| `Dockerfile` / `docker-compose.yml` | Containerized |
| `CLAUDE.md` or `.claude/CLAUDE.md` | Already has Claude config |

State what was detected. If multiple types, list all.

---

## Step 3: Project CLAUDE.md

Check if `CLAUDE.md` or `.claude/CLAUDE.md` exists in the current project.

- **If found**: read it, summarize what it covers in 1–2 lines. Print "✓ exists at <path>".
- **If missing**: ask — *"No project CLAUDE.md found. Create one? (yes / no)"*
  - If yes: create `.claude/CLAUDE.md` with a minimal template suited to the detected project type. Always include these sections: `## Commands`, `## Architecture`, `## Key files`, `## Known issues`. Leave placeholder content so the user can fill in details. Do not create doc files for all sections — this is a working reference, not documentation.

---

## Step 4: Project settings

Check if `.claude/settings.json` exists in the current project.

- **If found**: read it, show the current `permissions.allow` list. Print "✓ exists".
- **If missing**: ask — *"No project settings found. Create one with detected tool permissions? (yes / no)"*
  - If yes: based on detected project type, propose a `permissions.allow` list. Show the proposed JSON, ask *"Confirm? (yes / edit / skip)"* before writing.

Suggested allow entries by type:
- Node: `Bash(npm:*)`, `Bash(npx:*)`, `Bash(node:*)`
- Rust: `Bash(cargo:*)`
- Go: `Bash(go:*)`
- Python: `Bash(python:*)`, `Bash(pip:*)`, `Bash(uv:*)`
- Swift: `Bash(swift:*)`, `Bash(xcodebuild:*)`
- All: `Bash(git status)`, `Bash(git log:*)`, `Bash(git diff:*)`

---

## Step 5: .gitignore check

If `.git/` exists in the current directory:
- Check if `.claude/settings.local.json` appears in `.gitignore`
- If not: ask — *"Add .claude/settings.local.json to .gitignore? (yes / skip)"*
  - If yes: append `.claude/settings.local.json` to `.gitignore`

---

## Step 6: Multi-directory access

Ask: *"Does this project need access to directories outside the project root? (yes / no)"*

- If yes: ask which paths. Add them to the project `.claude/settings.json` under `permissions.additionalDirectories`. Also mention: use `/add-dir <path>` to add directories for the current session only.

---

## Step 7: Task type and model/effort

Ask: *"What kind of work are you starting? Pick a number:"*

```
1. Routine edits, fixes, small tasks
2. Feature work, debugging, moderate complexity
3. Architecture, complex multi-file refactoring
4. Research, exploration, or planning
```

Based on choice:
1. Run `/effort low`, suggest switching to `/model sonnet` if not already
2. Run `/effort auto` (or confirm it's already set)
3. Run `/effort high`, suggest `/model opus` if not already
4. Run `/effort high`, suggest `/model opus` if not already

---

## Step 8: Summary

Print a compact setup summary:

```
── Setup complete ───────────────────────
Project:   <type(s)>
CLAUDE.md: <path or created>
Settings:  <found / created / none>
Memory:    ~/.claude/projects/<encoded-cwd>/memory/

── Key commands ────────────────────────
/effort <level>   adjust reasoning depth
/model <name>     switch model mid-session
/compact          compress context when it fills up
/cost             check spend so far
/usage            check plan limits
/memory           view or edit auto-memory
/context          inspect context window
/permissions      review tool access rules
/add-dir <path>   add a directory for this session
```
