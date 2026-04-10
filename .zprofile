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
# NVM_DIR is exported in .zshenv. PATH resolution lives here because macOS runs
# path_helper in /etc/zprofile (before ~/.zprofile), which rearranges PATH and
# would push a .zshenv prepend down. Adding it here ensures NVM node wins.
if [[ -n "$NVM_DIR" && -d "$NVM_DIR/versions/node" ]]; then
  _nvm_alias=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
  if [[ -n "$_nvm_alias" ]]; then
    _nvm_resolved=$(ls -1d "$NVM_DIR/versions/node/v${_nvm_alias}"* 2>/dev/null | sort -V | tail -1)
    [[ -d "$_nvm_resolved/bin" ]] && export PATH="$_nvm_resolved/bin:$PATH"
    unset _nvm_resolved
  fi
  unset _nvm_alias
fi

# Lazy-load full nvm in interactive shells only — PATH above is enough for non-interactive.
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

## Python (Homebrew, keg-only)
if [[ -d "/opt/homebrew/opt/python@3.13" ]]; then
  export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
fi

## local binaries (pipx, poetry, etc.)
export PATH="$HOME/.local/bin:$PATH"

## dotfiles scripts
export PATH="$HOME/dotfiles/bin:$PATH"
