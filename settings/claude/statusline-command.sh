#!/usr/bin/env bash
# Claude Code status line

input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

seg() {
    # helper: print ─[content] segment if value is non-empty
    [ -n "$1" ] && printf "%b─[%b%s%b]" "$gray" "$reset" "$1" "$gray"
}

# Time
time_str=$(date +"%H:%M")

# User & dir
user=$(whoami)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd' 2>/dev/null)
dir=$(basename "$cwd")

# Git branch
git_branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
                 || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
                 || echo "?")
    git_branch=$(echo "$git_branch" | tr '[:upper:]' '[:lower:]')
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)

# Context window
ctx_used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
ctx_total=$(echo "$input" | jq -r '.context_window.total_tokens // empty' 2>/dev/null)
ctx_used=$(echo "$input" | jq -r '.context_window.used_tokens // empty' 2>/dev/null)

# Format token counts as "Xk"
[ -n "$ctx_total" ] && ctx_total=$(awk "BEGIN{printf \"%.0fk\", $ctx_total/1000}")
[ -n "$ctx_used" ] && ctx_used=$(awk "BEGIN{printf \"%.0fk\", $ctx_used/1000}")

# Session info
session_id=$(echo "$input" | jq -r '.session.id // empty' 2>/dev/null)
[ -n "$session_id" ] && session_id=$(echo "$session_id" | cut -c1-8)
cost=$(echo "$input" | jq -r '.session.cost // empty' 2>/dev/null)
[ -n "$cost" ] && cost=$(printf '$%.2f' "$cost")
duration_ms=$(echo "$input" | jq -r '.session.duration_ms // empty' 2>/dev/null)
if [ -n "$duration_ms" ]; then
    total_sec=$((duration_ms / 1000))
    mins=$((total_sec / 60))
    secs=$((total_sec % 60))
    duration=$(printf '%dm%02ds' "$mins" "$secs")
fi
msg_count=$(echo "$input" | jq -r '.session.message_count // empty' 2>/dev/null)

# Build output
printf "%b[%b%s%b]" "$gray" "$reset" "$time_str" "$gray"
seg "$user"
seg "$dir"
[ -n "$git_branch" ] && printf "%b─[%bgit%b:%b%s%b]" "$gray" "$reset" "$gray" "$reset" "$git_branch" "$gray"
seg "$model"
[ -n "$ctx_used_pct" ] && seg "ctx ${ctx_used_pct}%"
[ -n "$ctx_used" ] && [ -n "$ctx_total" ] && seg "${ctx_used}/${ctx_total}"
seg "$session_id"
seg "$cost"
seg "$duration"
[ -n "$msg_count" ] && seg "${msg_count}msgs"
printf "%b\n" "$reset"
