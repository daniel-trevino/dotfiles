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

PROFILE ?= full

# Brew command that works whether brew is in PATH or freshly installed
BREW = $$(command -v brew 2>/dev/null || \
	([ -x /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew) || \
	([ -x /home/linuxbrew/.linuxbrew/bin/brew ] && echo /home/linuxbrew/.linuxbrew/bin/brew) || \
	([ -x $(HOME)/.linuxbrew/bin/brew ] && echo $(HOME)/.linuxbrew/bin/brew) || \
	echo /usr/local/bin/brew)
STOW = $$(command -v stow 2>/dev/null || echo stow)

ifdef GITHUB_ACTION
all: $(OS)
else
all:
	@printf "\nSelect installation profile:\n"
	@printf "  [1] Full  - all packages, GUI apps, cloud CLIs, databases\n"
	@printf "  [2] Light - core CLI tools, dev runtimes, shell config, Claude Code\n"
	@printf "\nChoice [1]: " && read choice; \
	if [ "$$choice" = "2" ]; then \
		$(MAKE) $(OS) PROFILE=light; \
	else \
		$(MAKE) $(OS) PROFILE=full; \
	fi
endif

ifeq ($(PROFILE),light)
macos: sudo core-macos packages-light-macos link-macos cleanup-shell atuin install-vim select-shell-terminal
linux: sudo core-linux brew packages-linux-light link-linux cleanup-shell atuin install-vim select-shell-linux
else
macos: sudo core-macos packages link-macos cleanup-shell atuin install-vim select-shell-terminal
linux: sudo core-linux brew packages-linux link-linux cleanup-shell atuin install-vim select-shell-linux
endif

light-macos:
	$(MAKE) macos PROFILE=light

light-linux:
	$(MAKE) linux PROFILE=light

core-macos: brew bash git npm ruby

core-linux:
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install -y build-essential curl file git zsh stow xclip

stow-macos: brew
	is-executable stow || $(BREW) install stow

stow-linux: core-linux
	is-executable stow || sudo apt-get -y install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

packages: brew-packages cask-apps node-packages oh-my-zsh zinit cargo-rust

packages-linux: brew-packages node-packages oh-my-zsh zinit cargo-rust

packages-light: brew-packages-light claude-code oh-my-zsh zinit cargo-rust

packages-light-macos: brew-packages-light cask-apps-light claude-code oh-my-zsh zinit cargo-rust

packages-linux-light: brew-packages-light claude-code oh-my-zsh zinit cargo-rust

link-macos: stow-$(OS)
	@echo "Backing up existing dotfiles..."
	@for FILE in .bash_profile .bashrc .inputrc .zprofile .zshenv .zshrc; do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			echo "Backing up $$FILE to $$FILE.bak"; \
			mv -v $(HOME)/$$FILE $(HOME)/$$FILE.bak; \
		fi; \
	done
	mkdir -p $(XDG_CONFIG_HOME)
	$(STOW) -v -t $(HOME) runcom
	$(STOW) -v -t $(XDG_CONFIG_HOME) config
	@echo "Dotfiles symlinked successfully"


link-linux: stow-$(OS)
	@echo "Backing up existing dotfiles..."
	@for FILE in .bash_profile .bashrc .inputrc .zprofile .zshenv .zshrc; do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			echo "Backing up $$FILE to $$FILE.bak"; \
			mv -v $(HOME)/$$FILE $(HOME)/$$FILE.bak; \
		fi; \
	done
	mkdir -p $(XDG_CONFIG_HOME)
	$(STOW) -v -t $(HOME) runcom
	$(STOW) -v -t $(XDG_CONFIG_HOME) config

unlink: stow-$(OS)
	$(STOW) --delete -t $(HOME) runcom
	$(STOW) --delete -t $(XDG_CONFIG_HOME) config
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
	@if [ "$(USER)" = "root" ]; then \
		echo "Error: Do not run 'sudo make'. Run 'make' instead."; \
		echo "The Makefile will prompt for sudo when needed."; \
		exit 1; \
	fi
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		if [ -x /opt/homebrew/bin/brew ]; then \
			eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then \
			eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		elif [ -x $(HOME)/.linuxbrew/bin/brew ]; then \
			eval "$$($(HOME)/.linuxbrew/bin/brew shellenv)"; \
		fi; \
	fi

bash: BASH=/opt/homebrew/bin/bash
bash: SHELLS=/private/etc/shells
bash: brew
	@if ! grep -q $(BASH) $(SHELLS); then \
		$(BREW) install bash bash-completion@2 pcre && \
		sudo append $(BASH) $(SHELLS); \
		if [ "$(USER)" = "root" ]; then \
			echo "Warning: Running as root, skipping shell change"; \
		elif [ -z "$(GITHUB_ACTION)" ]; then \
			chsh -s $(BASH); \
		else \
			sudo chsh -s $(BASH); \
		fi; \
	fi

git: brew
	$(BREW) install git git-extras

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

ruby: brew
	$(BREW) install ruby

brew-packages: brew
	$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

brew-packages-light: brew
	$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile.light || true

cask-apps: brew
	$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile --verbose || true
	@if [ -d ~/Library/QuickLook ]; then \
		xattr -d -r com.apple.quarantine ~/Library/QuickLook 2>/dev/null || true; \
	fi

cask-apps-light:
	@echo "Skipping cask apps (light profile)"

node-packages: npm
	. $(NVM_DIR)/nvm.sh; npm install -g $(shell cat install/npmfile)

claude-code: npm
	. $(NVM_DIR)/nvm.sh; npm install -g @anthropic-ai/claude-code

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
		sh sh.rustup.rs -y && \
		rm sh.rustup.rs; \
	fi

# Terminal plugin package manager
zinit:
	if ! [ -d $(ZINIT_DIR) ]; then \
		curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh -o install-zinit.sh && \
		bash install-zinit.sh --unattended && \
		rm install-zinit.sh; \
	fi

select-shell-terminal:
  # Change default shell from /bin/bash to zsh
	chsh -s /bin/zsh

select-shell-linux:
	@ZSH_PATH=$$(which zsh); \
	if ! grep -qxF "$$ZSH_PATH" /etc/shells; then \
		echo "$$ZSH_PATH" | sudo tee -a /etc/shells; \
	fi; \
	sudo chsh -s "$$ZSH_PATH" "$(USER)"

# Cleanup shell completions and caches
cleanup-shell:
	@echo "Cleaning up shell completions and caches..."
	@# Remove broken symlinks from old Intel Mac completion directory
	@if [ -d /usr/local/share/zsh/site-functions ]; then \
		find /usr/local/share/zsh/site-functions -type l ! -exec test -e {} \; -delete 2>/dev/null || true; \
	fi
	@# Generate cargo completions if cargo is installed
	@if command -v rustup >/dev/null 2>&1; then \
		BREW_PREFIX=$$(brew --prefix 2>/dev/null || echo ""); \
		if [ -n "$$BREW_PREFIX" ]; then \
			mkdir -p "$$BREW_PREFIX/share/zsh/site-functions"; \
			rustup completions zsh cargo > "$$BREW_PREFIX/share/zsh/site-functions/_cargo" 2>/dev/null || true; \
		fi; \
	fi
	@# Clear completion cache to force regeneration
	@rm -f $(HOME)/.zcompdump* 2>/dev/null || true
	@echo "Shell cleanup completed"

# Reload shell configuration (useful after making changes)
reload-shell:
	@echo "Reloading shell configuration..."
	@zsh -c "source ~/.zprofile && source ~/.zshrc" && echo "Shell reloaded successfully"

# Quick install shortcuts for individual package files
brewfile: brew-packages
caskfile: cask-apps
npmfile: node-packages
