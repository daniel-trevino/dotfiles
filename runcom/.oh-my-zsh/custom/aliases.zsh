# Shortcuts

alias reload="source ~/.zshrc"
alias _="sudo"
alias rr="rm -rf"
alias dl="z ~/Downloads"
alias dt="z ~/Desktop"
alias p="z ~/Projects"
alias dot="z ~/.dotfiles && code ."
alias cd="z"

# Development

alias g="git"
alias gcom="git checkout master"
alias gcomp="git checkout master && git pull origin master"
alias gcan="git commit --amend --no-edit"
alias gca="git commit --amend"
alias gbl="git branch --list --sort=-committerdate"
alias fk="fkill"
alias ss="serve"
alias k="kubectl"
alias c="code ."

# docker

alias lzd='lazydocker'
alias d="docker"
alias dp="docker image prune -a" ## Prune all images
alias ddc='docker rm $(docker ps -aq)' ## Deletes all containers
alias ddi='docker rmi $(docker images -q)' ## Deletes all images
alias ddia='docker rmi $(docker images -q --filter "dangling=true") -f ' ## Deletes all untagged images
alias dclean="dp && ddc && ddi && ddia" ## Cleans up docker

# yarn

alias y="yarn"
alias yd="yarn dev"
alias ya="yarn add"
alias yr="yarn remove"
alias yri="rm -r node_modules && yarn"
alias yc="yarn clean"
alias yu="yarn upgrade --latest"
alias yui="yarn upgrade-interactive --latest" # Upgrades on yarn workspaces
alias yb="yarn build"
alias yt="yarn test"

# pnpm

alias pna="pnpm add" # Add a package to the project
alias pnad="pnpm add --save-dev" # Add a package to the project as a development dependency
alias pnap="pnpm add --save-peer" # Add a package to the project as a peer dependency
alias pnau="pnpm audit" # Audit the project for vulnerabilities
alias pnb="pnpm run build" # Build the project
alias pnc="pnpm create" # Create a new project
alias pnd="pnpm run dev" # Run the project in development mode
alias pndoc="pnpm run doc" # Generate documentation for the project
alias pnga="pnpm add --global" # Add a package to the global store
alias pngls="pnpm list --global" # List packages in the global store
alias pngrm="pnpm remove --global" # Remove a package from the global store
alias pngu="pnpm update --global" # Update a package in the global store
alias pnh="pnpm help" # Show help for a command
alias pni="pnpm init" # Initialize a new project
alias pn="pnpm install" # Install the project's dependencies
alias pnln="pnpm run lint" # Lint the project
alias pnls="pnpm list" # List packages in the project
alias pnout="pnpm outdated"	# Check for outdated packages
alias pnp="pnpm" # Run a PNpm command
alias pnpub="pnpm publish" # Publish the project
alias pnrm="pnpm remove" # Remove a package from the project
alias pnrun="pnpm run" # Run a script in the project
alias pns="pnpm run serve" # Run the project in production mode
alias pnst="pnpm start" # Start the project
alias pnsv="pnpm server" # Start the project's development server
alias pnt="pnpm test" # Run the project's tests
alias pntc="pnpm test --coverage" # Run the project's tests with coverage
alias pnui="pnpm update --interactive" # Update packages interactively
alias pnuil="pnpm update --interactive --latest" # Update packages interactively to the latest version
alias pnun="pnpm uninstall" # Remove a package from the project
alias pnup="pnpm update" # Update packages in the project
alias pnwhy="pnpm why" # Show why a package is installed
alias pnx="pnpx" # Run a PNpx command

# bun
alias ba="bun add"
alias bad="bun add --development"
alias bd="bun dev"
alias bb="bun run build"
alias bui="bunx npm-check-updates --root --format group -i" # Update dependencies interactive

# Default options

alias rsync="rsync -vh"
alias json="json -c"
alias psgrep="psgrep -i"

# List declared aliases, functions, paths

alias aliases="alias | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths='echo -e ${PATH//:/\\n}'

