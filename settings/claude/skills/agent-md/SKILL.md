---
name: agent-md
description: Create or audit a project CLAUDE.md using research-backed principles. Generates protocol-style files under 200 lines, flags bloat in existing ones.
---

Create or audit a project `CLAUDE.md`. Apply these principles throughout — they are backed by research showing developer-curated context improves agent performance by +4%, while auto-generated context is net-negative (-3%).

## Core filter

For every piece of content, ask: **"Can Claude discover this by reading the code or running a command?"**
- Yes → exclude it (file structure, standard conventions, API shapes, type definitions)
- No → include it (non-obvious commands, gotchas, env quirks, architectural decisions that aren't self-evident)

## Token budget

Target: **under 200 lines, 300–400 tokens**. Frontier models follow ~200 instructions reliably; Claude Code's system prompt uses ~50, leaving ~150 for CLAUDE.md. Instruction-following degrades uniformly as count increases.

---

## Mode: Create (no CLAUDE.md exists)

Work through these steps. Be interactive — ask clarifying questions rather than guessing.

### 1. Scan the project

Detect silently (don't list everything found — just use it):
- Language/framework (package.json, Cargo.toml, go.mod, pyproject.toml, etc.)
- Build/test/lint commands (scripts in package.json, Makefile targets, CI configs)
- Existing linters/formatters (biome.json, .eslintrc, .prettierrc, rustfmt.toml, etc.)
- Available skills and MCP servers (check `.claude/settings.json`, `~/.claude/settings.json`)
- Existing `.claude/rules/` files

### 2. Ask targeted questions

Ask only what can't be discovered from code. Examples:
- "What gotchas or non-obvious failure modes should Claude know about?"
- "Any repo conventions for branches, commits, or PRs?"
- "Are there dev environment quirks — required env vars, non-standard setup steps?"
- "Any commands that aren't obvious from package.json / Makefile?"

Skip questions where the answer is clearly in the code already.

### 3. Generate CLAUDE.md

Write to `.claude/CLAUDE.md` (or `CLAUDE.md` at project root — ask preference). Include only sections that have real content:

```markdown
## Commands
<only non-obvious build/test/lint/deploy invocations>

## Architecture
<only decisions that aren't self-evident from code structure>

## Gotchas
<failure modes, env quirks, non-obvious constraints>

## Repo conventions
<branch naming, commit format, PR process — only if non-standard>

## Skills & integrations
<declare available skills and MCP servers with what task classes they cover>
```

**Do not include:**
- File-by-file descriptions
- Standard language conventions
- Generic instructions ("write clean code", "be thorough")
- Code style rules already enforced by linters/formatters
- Detailed API documentation (link instead)

### 4. Suggest progressive disclosure

If the project has complex domain knowledge, suggest creating `agent_docs/` with focused docs referenced via `@path/to/file` syntax rather than inlining everything. Suggest `.claude/rules/` for path-scoped rules that only load when working on matching files.

---

## Mode: Audit (CLAUDE.md exists)

### 1. Read and measure

- Read the existing CLAUDE.md
- Count lines and estimate token count
- Count discrete instructions/rules

### 2. Score against principles

Check for and report:
- **Bloat**: lines > 200 or tokens > 400 — flag with specific cut suggestions
- **Discoverable content**: sections that describe what Claude can read from code (file structure, type definitions, standard patterns)
- **Missing gotchas**: no gotchas/known-issues section
- **Missing skills/MCP declarations**: skills or MCPs are configured but not declared
- **Style rules without tooling**: code style instructions that should be linter config instead
- **Generic instructions**: vague directives that add noise ("be careful", "write good code")
- **Stale content**: references to files/commands that no longer exist (verify by checking)

### 3. Suggest changes

Present a numbered list of suggested cuts and additions. Apply only after confirmation.

---

## Principles reference

These come from research and Anthropic's own guidance:
- CLAUDE.md is a **protocol file** — routing and capability declarations, not a repo overview
- **Don't use LLMs as linters** — configure actual tools, use Stop hooks to run formatters
- **Progressive disclosure** — keep CLAUDE.md minimal, put domain knowledge in separate docs
- **Task framing** — encourage Intent (why), Goal (what success looks like), Path (efficient route)
