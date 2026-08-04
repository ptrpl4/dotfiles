# ─── Environment ──────────────────────────────────────────────────────────────
# Sits above the interactive guard, so it covers (bash(1) INVOCATION):
#   - interactive shells                        — .bashrc proper
#   - `bash -l` / `bash -lc`                    — via .bash_profile
#   - `ssh host 'cmd'` where bash is the LOGIN shell (the Pi; not this Mac, whose
#     UserShell is /bin/zsh) — bash reads .bashrc when stdin is a socket
# It does NOT cover `bash -c` or `make`: bash reads .bashrc only in the cases
# above, and there is no bash equivalent of `.zshenv`. BASH_ENV is consulted only
# by non-interactive shells and must already be exported by an ancestor to reach
# `make`, so it is not a clean fix.

# Bash has no `typeset -U`. These mirror it: an entry already in PATH is MOVED,
# not skipped — in a login shell /etc/profile runs path_helper first, so skipping
# would leave e.g. /opt/homebrew/bin stuck at the mid-PATH slot path_helper gave
# it, behind /usr/local/bin.
path_remove() {
    local p=":${PATH}:"
    p="${p//":$1:"/:}"
    p="${p#:}"
    PATH="${p%:}"
}

path_prepend() {
    [[ -d "$1" ]] || return 0
    path_remove "$1"
    PATH="$1${PATH:+:$PATH}"
}

path_append() {
    [[ -d "$1" ]] || return 0
    path_remove "$1"
    PATH="${PATH:+$PATH:}$1"
}

## Brew
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    path_prepend "/opt/homebrew/sbin"
    path_prepend "/opt/homebrew/bin"
fi

## Android Studio
export ANDROID_HOME=~/Library/Android/sdk
path_append "$ANDROID_HOME/emulator"

## Docker
path_prepend "$HOME/.docker/bin"

## VSCode
path_append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

## golang
path_append "$HOME/go/bin"

## dotfiles scripts
path_prepend "$HOME/dotfiles/bin"

export PATH
export BASH_SILENCE_DEPRECATION_WARNING=1

unset -f path_prepend path_append path_remove

# ─── Interactive only ─────────────────────────────────────────────────────────
[[ $- != *i* ]] && return

# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth  # skip dupes + space-prefixed
shopt -s histappend     # append, don't overwrite

# Load dotfiles:
for file in ~/.{bash_prompt,aliases,private}; do
    [[ -r "$file" ]] && source "$file"
done
unset file

## Docker completions
if [[ -d ~/.docker/completions ]]; then
  for completion_file in ~/.docker/completions/*; do
    [[ "$(basename "$completion_file")" == _* ]] && continue
    [[ -f "$completion_file" ]] && source "$completion_file"
  done
  unset completion_file
fi
