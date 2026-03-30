---
paths:
  - "**/*.sh"
  - "**/.aliases"
  - "**/.bashrc"
  - "**/.bash_prompt"
  - "**/.zshrc"
  - "**/.zprofile"
  - "**/.zshenv"
  - "**/.zprompt"
  - "**/.prompt_common"
---

# Shell File Rules

- Use `bash` for scripts, `zsh` for interactive config
- Prefer functions over aliases when the body uses `$()` or arguments
- Quote all variable expansions: `"$var"`, `"$(cmd)"`
- Use `[[ ]]` in zsh/bash, `[ ]` only for POSIX sh compatibility
- Use `local` for all function-scoped variables
