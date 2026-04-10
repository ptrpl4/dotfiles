---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/package.json"
  - "**/.nvmrc"
---

# Node / NVM Rules

- `nvm` is a shell function — not available in the Bash tool directly. Source it first:
  `. "$NVM_DIR/nvm.sh" && nvm <command>`
- If the project has `.nvmrc`, run `. "$NVM_DIR/nvm.sh" && nvm install` before assuming the right Node version is active
- Prefer `node`, `npm`, `npx`, `pnpm` directly (available on PATH via NVM default) — only source nvm.sh when you need `nvm use` or `nvm install`
