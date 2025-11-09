# Set PATHS and Completions
## Brew
if [ -x "/opt/homebrew/bin/brew" ]; then
    # For Apple Silicon Macs
    export PATH="/opt/homebrew/bin:$PATH"
    export PATH="/opt/homebrew/sbin:$PATH"
fi

## Android Studio
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator

## Brew Completions
if command -v brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

## Node Version Manager (lazy loaded for performance)
export NVM_DIR="$HOME/nvm"

# Lazy load NVM - only load when node/npm/nvm is actually used
nvm() {
  unset -f nvm node npm npx
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  fi
  nvm "$@"
}

node() {
  unset -f nvm node npm npx
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  fi
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  fi
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  fi
  npx "$@"
}

## Docker
if [[ -d /Applications/Docker.app ]] || [[ -d ~/.docker/bin ]] || [[ -f /usr/local/bin/docker ]]; then
  export PATH="$HOME/.docker/bin:$PATH" # custom docker installation

  ### Add custom Docker completion directory to fpath
  if [[ -d ~/.docker/completions ]]; then
    fpath=(~/.docker/completions $fpath)
  else
    echo "Warning: Docker completions directory not found at ~/.docker/completions"
  fi
fi

## VSCode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

## Initialize completion system (optimized with cache)
autoload -Uz compinit
# Only rebuild completion cache once a day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qNmh-24) ]]; then
  compinit -C  # Skip security check, use cached
else
  compinit     # Rebuild cache
fi
