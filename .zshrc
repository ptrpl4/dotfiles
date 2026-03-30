# Start profiling
if [[ -n $PROFILE_STARTUP ]]; then
  zmodload zsh/zprof
fi

autoload -Uz colors && colors
setopt PROMPT_SUBST

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${HOME}/.zsh_history"
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

# Shell behavior
setopt CORRECT
setopt INTERACTIVE_COMMENTS

for file in ~/.{zprompt,aliases,private}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

if [[ -n $PROFILE_STARTUP ]]; then
  zprof
fi
