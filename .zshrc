# Load colors func.
autoload -Uz colors && colors

# Enable vars and commands within prompt
setopt PROMPT_SUBST

# Load config files
for file in ~/.{zprompt,aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

# Unset used var
unset file;
