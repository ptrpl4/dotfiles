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

# Commented out optimized version:
# The version below uses lazy loading to improve startup time
# To use this version, comment out the for loop above and uncomment this section
#
# load_file() {
#   [ -r "$1" ] && [ -f "$1" ] && source "$1"
# }
#
# # Core configuration - load immediately
# load_file ~/.zprompt  # Prompt is needed right away
#
# # Lazy load functions - only when first used
# lazy_load() {
#   local cmd="$1"
#   local file="$2"
#
#   eval "$cmd() { unfunction $cmd; load_file $file; $cmd \$@ }"
# }
#
# # Load aliases and private settings only when the shell becomes interactive
# if [[ -o interactive ]]; then
#   load_file ~/.aliases
#   load_file ~/.private
# fi

# End profiling if enabled
if [[ -n $PROFILE_STARTUP ]]; then
  zprof
fi
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/xsolla.user/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