# Directory listing/traversal
alias l="lsd -lAhF --group-dirs first"
alias ll="lsd -l --tree"

alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."
alias -- -="z -"                  # Go to previous dir with -
alias cd.='z $(readlink -f .)'    # Go to real dir (i.e. if current dir is linked)

# npm

alias ni="npm install"
alias nu="npm uninstall"
alias nup="npm update"
alias nri="rm -r node_modules && npm install"
alias ncd="npm-check -su"


# Network

alias ip="curl -s ipinfo.io | jq -r '.ip'"
alias localip="ipconfig getifaddr en0"
alias ipl="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"

# Request using GET, POST, etc. method

for METHOD in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  alias "$METHOD"="lwp-request -m '$METHOD'"
done
unset METHOD

# Miscellaneous

alias hosts="sudo $EDITOR /etc/hosts"
alias quit="exit"
alias week="date +%V"
alias speedtest="wget -O /dev/null http://speed.transip.nl/100mb.bin"
alias grip="grip -b"

# ----------------------------- MACOS ---------------------------------
# Copy pwd to clipboard

alias cpwd="pwd|tr -d '\n'|pbcopy"

# Shortcuts

alias gg="$DOTFILES_GIT_GUI"

alias cask="brew cask"

alias chrome="open -a ~/Applications/Google\ Chrome.app"
alias canary="open -a ~/Applications/Google\ Chrome\ Canary.app"
alias firefox="open -a ~/Applications/Firefox.app"

# Exclude macOS specific files in ZIP archives

alias zip="zip -x *.DS_Store -x *__MACOSX* -x *.AppleDouble*"

# Open iOS Simulator

alias ios="open /Applications/Xcode.app/Contents/Developer/Applications/iOS\ Simulator.app"

# Flush DNS

alias flushdns="dscacheutil -flushcache && killall -HUP mDNSResponder"

# Start screen saver

alias afk="open /System/Library/CoreServices/ScreenSaverEngine.app"

# Log off

alias logoff="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# Quick-Look preview files from the command line

alias ql="qlmanage -p &>/dev/null"

# Show/hide desktop icons

alias desktopshow="defaults write com.apple.finder CreateDesktop -bool true && killfinder"
alias desktophide="defaults write com.apple.finder CreateDesktop -bool false && killfinder"

# Recursively remove Apple meta files

alias cleanupds="find . -type f -name '*.DS_Store' -ls -delete"
alias cleanupad="find . -type d -name '.AppleD*' -ls -exec /bin/rm -r {} \;"

# Clean up LaunchServices to remove duplicates in the "Open With" menu

alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Empty trash on mounted volumes and main HDD, and clear system logs

alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Reload native apps

alias killfinder="killall Finder"
alias killdock="killall Dock"
alias killmenubar="killall SystemUIServer NotificationCenter"
alias killos="killfinder && killdock && killmenubar"

# Kill all the tabs in Chrome to free up memory

alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Show system information

alias displays="system_profiler SPDisplaysDataType"
alias cpu="sysctl -n machdep.cpu.brand_string"
alias ram="top -l 1 -s 0 | grep PhysMem"

alias pbtext="pbpaste | textutil -convert txt -stdin -stdout -encoding 30 | pbcopy"
alias pbspaces="pbpaste | expand | pbcopy"
alias cpf="pbcopy < " # Copy from file

# Helps to handle multiple ssh keys on github and cloning repos
gclone() {
  SSH_COMMAND="ssh-add ~/.ssh/${1}; git clone ${2}"
  ssh-agent bash -c "${SSH_COMMAND}"
  echo "$1" "$2"
}

# Shows the aliases that start with the given string
# Usage: al <string>
function al {
  alias | sed 's/alias //g' | sed 's/=.*//' | grep "^$1"
}



# Possibility to load local scripts for the machine who needs it and that should not be commited to the repo
DIR="$HOME/.dotfiles/runcom/local-scripts"
if [ "$(ls -A $DIR)" ]; then
  for i in $HOME/.dotfiles/runcom/local-scripts/*;
    do source $i
  done
fi
