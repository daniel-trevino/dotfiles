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

## End of Zinit's installer chunk

# Enable autocompletions
autoload -Uz compinit

# Only add completion paths that exist
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
[ -d /usr/local/share/zsh/site-functions ] && fpath=(/usr/local/share/zsh/site-functions $fpath)

typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi
zmodload -i zsh/complist

# Skip missing completion functions gracefully
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Save history so we get auto suggestions
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

# Options
setopt auto_cd # cd by typing directory name if it's not a command
setopt auto_list # automatically list choices on ambiguous completion
setopt auto_menu # automatically use menu completion
setopt always_to_end # move cursor to end if word had one match
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks # remove superfluous blanks from history items
setopt inc_append_history # save history entries as soon as they are entered
setopt share_history # share history between different instances
setopt correct_all # autocorrect commands
setopt interactive_comments # allow comments in interactive shells

# Improve autocompletion style
zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

# Plugins
# zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-completions
zinit light buonomo/yarn-completion
# Note: zsh-notify disabled - shows "unsupported environment" warning in some terminal configurations
# [[ -x "$(command -v terminal-notifier)" ]] && zinit light marzocchi/zsh-notify

plugins=(
  colored-man-pages
  git
  yarn
)

# Keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Theme
# zinit light denysdovhan/spaceship-prompt
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  node          #
  exec_time     # Execution time
  line_sep      # Line break
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

# Reload after loading plugins
source $ZSH/oh-my-zsh.sh

# Fixes permissions with the /usr folder
ZSH_DISABLE_COMPFIX=true

# Fixes global npm packages installation
export PATH=/usr/local/share/npm/bin:$PATH

# Eval to fix thefuck
eval $(thefuck --alias)

# Eval to add starship https://starship.rs/
eval "$(starship init zsh)"

# Added by serverless binary installer
export PATH="$HOME/.serverless/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ASDF
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . $HOME/.asdf/asdf.sh
  . $HOME/.asdf/completions/asdf.bash
  export PATH="$HOME/.asdf/shims:$PATH"

  # Function to automatically install tools based on .tool-versions
  asdf_auto_install() {
    if [ -f ".tool-versions" ]; then
      asdf install
    fi
  }

  # Hook the function to the shell prompt command
  autoload -U add-zsh-hook
  add-zsh-hook chpwd asdf_auto_install
  asdf_auto_install
fi

# bat
export BAT_THEME=Dracula

. "$HOME/.atuin/bin/env"

# Atuin
eval "$(atuin init zsh)"

# fzf key bindings for completion
eval "$(fzf --zsh)"

# Zoxide (better cd)
eval "$(zoxide init zsh)"
