# If not running interactively, exit script
[[ $- != *i* ]] && return

# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth  # skip dupes + space-prefixed
shopt -s histappend     # append, don't overwrite

# Load dotfiles:
for file in ~/.{bash_prompt,aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Set PATHS
## Brew
if [ -x "/opt/homebrew/bin/brew" ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

## Android Studio
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator

## Node Version Manager (lazy loaded for performance)
export NVM_DIR="$HOME/nvm"

_nvm_load() {
  unset -f nvm node npm npx pnpm _nvm_load
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
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

export BASH_SILENCE_DEPRECATION_WARNING=1

## Docker
export PATH=$PATH:$HOME/.docker/bin

## VSCode
if [ -d "/Applications/Visual Studio Code.app" ]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

### Add custom Docker completion for bash
if [ -d ~/.docker/completions ]; then
  for completion_file in ~/.docker/completions/*; do
    # Skip Zsh completion files (those starting with _)
    [[ "$(basename "$completion_file")" == _* ]] && continue
    if [ -f "$completion_file" ]; then
      source "$completion_file"
    fi
  done
fi

## golang
export PATH="$PATH:$HOME/go/bin"

## dotfiles scripts
export PATH="$HOME/dotfiles/bin:$PATH"
