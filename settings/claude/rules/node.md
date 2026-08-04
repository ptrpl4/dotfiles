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
- `n` itself is a Homebrew formula, but Node is not — it lives under `$N_PREFIX` (`~/.n`).
  Never `brew install node`, and don't expect Node in `brew list`/`brew leaves`
