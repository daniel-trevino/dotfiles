# CLAUDE.md - Repository Context for Claude Code

## Overview

This is a personal dotfiles repository for macOS and Ubuntu setup. It automates the installation of development tools, shell configuration, and system preferences using a Makefile-based approach with GNU Stow for symlink management.

**Author:** Daniel Treviño Bergman
**Repository:** https://github.com/daniel-trevino/dotfiles

## Repository Structure

```
.
├── Makefile           # Main installation orchestrator
├── bin/               # Custom utility scripts (added to PATH)
├── config/            # Application configs (symlinked to ~/.config/)
│   ├── git/           # Git configuration and ignore patterns
│   ├── prettier/      # Prettier configuration
│   └── thefuck/       # thefuck settings
├── install/           # Package lists
│   ├── Brewfile       # Homebrew formulae
│   ├── Caskfile       # Homebrew casks (GUI apps)
│   └── npmfile        # Global npm packages
├── macos/             # macOS-specific scripts
│   ├── defaults.sh    # System preferences (Finder, Dock, etc.)
│   └── dock.sh        # Dock application layout
└── runcom/            # Shell configuration (symlinked to ~/)
    ├── .zshrc         # Zsh configuration
    ├── .zprofile      # Zsh profile (Homebrew shellenv)
    ├── .bash_profile  # Bash configuration
    ├── .config/       # XDG config (starship.toml)
    └── .oh-my-zsh/    # Oh My Zsh customizations
        └── custom/
            └── aliases.zsh  # Custom shell aliases
```

## Key Commands

### Installation
```bash
make                # Full installation (detects macOS vs Linux)
make macos          # macOS-specific installation
make linux          # Linux-specific installation
```

### Quick Package Updates
```bash
make brewfile       # Install/update Homebrew packages
make caskfile       # Install/update cask apps
make npmfile        # Install/update npm packages
```

### Utility Commands
```bash
dotfiles help       # Show available commands
dotfiles dock       # Apply Dock settings
dotfiles macos      # Apply macOS system defaults
dotfiles update     # Update all package managers
dotfiles clean      # Clean up caches
```

### Symlink Management
```bash
make link-macos     # Create symlinks using stow
make unlink         # Remove symlinks and restore backups
```

## Shell Environment

- **Primary Shell:** Zsh with Oh My Zsh
- **Plugin Manager:** Zinit (for Zsh plugins)
- **Prompt:** Starship (customized in `runcom/.config/starship.toml`)
- **Key Tools:**
  - `zoxide` - Smart directory navigation (aliased as `cd`)
  - `fzf` - Fuzzy finder
  - `atuin` - Shell history sync
  - `thefuck` - Command correction
  - `bat` - Better cat (Dracula theme)
  - `lsd` - Better ls

## Development Workflow

### Commits
Uses Conventional Commits enforced by commitlint and Husky:
```bash
feat: add new feature
fix: fix a bug
chore: maintenance tasks
```

### Releases
Automated via semantic-release on push to master.

### CI
GitHub Actions workflow runs on every push/PR:
1. Tests installation on Ubuntu
2. Verifies runcom setup
3. Releases new version if commits warrant it

## Important Aliases

### Navigation
- `cd` → `zoxide` (smart directory jumping)
- `l` → `lsd -lAhF --group-dirs first`
- `..`, `...`, `....` → navigate up directories

### Git
- `g` → git
- `gcom` → `git checkout master`
- `gbl` → `git branch --list --sort=-committerdate`

### Package Managers
- `pn` → `pnpm install`
- `pnd` → `pnpm run dev`
- `pnb` → `pnpm run build`
- `y`, `yd`, `yb` → yarn shortcuts
- `ba`, `bd`, `bb` → bun shortcuts

### Docker
- `lzd` → lazydocker
- `dclean` → full docker cleanup

## Git Configuration

- **SSH Key:** `~/.ssh/daniel-trevino-git`
- **Diff Tool:** Kaleidoscope with diff-so-fancy
- **Default Branch:** main
- **Pull Strategy:** rebase

Notable aliases in `config/git/config`:
- `l` → pretty log graph
- `pr` → fetch and checkout PR by number
- `amend` → commit --amend --reuse-message=HEAD

## Testing

```bash
make test           # Run bats tests
dotfiles test       # Alternative via dotfiles command
```

## Adding New Packages

1. **Homebrew formulae:** Add to `install/Brewfile`
2. **GUI apps (casks):** Add to `install/Caskfile`
3. **npm packages:** Add to `install/npmfile`

Then run the corresponding make target (`brewfile`, `caskfile`, `npmfile`).

## Customization

- **Machine-local scripts:** Add to `runcom/local-scripts/` (gitignored)
- **Additional dotfiles:** Use `~/.extra/runcom/*.sh` (sourced automatically)

## Notes

- Installation backs up existing dotfiles to `*.bak` before symlinking
- macOS defaults script sets computer name to "DanielTrevino"
- Timezone defaults to Europe/Amsterdam
- Node.js managed via NVM (LTS version)
- asdf used for version management with auto-install on directory change
