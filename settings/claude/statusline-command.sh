#!/usr/bin/env bash
input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
orange=$(tput setaf 214 2>/dev/null || printf '\033[38;5;214m')
red=$(tput setaf 1 2>/dev/null || printf '\033[31m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

seg() { [[ -n "$1" ]] && printf "%b─[%b%s%b]" "$gray" "$reset" "$1" "$gray"; }
j()   { jq -r "$1" <<< "$input" 2>/dev/null; }

# Directory
cwd=$(j '.workspace.current_dir // .cwd // empty')
printf "%b[%b%s%b]" "$gray" "$reset" "$(basename "$cwd")" "$gray"

# Git
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
             || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null \
             || echo "?")
    branch=$(tr '[:upper:]' '[:lower:]' <<< "$branch")
    git_status=""
    upstream=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        read -r ahead behind < <(git --no-optional-locks -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        ahead=${ahead:-0}; behind=${behind:-0}
        [[ "$behind" -gt 0 ]] && git_status+="↓${behind}"
        [[ "$ahead"  -gt 0 ]] && git_status+="↑${ahead}"
        [[ "$ahead" -eq 0 && "$behind" -eq 0 ]] && git_status="✓"
    fi
    if [[ -n "$git_status" ]]; then
        printf "%b─[%bgit%b:%b%s%b:%b%s%b]" "$gray" "$reset" "$gray" "$reset" "$branch" "$gray" "$reset" "$git_status" "$gray"
    else
        printf "%b─[%bgit%b:%b%s%b]" "$gray" "$reset" "$gray" "$reset" "$branch" "$gray"
    fi
fi

# Context + Model
ctx_pct=$(j '.context_window.used_percentage // empty')
ctx_size=$(j '.context_window.context_window_size // empty')
model=$(j '.model.display_name // empty')
if [[ -n "$ctx_pct" && -n "$ctx_size" ]]; then
    read -r ctx_used ctx_total < <(awk "BEGIN{printf \"%d %d\", int($ctx_pct/100*$ctx_size/1000), int($ctx_size/1000)}")
    ctx_color="$reset"
    [[ "$ctx_pct" -ge 75 ]] && ctx_color="$orange"
    [[ "$ctx_pct" -ge 88 ]] && ctx_color="$red"
    seg_content="${ctx_used}/${ctx_total}k"
    [[ -n "$model" ]] && seg_content+=" $(tr ' ' '-' <<< "$model")"
    printf "%b─[%b%s%b]" "$gray" "$ctx_color" "$seg_content" "$gray"
elif [[ -n "$model" ]]; then
    seg "$(tr ' ' '-' <<< "$model")"
fi

# Effort
effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
case "$effort" in
    low) label="lo" ;; medium) label="med" ;; high) label="hi" ;;
    max) label="max" ;; auto) label="auto" ;; *) label="" ;;
esac
if [[ -n "$label" ]]; then
    warn=""
    model_lc=$(tr '[:upper:]' '[:lower:]' <<< "$model")
    [[ "$model_lc" == *opus*  && "$effort" == "low" ]] && warn="!"
    [[ "$model_lc" == *haiku* && ( "$effort" == "high" || "$effort" == "max" ) ]] && warn="!"
    seg "${label}${warn}"
fi

# Cost + rate limits
cost=$(j '.cost.total_cost_usd // empty')
rl5h=$(j 'if .rate_limits.five_hour.used_percentage then (.rate_limits.five_hour.used_percentage | floor | tostring) else empty end')
rl7d=$(j 'if .rate_limits.seven_day.used_percentage then (.rate_limits.seven_day.used_percentage | floor | tostring) else empty end')
limits=""
[[ -n "$cost" ]] && limits="$(awk "BEGIN{printf \"\$%.1f\", $cost}")"
if [[ -n "$rl5h" || -n "$rl7d" ]]; then
    max_rl=${rl5h:-0}; [[ -n "$rl7d" && "$rl7d" -gt "$max_rl" ]] && max_rl=$rl7d
    rl_color=""
    [[ "$max_rl" -ge 75 ]] && rl_color="$orange"
    [[ "$max_rl" -ge 88 ]] && rl_color="$red"
    [[ -n "$limits" ]] && limits+=" "
    limits+="${rl_color}${rl5h:-?}/${rl7d:-?}%${gray}"
fi
[[ -n "$limits" ]] && printf "%b─[%b%s%b]" "$gray" "$reset" "$limits" "$gray"

printf "%b\n" "$reset"
