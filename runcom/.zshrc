### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Enable autocompletions
autoload -Uz compinit

# Only add completion paths that exist
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
[ -d /usr/local/share/zsh/site-functions ] && fpath=(/usr/local/share/zsh/site-functions $fpath)

# Guard against multiple compinit calls during reload
if [[ -z "$_COMPINIT_DONE" ]]; then
  typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
  if [ $(date +'%j') != $updated_at ]; then
    compinit -i
  else
    compinit -C -i
  fi
  zmodload -i zsh/complist
  _COMPINIT_DONE=1
fi

# Zinit plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-completions
# Note: yarn completion provided by oh-my-zsh yarn plugin below

# Oh My Zsh plugins
plugins=(
  colored-man-pages
  git
  yarn
)

# Keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Fixes permissions with the /usr folder - MUST be before oh-my-zsh.sh
ZSH_DISABLE_COMPFIX=true

# Load Oh My Zsh (sources custom/*.zsh: aliases, asdf, nvm, options, path)
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Tool Initializations - MUST be after oh-my-zsh loads
# =============================================================================

# bat theme
export BAT_THEME=Dracula

# Zoxide (better cd) - creates 'z' function used by aliases
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# thefuck - command correction
if command -v thefuck >/dev/null 2>&1; then
  eval $(thefuck --alias)
fi

# Starship prompt
eval "$(starship init zsh)"

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
