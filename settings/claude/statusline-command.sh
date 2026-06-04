#!/usr/bin/env bash
# Claude Code status line — mirrors shell PS1 style from ~/.zprompt

input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
orange=$(tput setaf 214 2>/dev/null || printf '\033[38;5;214m')
red=$(tput setaf 1 2>/dev/null || printf '\033[31m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

# Print ─[content] segment if value is non-empty
seg() {
    [[ -n "$1" ]] && printf "%b─[%b%s%b]" "$gray" "$reset" "$1" "$gray"
}

# ── Shell-mirrored segments ──────────────────────────────────────────────────

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

# Context: compute used tokens from percentage * window size; color by threshold
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
if [[ -n "$ctx_pct" && -n "$ctx_size" ]]; then
    ctx_used=$(awk "BEGIN{printf \"%d\", int($ctx_pct/100*$ctx_size/1000)}")
    ctx_total=$(awk "BEGIN{printf \"%d\", int($ctx_size/1000)}")
    ctx_str="${ctx_used}k/${ctx_total}k"
    if [[ "$ctx_pct" -ge 88 ]]; then
        ctx_color="$red"
    elif [[ "$ctx_pct" -ge 75 ]]; then
        ctx_color="$orange"
    else
        ctx_color="$reset"
    fi
    printf "%b─[%bctx %b%s%b]" "$gray" "$reset" "$ctx_color" "$ctx_str" "$gray"
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
seg "$model"

# Model+effort combo — flag suboptimal pairings with !
effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
effort_label=""
case "$effort" in
    low)    effort_label="lo" ;;
    medium) effort_label="med" ;;
    high)   effort_label="hi" ;;
    max)    effort_label="max" ;;
    auto)   effort_label="auto" ;;
esac

if [[ -n "$effort_label" && -n "$model" ]]; then
    model_lc=$(echo "$model" | tr '[:upper:]' '[:lower:]')
    warn=""
    # opus/low: paying top price for minimum thinking
    [[ "$model_lc" == *opus* && "$effort" == "low" ]] && warn="!"
    # haiku/high or haiku/max: effort ceiling on cheapest model
    [[ "$model_lc" == *haiku* && ( "$effort" == "high" || "$effort" == "max" ) ]] && warn="!"
    seg "${effort_label}${warn}"
elif [[ -n "$effort_label" ]]; then
    seg "$effort_label"
fi

# Cost + rate limits: ─[$3.8 5h:20 7d:2]
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
limits_str=""
[[ -n "$cost" ]] && limits_str+="$(awk "BEGIN{printf \"\$%.1f\", $cost}")"
if [[ -n "$rl5h" ]]; then
    rl5h_color=""
    [[ "$rl5h" -ge 88 ]] && rl5h_color="$red"
    [[ "$rl5h" -ge 75 && "$rl5h" -lt 88 ]] && rl5h_color="$orange"
    [[ -n "$limits_str" ]] && limits_str+=" "
    limits_str+="${rl5h_color}5h:${rl5h}${gray}"
fi
if [[ -n "$rl7d" ]]; then
    rl7d_color=""
    [[ "$rl7d" -ge 88 ]] && rl7d_color="$red"
    [[ "$rl7d" -ge 75 && "$rl7d" -lt 88 ]] && rl7d_color="$orange"
    [[ -n "$limits_str" ]] && limits_str+=" "
    limits_str+="${rl7d_color}7d:${rl7d}${gray}"
fi
[[ -n "$limits_str" ]] && printf "%b─[%b%s%b]" "$gray" "$reset" "$limits_str" "$gray"

printf "%b\n" "$reset"
