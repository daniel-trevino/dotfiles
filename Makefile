SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := /opt/homebrew/bin:$(DOTFILES_DIR)/bin:$(PATH)
ATUIN_DIR := $(HOME)/.atuin
NVM_DIR := $(HOME)/.nvm
VIM_DIR := ~/.vim_runtime
CARGO_DIR := $(HOME)/.cargo
OH_MY_ZSH_DIR := ~/.oh-my-zsh
ZINIT_DIR := ~/.local/share/zinit/zinit.git
export XDG_CONFIG_HOME := $(HOME)/.config

# Brew command that works whether brew is in PATH or freshly installed
BREW = $$(command -v brew 2>/dev/null || echo /opt/homebrew/bin/brew)
STOW = $$(command -v stow 2>/dev/null || echo /opt/homebrew/bin/stow)

all: $(OS)

macos: sudo core-macos packages link-macos cleanup-shell atuin install-vim select-shell-terminal

linux: core-linux link-linux atuin install-vim

core-macos: brew bash git npm ruby

core-linux:
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -f

stow-macos: brew
	is-executable stow || $(BREW) install stow

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
	$(STOW) -v -t $(HOME) runcom
	$(STOW) -v -t $(XDG_CONFIG_HOME) config
	@echo "Dotfiles symlinked successfully"


link-linux: stow-$(OS)
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
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
		echo "Installing Homebrew for Apple Silicon..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> $(HOME)/.zprofile; \
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
	$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile

cask-apps: brew
	$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile --verbose || true
	@if [ -d ~/Library/QuickLook ]; then \
		xattr -d -r com.apple.quarantine ~/Library/QuickLook 2>/dev/null || true; \
	fi

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
		sh sh.rustup.rs -y && \
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

# Cleanup shell completions and caches
# This target fixes common shell startup warnings by:
# - Removing broken completion symlinks from old Intel Mac paths
# - Generating cargo completions if Rust is installed
# - Clearing stale completion caches
cleanup-shell:
	@echo "Cleaning up shell completions and caches..."
	@# Remove broken symlinks from old Intel Mac completion directory
	@if [ -d /usr/local/share/zsh/site-functions ]; then \
		find /usr/local/share/zsh/site-functions -type l ! -exec test -e {} \; -delete 2>/dev/null || true; \
	fi
	@# Generate cargo completions if cargo is installed
	@if command -v rustup >/dev/null 2>&1; then \
		mkdir -p /opt/homebrew/share/zsh/site-functions; \
		rustup completions zsh cargo > /opt/homebrew/share/zsh/site-functions/_cargo 2>/dev/null || true; \
	fi
	@# Clear completion cache to force regeneration
	@rm -f $(HOME)/.zcompdump* 2>/dev/null || true
	@echo "Shell cleanup completed"

# Reload shell configuration (useful after making changes)
reload-shell:
	@echo "Reloading shell configuration..."
	@zsh -c "source ~/.zprofile && source ~/.zshrc" && echo "✅ Shell reloaded successfully"
