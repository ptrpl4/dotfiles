---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/.python-version"
---

# Python Rules

For ad-hoc/internal scripts (analysis, scratch work, one-off tooling) — fast and secure over feature-complete.

## Fast
- `python3` is on PATH (3.14, Homebrew) — no venv for one-off scripts, just run it
- Prefer stdlib before reaching for a dependency: `pathlib` over `os.path`, `tomllib` (3.11+) over a TOML lib, `json`/`csv`/`sqlite3` before pandas for anything small
- Builtin generics, not `typing`: `list[str]`, `dict[str, int]`, `X | None` — not `List[str]`, `Optional[X]`

## Secure
- Never `subprocess.run(cmd, shell=True)` with interpolated input — pass args as a list
- Never `eval`/`exec` on external or user-controlled input
- `yaml.safe_load`, never `yaml.load`
- `secrets` module for tokens/passwords, never `random`
- Validate/normalize file paths before write operations — avoid path traversal
