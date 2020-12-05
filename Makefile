SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
VIM_DIR := ~/.vim_runtime
export XDG_CONFIG_HOME := $(HOME)/.config
export VSCODE_CONFIG_HOME := $(HOME)/Library/Application\ Support/Code/User
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test

all: $(OS)

macos: sudo core-macos packages link install-vim

linux: core-linux link install-vim

core-macos: brew bash git npm ruby

core-linux:
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -f

stow-macos: brew
	is-executable stow || brew install stow

stow-linux: core-linux
	is-executable stow || apt-get -y install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

packages: brew-packages cask-apps node-packages

# Make sure that a config folder doesn't contain files so the symlinks can be added without conflicts
define avoid_duplicate_files
    for FILE in $$(\ls -A $(1)); do if [ -f $(2)/$$FILE -a ! -h $(2)/$$FILE ]; then \
		  mv -v $(2)/$$FILE{,.bak}; fi; done
endef

# Make sure that a config folder doesn't contain files so the symlinks can be added without conflicts
define restore_bak_files
    for FILE in $$(\ls -A $(1)); do if [ -f $(2)/$$FILE.bak ]; then \
		  mv -v $(2)/$$FILE.bak $(2)/$${FILE%%.bak}; fi; done
endef

link: stow-$(OS)
	$(call avoid_duplicate_files,runcom,$(HOME))
	$(call avoid_duplicate_files,VSCode,$(VSCODE_CONFIG_HOME))
	mkdir -p $(XDG_CONFIG_HOME)
	stow -v -t $(HOME) runcom
	stow -v -t $(XDG_CONFIG_HOME) config
	stow -v -t $(VSCODE_CONFIG_HOME) VSCode

unlink: stow-$(OS)
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	stow --delete -t $(VSCODE_CONFIG_HOME) VSCode
	$(call restore_bak_files,runcom,$(HOME))
	$(call restore_bak_files,VSCode,$(VSCODE_CONFIG_HOME))

install-vim:
	if ! [ -d $(VIM_DIR)/.git ]; then git clone --depth=1 https://github.com/amix/vimrc.git $(VIM_DIR); fi
	sh ~/.vim_runtime/install_awesome_vimrc.sh
	echo ":set number" >> ~/.vimrc # Add :set number to the vim settings

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

bash: BASH=/usr/local/bin/bash
bash: SHELLS=/private/etc/shells
bash: brew
ifdef GITHUB_ACTION
	if ! grep -q $(BASH) $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		sudo append $(BASH) $(SHELLS) && \
		sudo chsh -s $(BASH); \
	fi
else
	if ! grep -q $(BASH) $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		sudo append $(BASH) $(SHELLS) && \
		chsh -s $(BASH); \
	fi
endif

git: brew
	brew install git git-extras

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

ruby: brew
	brew install ruby

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile --verbose || true
	defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
	for EXT in $$(cat install/Codefile); do code --install-extension $$EXT; done
	xattr -d -r com.apple.quarantine ~/Library/QuickLook

node-packages: npm
	. $(NVM_DIR)/nvm.sh; npm install -g $(shell cat install/npmfile)

test:
	. $(NVM_DIR)/nvm.sh; bats test
