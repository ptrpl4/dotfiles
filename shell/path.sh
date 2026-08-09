#!/bin/sh
# Single source of truth for PATH. Sourcing it runs it; the helpers are
# remove-then-add, so re-sourcing re-asserts order instead of duplicating.
#
# Sourced from: zshenv (every zsh) · zprofile (again, after path_helper demotes
# it) · bashrc (compatibility path). Shared, so no zsh-only syntax. Parameter
# expansion rather than sed — this runs on every zsh, and forking to build a
# PATH costs measurable startup time.
#
# Installers append their own `export PATH=` to the bottom of some rc file and
# win by running last, which is usually right. Hoist the line in here when the
# tool should also reach non-interactive shells.

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Remove-then-add, never skip-if-present: in a login shell path_helper has
# already placed /opt/homebrew/bin mid-PATH, and skipping would strand it
# behind /usr/local/bin. Adds are -d guarded, so missing dirs cost nothing.
_dfp_remove() {
    _dfp_p=":${PATH}:"
    _dfp_p="${_dfp_p//":$1:"/:}"
    _dfp_p="${_dfp_p#:}"
    PATH="${_dfp_p%:}"
    unset _dfp_p
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

# Appends first, then prepends in reverse priority — each prepend takes the
# head, so the last one ends up first.
_dfp_append  "$HOME/go/bin"

# /etc/paths.d is read by path_helper in login shells only; re-add so Makefiles
# and agent tooling see these too.
_dfp_append  "/usr/local/go/bin"
_dfp_prepend "/opt/podman/bin"

_dfp_prepend "/opt/homebrew/sbin"
_dfp_prepend "/opt/homebrew/bin"   # python3/pip3 live here; bare python is not wanted
_dfp_prepend "$HOME/.local/bin"
_dfp_prepend "$DOTFILES/bin"

export PATH
