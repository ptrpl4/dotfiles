#!/usr/bin/env bash
input=$(cat)

gray=$(tput setaf 8 2>/dev/null || printf '\033[90m')
orange=$(tput setaf 214 2>/dev/null || printf '\033[38;5;214m')
red=$(tput setaf 1 2>/dev/null || printf '\033[31m')
reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

# Pull every field from the stdin JSON in a single jq pass, one value per line,
# rather than forking jq once per field. Newline-delimited (not tab) so empty
# fields keep their position — the read loop preserves blank lines.
F=()
while IFS= read -r line; do F+=("$line"); done < <(
    jq -r '
      def num: if . == null then "" else floor end;
      (.workspace.current_dir // .cwd // ""),
      (.context_window.used_percentage | num),
      (.context_window.context_window_size // ""),
      (.model.display_name // ""),
      (.effort.level // ""),
      (.rate_limits.five_hour.used_percentage | num),
      (.rate_limits.seven_day.used_percentage | num),
      (.rate_limits.five_hour.resets_at | num)
    ' <<< "$input" 2>/dev/null
)
cwd=${F[0]}
ctx_pct=${F[1]}
ctx_size=${F[2]}
model=${F[3]}
effort=${F[4]}
rl5h=${F[5]}
rl7d=${F[6]}
rl5h_reset=${F[7]}

first=1
sep() { if [[ $first -eq 1 ]]; then first=0; else printf "%b · " "$gray"; fi; }
# format a value in thousands: 50 -> "50k", 1000 -> "1M", 1500 -> "1.5M"
fmtk() { awk "BEGIN{v=$1; if (v>=1000){v/=1000; if(v==int(v)) printf \"%dM\",v; else printf \"%.1fM\",v} else printf \"%dk\",v}"; }

# Directory
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
# strip trailing parenthetical, e.g. "Opus 4.8 (1M context)" -> "Opus 4.8"
model="${model%% (*}"
model_full="$model"
# "Sonnet 4.6" -> "So-4.6" (kept long for warn check below)
if [[ -n "$model" ]]; then
    model=$(sed 's/\([A-Za-z][A-Za-z]\)[A-Za-z]* \(.*\)/\1-\2/' <<< "$model")
fi
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
