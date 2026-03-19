# Personal Notes

## Claude Code Tips

- `claude -c` — resume last conversation
- `claude --resume` — pick from recent conversations
- `/rename` — rename current session
- `/fast` — toggle faster output mode
- `/compact` — compress context manually
- `claude config set --global preferReducedMotion true` — disable animations
- `claude mcp add playwright -- npx @playwright/mcp@latest` — add Playwright browser control MCP

## File Locations

- `~/.claude/CLAUDE.md` — global rules (auto-loaded every session)
- `~/.claude/settings.json` — global settings, permissions
- `~/.claude/notes.md` — this file (not auto-loaded, read on request)
- `~/.claude/projects/*/memory/MEMORY.md` — per-project memory (auto-loaded)
- `~/.claude/projects/*/memory/*.md` — extra memory files (read on demand)

## Ideas / TODO

- Establish session naming convention (e.g., `project-topic-subtopic`)

## Backup

~/.claude/ is NOT backed up automatically. Run periodically:
```bash
cp -r ~/.claude ~/.claude-backup
```

---

## Claude Code Features -- Adoption Plan

Track what we've tried, what works, what to skip.

### 1. Immediate (saves time every session)

- [x] **User-level CLAUDE.md** (`~/.claude/CLAUDE.md`)
  - Git rules, code style, docs, communication, package manager, code changes, output, meta
  - Notes: Done 2026-03-07

- [ ] **Permissions** (`.claude/settings.json`)
  - Auto-allow: Read, Edit, Write, Glob, Grep
  - Bash allowlist: `git *`, `pnpm *`, `npx playwright *`
  - Notes:

- [ ] **`/fast` mode**
  - Same model, faster output -- try for routine tasks
  - Notes:

### 2. Workflow (try next)

- [ ] **`/commit` skill**
  - Guided commit with diff review, replaces manual git add/commit
  - Notes:

- [ ] **`/simplify` skill**
  - Review changed code for quality after making changes
  - Notes:

- [ ] **`/review`**
  - Review code changes before PR
  - Notes:

- [ ] **Hooks** (afterEdit, afterWrite)
  - Auto-lint on file edit/create
  - Notes:

- [ ] **`/add-dir`**
  - Add extra working directories (work across packages)
  - Notes:

- [ ] **`/compact`**
  - Manually compress when context gets heavy mid-session
  - Notes:

### 3. Integrations (when relevant)

- [x] **Playwright MCP**
  - Browser control: navigate, click, fill, screenshot
  - Notes: Done 2026-03-10. `claude mcp add playwright -- npx @playwright/mcp@latest`

- [ ] **Jira MCP** (Atlassian)
  - Create/update NW tickets from terminal
  - Notes:

- [ ] **Slack MCP**
  - Post test results, notify team
  - Notes:

- [ ] **Xsolla MCP**
  - Search internal docs, IdP behavior questions
  - Notes:

- [ ] **Confluence MCP**
  - Update project documentation
  - Notes:

### 4. Advanced (power user)

- [ ] **One-shot mode** (`claude -p "prompt"`)
  - Script Claude into CI/makefiles for automated tasks
  - Notes:

- [ ] **Subagents** (Agent tool)
  - Parallel research in isolated context
  - Notes:

- [ ] **Worktrees** (EnterWorktree)
  - Work on parallel branches without stashing
  - Notes:

- [ ] **`.claudeignore`**
  - Exclude noise (node_modules, dist, build artifacts)
  - Notes:

- [ ] **`claude --resume`**
  - Pick from recent conversations (vs `-c` for last)
  - Notes:

- [ ] **`/pr-comments`**
  - View and respond to PR comments
  - Notes:

### Decided to Skip

| Feature | Reason |
|---------|--------|
| | |

### Log

| Date | Feature | Result |
|------|---------|--------|
| 2026-03-07 | Created plan | -- |
| 2026-03-07 | User-level CLAUDE.md | Set up with git, code, docs, output rules |
| 2026-03-10 | Playwright MCP | Added browser control for E2E debugging |
