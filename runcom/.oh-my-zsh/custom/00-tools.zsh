# Tool Initializations

# bat theme
export BAT_THEME=Dracula

# thefuck - command correction
eval $(thefuck --alias)

# Direnv - directory-specific environment variables
eval "$(direnv hook zsh)"

# Atuin - shell history sync
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# fzf - fuzzy finder key bindings
eval "$(fzf --zsh)"

# Zoxide (better cd) - only initialize in interactive shells
if [[ -o interactive ]]; then
  eval "$(zoxide init zsh)"
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Safe-chain
source ~/.safe-chain/scripts/init-posix.sh

# Warp terminal
if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

# Anthropic model preference
export ANTHROPIC_MODEL="claude-opus-4-5-20251101"
