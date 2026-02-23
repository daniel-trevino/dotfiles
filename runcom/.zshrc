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

### End of Zinit's installer chunk

# Completion paths (compinit is handled by Oh My Zsh)
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
[ -d /usr/local/share/zsh/site-functions ] && fpath=(/usr/local/share/zsh/site-functions $fpath)
zmodload -i zsh/complist

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

# thefuck - command correction (cached to avoid running Python on every startup)
if command -v thefuck >/dev/null 2>&1; then
  _thefuck_cache="${XDG_CACHE_HOME:-$HOME/.cache}/thefuck_alias.zsh"
  if [[ ! -f "$_thefuck_cache" || "$(command -v thefuck)" -nt "$_thefuck_cache" ]]; then
    mkdir -p "${_thefuck_cache:h}"
    thefuck --alias > "$_thefuck_cache"
  fi
  source "$_thefuck_cache"
  unset _thefuck_cache
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
