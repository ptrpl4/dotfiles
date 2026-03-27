# Start profiling and timing
if [[ -n $PROFILE_STARTUP ]]; then
  zmodload zsh/zprof
fi

# Start time measurement with millisecond precision
shell_start_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000')

# Load colors func.
autoload -Uz colors && colors

# Enable vars and commands within prompt
setopt PROMPT_SUBST

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY      # write to file immediately
setopt HIST_IGNORE_DUPS        # skip consecutive dupes
setopt HIST_IGNORE_SPACE       # leading space = not saved
setopt HIST_EXPIRE_DUPS_FIRST  # drop dupes first when trimming
setopt EXTENDED_HISTORY        # save timestamps

# Shell behavior
setopt CORRECT                 # suggest fix for typos
setopt INTERACTIVE_COMMENTS    # allow # comments in terminal

# Load dotfiles directly (traditional approach)
# This is the original loading pattern, which loads files immediately
for file in ~/.{zprompt,aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Calculate and display the startup time (styled to match prompt)
if [[ -o interactive ]]; then
  shell_end_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000')
  shell_load_time=$((shell_end_time - shell_start_time))

  # Colors matching prompt theme
  gray=$(tput setaf 8)
  reset=$(tput sgr0)

  # Display styled message (matches ┌─ opening style)
  echo "${gray}└──[${reset}shell loaded in ${shell_load_time}ms${gray}]${reset}"
fi

# End profiling if enabled
if [[ -n $PROFILE_STARTUP ]]; then
  zprof
fi
