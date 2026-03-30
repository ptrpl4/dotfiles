#!/usr/bin/env bash
# Claude Code status line — mirrors shell PS1 style from ~/.zprompt

input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

# Print ─[content] segment if value is non-empty
seg() {
    [[ -n "$1" ]] && printf "%b─[%b%s%b]" "$gray" "$reset" "$1" "$gray"
}

# ── Shell-mirrored segments ──────────────────────────────────────────────────

# Time: matches prompt_time()
h=$(date +"%H")
m=$(date +"%M")
printf "%b─[%b%s%b:%b%s%b]" "$gray" "$reset" "$h" "$gray" "$reset" "$m" "$gray"

# User
seg "$(whoami)"

# Directory (basename, matches %c)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd' 2>/dev/null)
seg "$(basename "$cwd")"

# Git: matches prompt_git_box()
git_branch=""
git_status=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
                 || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null \
                 || echo "?")
    git_branch=$(echo "$git_branch" | tr '[:upper:]' '[:lower:]')

    upstream=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        ahead_behind=$(git --no-optional-locks -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        ahead=${ahead_behind%%[[:space:]]*}
        behind=${ahead_behind##*[[:space:]]}
        ahead=${ahead:-0}
        behind=${behind:-0}
        [[ "$behind" -gt 0 ]] && git_status+="↓${behind}"
        [[ "$ahead" -gt 0 ]]  && git_status+="↑${ahead}"
        [[ "$ahead" -eq 0 ]] && [[ "$behind" -eq 0 ]] && git_status+="✓"
    fi

    if [[ -n "$git_status" ]]; then
        printf "%b─[%bgit%b:%b%s%b:%b%s%b]" \
            "$gray" "$reset" "$gray" "$reset" "$git_branch" "$gray" "$reset" "$git_status" "$gray"
    else
        printf "%b─[%bgit%b:%b%s%b]" "$gray" "$reset" "$gray" "$reset" "$git_branch" "$gray"
    fi
fi

# ── Claude-specific segments ─────────────────────────────────────────────────

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
seg "$model"

# Context used %
ctx_used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
[[ -n "$ctx_used_pct" ]] && seg "ctx $(printf '%.0f' "$ctx_used_pct")%"

printf "%b\n" "$reset"
