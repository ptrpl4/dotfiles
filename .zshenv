# Sourced for ALL zsh shells (interactive, non-interactive, login, non-login).
# Keep this minimal — only PATH and env vars that must be available everywhere.

# /etc/paths.d entries are applied by path_helper, which runs from /etc/zprofile
# — login shells only. Tools installed there (podman's official pkg) are invisible
# to non-login shells: Makefiles, editor terminals, agent tooling. Re-add here.
# Note path_helper does not prepend — it rebuilds PATH from /etc/paths{,.d} and
# appends whatever was already there, so entries set here land at the tail in login
# shells. That is fine for podman — nothing competes with it — but `n` must outrank
# any system node, so it alone is re-prepended in .zprofile, which runs after
# path_helper. `typeset -U` drops the demoted duplicate.
typeset -U path PATH
[[ -d /opt/podman/bin ]] && path=(/opt/podman/bin $path)

# n installs node/npm under N_PREFIX, not Homebrew. Same login-shell problem:
# set here so node resolves in Makefiles and editor terminals, not just logins.
export N_PREFIX="$HOME/.n"
[[ -d "$N_PREFIX/bin" ]] && path=("$N_PREFIX/bin" $path)

export PATH
