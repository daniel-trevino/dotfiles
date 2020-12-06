# Shortcuts

alias reload="source ~/.zshrc"
alias _="sudo"
alias rr="rm -rf"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias p="cd ~/Projects"

# Development
alias g="git"
alias fk="fkill"
alias ss="serve"
alias k="kubectl"

# Default options

alias rsync="rsync -vh"
alias json="json -c"
alias psgrep="psgrep -i"

# List declared aliases, functions, paths

alias aliases="alias | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths='echo -e ${PATH//:/\\n}'

# Directory listing/traversal

alias l="ls -lahA $LS_COLORS $LS_TIMESTYLEISO $LS_GROUPDIRSFIRST"
alias ll="ls -lA $LS_COLORS"
alias lt="ls -lhAtr $LS_COLORS $LS_TIMESTYLEISO $LS_GROUPDIRSFIRST"
alias ld="ls -ld $LS_COLORS */"
alias lp="stat -c '%a %n' *"

unset LS_COLORS LS_TIMESTYLEISO LS_GROUPDIRSFIRST

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"                  # Go to previous dir with -
alias cd.='cd $(readlink -f .)'    # Go to real dir (i.e. if current dir is linked)

# npm

alias ni="npm install"
alias nu="npm uninstall"
alias nup="npm update"
alias nri="rm -r node_modules && npm install"
alias ncd="npm-check -su"

# yarn

alias ya="yarn add"
alias yr="yarn remove"
alias yri="rm -r node_modules && yarn"

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
