#!/usr/bin/env bash
input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
orange=$(tput setaf 214 2>/dev/null || printf '\033[38;5;214m')
red=$(tput setaf 1 2>/dev/null || printf '\033[31m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

first=1
sep() { if [[ $first -eq 1 ]]; then first=0; else printf "%b · " "$gray"; fi; }
j()   { jq -r "$1" <<< "$input" 2>/dev/null; }
# format a value in thousands: 50 -> "50k", 1000 -> "1M", 1500 -> "1.5M"
fmtk() { awk "BEGIN{v=$1; if (v>=1000){v/=1000; if(v==int(v)) printf \"%dM\",v; else printf \"%.1fM\",v} else printf \"%dk\",v}"; }

# Directory
cwd=$(j '.workspace.current_dir // .cwd // empty')
dir=$(basename "$cwd")
if [[ ${#dir} -gt 24 ]]; then
    keep=$(( 24 - 3 ))
    head=$(( (keep + 1) / 2 ))
    tail=$(( keep / 2 ))
    dir="${dir:0:$head}...${dir: -$tail}"
fi
sep; printf "%b%s" "$reset" "$dir"

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
    sep
    if [[ -n "$git_status" ]]; then
        printf "%b%s %s" "$reset" "$branch" "$git_status"
    else
        printf "%b%s" "$reset" "$branch"
    fi
fi

# Context + Model + Effort
ctx_pct=$(j '.context_window.used_percentage // empty')
ctx_size=$(j '.context_window.context_window_size // empty')
model=$(j '.model.display_name // empty')
# strip trailing parenthetical, e.g. "Opus 4.8 (1M context)" -> "Opus 4.8"
model="${model%% (*}"
# "Sonnet 4.6" -> "So-4.6" (kept long for warn check below)
model_full="$model"
if [[ -n "$model" ]]; then
    model=$(sed 's/\([A-Za-z][A-Za-z]\)[A-Za-z]* \(.*\)/\1-\2/' <<< "$model")
fi
effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
case "$effort" in
    low) label="lo" ;; medium) label="med" ;; high) label="hi" ;;
    max) label="max" ;; auto) label="auto" ;; *) label="" ;;
esac
if [[ -n "$label" && -n "$model" ]]; then
    warn=""
    model_lc=$(tr '[:upper:]' '[:lower:]' <<< "$model_full")
    [[ "$model_lc" == *opus*  && "$effort" == "low" ]] && warn="!"
    [[ "$model_lc" == *haiku* && ( "$effort" == "high" || "$effort" == "max" ) ]] && warn="!"
    model="${model}-${label}${warn}"
fi
if [[ -n "$ctx_pct" && -n "$ctx_size" ]]; then
    read -r ctx_used ctx_total < <(awk "BEGIN{printf \"%d %d\", int($ctx_pct/100*$ctx_size/1000), int($ctx_size/1000)}")
    ctx_color="$reset"
    # color by percentage (small contexts) or absolute used tokens (1M contexts)
    [[ "$ctx_pct" -ge 75 || "$ctx_used" -ge 200 ]] && ctx_color="$orange"
    [[ "$ctx_pct" -ge 88 || "$ctx_used" -ge 400 ]] && ctx_color="$red"
    seg_content="$(fmtk "$ctx_used")/$(fmtk "$ctx_total")"
    [[ -n "$model" ]] && seg_content+=" $model"
    sep; printf "%b%s" "$ctx_color" "$seg_content"
elif [[ -n "$model" ]]; then
    sep; printf "%b%s" "$reset" "$model"
fi

# Rate limits
rl5h=$(j 'if .rate_limits.five_hour.used_percentage then (.rate_limits.five_hour.used_percentage | floor | tostring) else empty end')
rl7d=$(j 'if .rate_limits.seven_day.used_percentage then (.rate_limits.seven_day.used_percentage | floor | tostring) else empty end')
rl5h_reset=$(j '.rate_limits.five_hour.resets_at // empty')
limits=""
if [[ -n "$rl5h" || -n "$rl7d" ]]; then
    max_rl=${rl5h:-0}; [[ -n "$rl7d" && "$rl7d" -gt "$max_rl" ]] && max_rl=$rl7d
    rl_color=""
    [[ "$max_rl" -ge 75 ]] && rl_color="$orange"
    [[ "$max_rl" -ge 88 ]] && rl_color="$red"
    limits+="${rl_color}${rl5h:-?}/${rl7d:-?}%${gray}"
    if [[ -n "$rl5h_reset" ]]; then
        now=$(date +%s)
        diff=$(( rl5h_reset - now ))
        if [[ "$diff" -gt 0 ]]; then
            mins=$(( diff / 60 ))
            limits+=" ↺${mins}m"
        fi
    fi
fi
[[ -n "$limits" ]] && { sep; printf "%b%s" "$reset" "$limits"; }

printf "%b\n" "$reset"
