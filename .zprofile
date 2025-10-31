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

## Node Version Manager
export NVM_DIR="$HOME/nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"  # This loads nvm
else
  echo "Warning: NVM script not found at $NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
else
  echo "Warning: NVM bash completion not found at $NVM_DIR/bash_completion"
fi

## Docker
export PATH="$HOME/.docker/bin:$PATH" # custom docker installation

### Add custom Docker completion directory to fpath
if [[ -d ~/.docker/completions ]]; then
  fpath=(~/.docker/completions $fpath)
else
  echo "Warning: Docker completions directory not found at ~/.docker/completions"
fi

## VSCode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

## Initialize completion system
autoload -Uz compinit
compinit 