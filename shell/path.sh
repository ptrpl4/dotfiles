# Single source of truth for PATH. Sourcing it runs it; the helpers are
# remove-then-add, so re-sourcing re-asserts order instead of duplicating.
# No shebang: this is sourced, never executed. It needs bash or zsh — the
# ${var//x/y} below is not POSIX and silently no-ops under dash.
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
# Looped, because the match consumes the shared separator: a single pass turns
# ":a:a:" into ":a:" rather than "::", leaving one stale copy mid-PATH. zsh
# hides this behind `typeset -U`; bash has no equivalent.
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

# Appends first, then prepends in reverse priority — each prepend takes the
# head, so the last one ends up first.
_dfp_append  "$HOME/go/bin"

# /etc/paths and /etc/paths.d are read by path_helper in login shells only, so
# re-add the entries that carry real tools — go, podman and /usr/local/bin. (n
# no longer installs there; see N_PREFIX below.) The rest of /etc/paths.d is
# Apple's (cryptex, rvictl) plus /pkg/env/global/bin, which does not exist here;
# the -d guard would skip it anyway. /usr/local/bin is prepended below podman so the order matches what
# path_helper produces in a login shell.
_dfp_append  "/usr/local/go/bin"
_dfp_prepend "/usr/local/bin"
_dfp_prepend "/opt/podman/bin"

_dfp_prepend "/opt/homebrew/sbin"
_dfp_prepend "/opt/homebrew/bin"   # python3/pip3 live here; bare python is not wanted
# n installs into $N_PREFIX/{bin,lib,include,share}. Unset, it writes to
# /usr/local and needs sudo — and sudo's env_reset drops this var, so `sudo n`
# lands in /usr/local no matter what is set here. Run n without sudo. This
# belongs in the PATH file rather than a shell rc: it decides where a binary
# lands, so it must not drift away from the prepend on the next line, and every
# shell needs it — n run from a script or a non-interactive shell must not pick
# a different prefix than an interactive one.
export N_PREFIX="$HOME/.local"

_dfp_prepend "$HOME/.local/bin"
_dfp_prepend "$DOTFILES/bin"

export PATH
