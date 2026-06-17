---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/package.json"
  - "**/.node-version"
  - "**/.nvmrc"
---

# Node / n Rules

- `n` is the Node version manager — use `n <version>` or `n auto` to switch versions
- If the project has `.node-version` or `.nvmrc`, run `n auto` before assuming the right Node version is active
- `node`, `npm`, `npx`, `pnpm` are available directly on PATH via `n`'s active version
