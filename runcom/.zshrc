# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Enable autocompletions
autoload -Uz compinit
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi
zmodload -i zsh/complist
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
# Load antibody plugin manager
source <(antibody init)
# Plugins
antibody bundle zdharma/fast-syntax-highlighting
antibody bundle zsh-users/zsh-autosuggestions
antibody bundle zsh-users/zsh-history-substring-search
antibody bundle zsh-users/zsh-completions
antibody bundle buonomo/yarn-completion
# antigen bundle marzocchi/zsh-notify
# Keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# Theme
antibody bundle denysdovhan/spaceship-prompt
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  node          #
  exec_time     # Execution time
  line_sep      # Line break
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

# place this after nvm initialization!
autoload -U add-zsh-hook

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
