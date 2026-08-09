#!/usr/bin/env bash
# Claude Code statusline. Runs on every render, so the only processes spawned
# are jq and one git call; everything else is bash builtins.
input=$(</dev/stdin)

gray=$'\033[90m'
orange=$'\033[38;5;214m'
red=$'\033[31m'
reset=$'\033[0m'

# Pull every field from the stdin JSON in a single jq pass, one value per line,
# rather than forking jq once per field. Newline-delimited (not tab) so empty
# fields keep their position — the read loop preserves blank lines.
#
# num must type-check rather than call floor directly: floor on a non-number
# aborts the whole program, and since jq streams, every field *after* the bad
# one is silently lost — a string used_percentage would reduce the statusline
# to just the directory.
F=()
while IFS= read -r line; do F+=("$line"); done < <(
    jq -r '
      def num: if type == "number" then floor else "" end;
      (.workspace.current_dir // .cwd // ""),
      (.context_window.used_percentage | num),
      (.context_window.context_window_size | num),
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
sep() { if [[ $first -eq 1 ]]; then first=0; else printf '%s · ' "$gray"; fi; }

# format a value in thousands: 50 -> "50k", 1000 -> "1M", 1500 -> "1.5M"
fmtk() {
    if (( $1 >= 1000 )); then
        local whole=$(( $1 / 1000 )) tenth=$(( ($1 % 1000) / 100 ))
        if (( tenth == 0 )); then printf '%dM' "$whole"; else printf '%d.%dM' "$whole" "$tenth"; fi
    else
        printf '%dk' "$1"
    fi
}

# shorten to max 20 chars with a middle ellipsis: "a-very-long-branch-name" ->
# "a-very-l..ranch-name"
shorten() {
    local s=$1 max=20 keep head tail
    if (( ${#s} > max )); then
        keep=$(( max - 2 ))
        head=$(( (keep + 1) / 2 ))
        tail=$(( keep / 2 ))
        s="${s:0:head}..${s: -tail}"
    fi
    printf '%s' "$s"
}

# Directory. Skipped entirely when cwd is unknown: `git -C ''` is a no-op, so
# the git block below would otherwise report this script's own repo.
if [[ -n $cwd && -d $cwd ]]; then
    dir=${cwd%/}; dir=${dir##*/}          # basename, without the fork
    sep; printf '%s%s' "$reset" "$(shorten "$dir")"
    dir_ok=1
fi

# Git. One for-each-ref rather than status: refs only, so the cost does not
# scale with worktree size or dirtiness. Branch case is preserved.
if [[ -n $dir_ok ]] && out=$(git --no-optional-locks -C "$cwd" for-each-ref \
        --format='%(HEAD)|%(refname:short)|%(upstream)|%(upstream:track,nobracket)' \
        refs/heads 2>/dev/null); then
    branch='' up='' track=''
    while IFS= read -r line; do
        [[ $line == '*|'* ]] || continue
        rest=${line#'*|'}
        # right to left: a branch name may contain '|', the other fields cannot
        track=${rest##*|}; rest=${rest%|*}
        up=${rest##*|};    branch=${rest%|*}
        break
    done <<< "$out"

    [[ -n $branch ]] || branch=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    if [[ -n $branch ]]; then
        git_status=''
        if [[ -n $up ]]; then
            if [[ $track == gone ]]; then
                git_status='gone'
            else
                ahead='' behind=''
                [[ $track == *'behind '* ]] && { behind=${track##*behind }; behind=${behind%%,*}; }
                [[ $track == *'ahead '*  ]] && { ahead=${track##*ahead };   ahead=${ahead%%,*}; }
                [[ -n $behind ]] && git_status+="↓${behind}"
                [[ -n $ahead  ]] && git_status+="↑${ahead}"
                [[ -z $git_status ]] && git_status='✓'
            fi
        fi
        sep
        if [[ -n $git_status ]]; then
            printf '%s%s %s' "$reset" "$(shorten "$branch")" "$git_status"
        else
            printf '%s%s' "$reset" "$(shorten "$branch")"
        fi
    fi
fi

# Context + Model + Effort
model=${model%% (*}          # "Opus 4.8 (1M context)" -> "Opus 4.8"
if [[ -n $model ]]; then
    case "$effort" in
        low) label=lo ;; medium) label=med ;; high) label=hi ;;
        max) label=max ;; auto) label=auto ;; *) label='' ;;
    esac
    warn=''
    # nocasematch rather than ${model,,}: case conversion is bash 4+, and this
    # script runs under whatever `bash` Claude Code's PATH resolves to — 3.2
    # when the app is launched from the Dock rather than a terminal. There the
    # bad substitution aborts the rest of this block, silently dropping the
    # abbreviation and the effort label.
    shopt -s nocasematch
    [[ $model == *opus*  && $effort == low ]] && warn='!'
    [[ $model == *haiku* && ( $effort == high || $effort == max ) ]] && warn='!'
    shopt -u nocasematch
    # "Sonnet 4.6" -> "So-4.6"
    if [[ $model == *' '* ]]; then
        model="${model:0:2}-${model#* }"
    fi
    [[ -n $label ]] && model="${model}-${label}${warn}"
fi

if [[ -n $ctx_pct && -n $ctx_size ]]; then
    ctx_used=$(( ctx_pct * ctx_size / 100000 ))
    ctx_total=$(( ctx_size / 1000 ))
    ctx_color=$reset
    # color by percentage (small contexts) or absolute used tokens (1M contexts)
    (( ctx_pct >= 75 || ctx_used >= 200 )) && ctx_color=$orange
    (( ctx_pct >= 88 || ctx_used >= 400 )) && ctx_color=$red
    seg="$(fmtk "$ctx_used")/$(fmtk "$ctx_total")"
    [[ -n $model ]] && seg+=" $model"
    sep; printf '%s%s' "$ctx_color" "$seg"
elif [[ -n $model ]]; then
    sep; printf '%s%s' "$reset" "$model"
fi

# Rate limits
if [[ -n $rl5h || -n $rl7d ]]; then
    max_rl=${rl5h:-0}
    [[ -n $rl7d ]] && (( rl7d > max_rl )) && max_rl=$rl7d
    rl_color=''
    (( max_rl >= 75 )) && rl_color=$orange
    (( max_rl >= 88 )) && rl_color=$red
    limits="${rl_color}${rl5h:-?}/${rl7d:-?}%${gray}"
    if [[ -n $rl5h_reset ]]; then
        # EPOCHSECONDS is bash 5+; unset it evaluates to 0 and the countdown
        # becomes the raw epoch. Fall back to a fork only where it is missing.
        now=${EPOCHSECONDS:-$(date +%s)}
        (( diff = rl5h_reset - now ))
        (( diff > 0 )) && limits+=" ↺$(( diff / 60 ))m"
    fi
    sep; printf '%s%s' "$reset" "$limits"
fi

printf '%s\n' "$reset"
