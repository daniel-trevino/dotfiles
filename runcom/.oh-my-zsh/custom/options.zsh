# Shell Options and Completion Settings

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

# Options
setopt auto_cd                  # cd by typing directory name if it's not a command
setopt auto_list                # automatically list choices on ambiguous completion
setopt auto_menu                # automatically use menu completion
setopt always_to_end            # move cursor to end if word had one match
setopt hist_ignore_all_dups     # remove older duplicate entries from history
setopt hist_reduce_blanks       # remove superfluous blanks from history items
setopt inc_append_history       # save history entries as soon as they are entered
setopt share_history            # share history between different instances
setopt correct_all              # autocorrect commands
setopt interactive_comments     # allow comments in interactive shells

# Completion styling
zstyle ':completion:*' menu select                                    # select completions with arrow keys
zstyle ':completion:*' group-name ''                                  # group results by category
zstyle ':completion:::::' completer _expand _complete _ignored _approximate  # enable approximate matches
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'    # skip missing completion functions gracefully
