# Load .bashrc if available
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Set PATHS
## Brew
if [ -x "/opt/homebrew/bin/brew" ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

## Android Studio
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/tools/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools

## Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export BASH_SILENCE_DEPRECATION_WARNING=1

## Docker
export PATH=$PATH:$HOME/.docker/bin

### Add custom Docker completion for bash
if [ -d ~/.docker/completions ]; then
  for completion_file in ~/.docker/completions/*; do
    if [ -f "$completion_file" ]; then
      source "$completion_file"
    fi
  done
fi
