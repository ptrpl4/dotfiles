# Set PATHS and Completions
## Brew
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    # For Apple Silicon Macs
    export PATH="/opt/homebrew/bin:$PATH"
    export PATH="/opt/homebrew/sbin:$PATH"
fi

## Android Studio
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator

## Brew Completions
if command -v brew &>/dev/null; then
  FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
fi

## Node Version Manager
# NVM_DIR and default node PATH are set in .zshenv (sourced for all shells).
# Lazy load full NVM only in interactive shells — non-interactive shells
# (CI, IDE subprocesses, Claude Code Bash tool) already have node on PATH via .zshenv.
if [[ -o interactive ]]; then
  _nvm_load() {
    unfunction nvm node npm npx pnpm _nvm_load 2>/dev/null
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
      . "$NVM_DIR/nvm.sh"
    else
      echo "Warning: nvm not found at $NVM_DIR/nvm.sh" >&2
      return 1
    fi
  }

  nvm()  { _nvm_load && nvm  "$@"; }
  node() { _nvm_load && node "$@"; }
  npm()  { _nvm_load && npm  "$@"; }
  npx()  { _nvm_load && npx  "$@"; }
  pnpm() { _nvm_load && pnpm "$@"; }
fi

## Docker
if [[ -d /Applications/Docker.app ]] || [[ -d ~/.docker/bin ]] || [[ -f /usr/local/bin/docker ]]; then
  export PATH="$HOME/.docker/bin:$PATH" # custom docker installation

  [[ -d ~/.docker/completions ]] && fpath=(~/.docker/completions $fpath)
fi

## VSCode
if [[ -d "/Applications/Visual Studio Code.app" ]]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

## Initialize completion system (optimized with cache)
autoload -Uz compinit
# Only rebuild completion cache once a day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qNmh-24) ]]; then
  compinit -C  # Skip security check, use cached
else
  compinit     # Rebuild cache
fi

## golang
export PATH="$PATH:$HOME/go/bin"

## Default editor
if command -v zed &>/dev/null; then
  export EDITOR="zed --wait"
  export VISUAL="zed --wait"
fi

## local binaries (pipx, poetry, etc.)
export PATH="$HOME/.local/bin:$PATH"

## dotfiles scripts
export PATH="$HOME/dotfiles/bin:$PATH"
