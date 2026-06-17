# Set PATHS and Completions
typeset -U PATH path

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

## n (Node version manager)
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

## local binaries (pipx, poetry, etc.)
export PATH="$HOME/.local/bin:$PATH"

## dotfiles scripts
export PATH="$HOME/dotfiles/bin:$PATH"
