SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
ATUIN_DIR := $(HOME)/.atuin
NVM_DIR := $(HOME)/.nvm
VIM_DIR := ~/.vim_runtime
CARGO_DIR := $(HOME)/.cargo
OH_MY_ZSH_DIR := ~/.oh-my-zsh
ZINIT_DIR := ~/.local/share/zinit/zinit.git
export XDG_CONFIG_HOME := $(HOME)/.config

all: $(OS)

macos: sudo core-macos packages link-macos atuin install-vim select-shell-terminal

linux: core-linux link-linux atuin install-vim

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

packages: brew-packages cask-apps node-packages oh-my-zsh zinit cargo-rust

link-macos: stow-$(OS)
	for FILE in $(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -v -t $(HOME) runcom
	stow -v -t $(XDG_CONFIG_HOME) config


link-linux: stow-$(OS)
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -v -t $(HOME) runcom
	stow -v -t $(XDG_CONFIG_HOME) config

unlink: stow-$(OS)
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

install-vim:
	if ! [ -d $(VIM_DIR) ]; then \
		git clone --depth=1 https://github.com/amix/vimrc.git $(VIM_DIR) && \
		sh ~/.vim_runtime/install_awesome_vimrc.sh && \
		echo ":set number" >> ~/.vimrc && \
    	echo ":set mouse=nicr" >> ~/.vimrc; \
	fi

brew:
	@if ! is-executable brew; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		ARCH=$$(uname -m); \
		if [ "$$ARCH" = "arm64" ]; then \
			echo "Detected Apple Silicon, setting up PATH for /opt/homebrew"; \
			echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> $(HOME)/.zprofile; \
		else \
			echo "Detected Intel Mac, setting up PATH for /usr/local"; \
			echo 'eval "$$(/usr/local/bin/brew shellenv)"' >> $(HOME)/.zprofile; \
		fi; \
	fi

bash: SHELLS=/private/etc/shells
bash: brew
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" = "arm64" ]; then \
		BASH=/opt/homebrew/bin/bash; \
	else \
		BASH=/usr/local/bin/bash; \
	fi; \
	if ! grep -q $$BASH $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		sudo append $$BASH $(SHELLS); \
		if [ -z "$(GITHUB_ACTION)" ]; then \
			chsh -s $$BASH; \
		else \
			sudo chsh -s $$BASH; \
		fi; \
	fi

git: brew
	brew install git git-extras
	$(DOTFILES_DIR)/bin/setup-git-config

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

ruby: brew
	brew install ruby

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile --verbose || true
	xattr -d -r com.apple.quarantine ~/Library/QuickLook

node-packages: npm
	. $(NVM_DIR)/nvm.sh; npm install -g $(shell cat install/npmfile)

oh-my-zsh:
	if ! [ -d $(OH_MY_ZSH_DIR) ]; then \
		curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -o install-oh-my-zsh.sh && \
		sh install-oh-my-zsh.sh --unattended && \
		rm install-oh-my-zsh.sh; \
	fi

atuin:
	if ! [ -d $(ATUIN_DIR) ]; then \
		curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; \
	fi

# Cargo (Rust) package manager
cargo-rust:
	if ! [ -d $(CARGO_DIR) ]; then \
		curl -fsSL https://sh.rustup.rs -o sh.rustup.rs && \
		sh sh.rustup.rs --unattended && \
		rm sh.rustup.rs; \
	fi

# Terminal plugin package manager
zinit:
	if ! [ -d $(ZINIT_DIR) ]; then \
		curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh -o install-zinit.sh && \
		sh install-zinit.sh --unattended && \
		rm install-zinit.sh; \
	fi

select-shell-terminal:
  # Change default shell from /bin/bash to zsh
	chsh -s /bin/zsh
