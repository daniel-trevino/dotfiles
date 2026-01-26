# Tool Initializations
# Note: This file is named 00-tools.zsh to load BEFORE aliases.zsh
# because aliases depend on tools like zoxide being initialized first.

# bat theme
export BAT_THEME=Dracula

# thefuck - command correction
if command -v thefuck >/dev/null 2>&1; then
  eval $(thefuck --alias)
fi

# Direnv - directory-specific environment variables
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Atuin - shell history sync
if [ -f "$HOME/.atuin/bin/env" ]; then
  . "$HOME/.atuin/bin/env"
fi
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

# fzf - fuzzy finder key bindings
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# Zoxide (better cd) - MUST be initialized before aliases.zsh loads
# This creates the 'z' function that aliases depend on
if command -v zoxide >/dev/null 2>&1 && [[ -o interactive ]]; then
  eval "$(zoxide init zsh)"
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Safe-chain (only if installed)
[ -f ~/.safe-chain/scripts/init-posix.sh ] && source ~/.safe-chain/scripts/init-posix.sh

# Warp terminal
if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

# Anthropic model preference
export ANTHROPIC_MODEL="claude-opus-4-5-20251101"
