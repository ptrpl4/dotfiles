# Sourced for ALL zsh shells (interactive, non-interactive, login, non-login).
# Keep this minimal — only PATH and env vars that must be available everywhere.

## Node Version Manager — ensure nvm default node is always in PATH
## (IDE task runners like Zed and VS Code spawn non-login shells)
export NVM_DIR="$HOME/nvm"
if [ -d "$NVM_DIR/versions/node" ]; then
  _nvm_alias=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
  if [ -n "$_nvm_alias" ]; then
    _nvm_resolved=$(ls -1d "$NVM_DIR/versions/node/v${_nvm_alias}"* 2>/dev/null | sort -V | tail -1)
    [ -d "$_nvm_resolved/bin" ] && export PATH="$_nvm_resolved/bin:$PATH"
    unset _nvm_resolved
  fi
  unset _nvm_alias
fi
