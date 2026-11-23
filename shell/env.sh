# PATH and env shared by every shell; sourced, never executed. bash or zsh only:
# ${var//x/y} silently no-ops under dash.

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Remove-then-add rather than skip-if-present, so re-sourcing after path_helper
# restores order. Looped because one pass leaves a copy of ":a:a:".
_dfp_remove() {
    _dfp_p=":${PATH}:"
    while :; do
        _dfp_q="${_dfp_p//":$1:"/:}"
        [ "$_dfp_q" = "$_dfp_p" ] && break
        _dfp_p="$_dfp_q"
    done
    _dfp_p="${_dfp_p#:}"
    PATH="${_dfp_p%:}"
    unset _dfp_p _dfp_q
}

_dfp_prepend() {
    [ -d "$1" ] || return 0
    _dfp_remove "$1"
    PATH="$1${PATH:+:$PATH}"
}

_dfp_append() {
    [ -d "$1" ] || return 0
    _dfp_remove "$1"
    PATH="${PATH:+$PATH:}$1"
}

# Prepends run in reverse priority: the last one ends up first.
_dfp_append  "$HOME/go/bin"

# path_helper only runs in login shells; re-add the /etc/paths{,.d} entries that matter.
_dfp_append  "/usr/local/go/bin"
_dfp_prepend "/usr/local/bin"
_dfp_prepend "/opt/podman/bin"

_dfp_prepend "/opt/homebrew/sbin"
_dfp_prepend "/opt/homebrew/bin"

# Run n without sudo: env_reset drops N_PREFIX and n falls back to /usr/local.
export N_PREFIX="$HOME/.local"

_dfp_prepend "$HOME/.local/bin"
_dfp_prepend "$DOTFILES/bin"

# glab rewrites its config in place; local/ is gitignored and seeded by install.sh.
export GLAB_CONFIG_DIR="$DOTFILES/settings/glab/local"

export PATH
