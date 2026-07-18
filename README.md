[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

# dotfiles

My dotfiles for Mac and Ubuntu setup.

## Highlights

- Minimal efforts to install everything, using a [Makefile](./Makefile)
- Mostly based around Homebrew, Caskroom and Node.js, latest Bash + GNU Utils
- Fast and colored prompt
- Updated macOS defaults (including Caps Lock → Control remap for tmux)
- Well-organized and easy to customize
- The installation and runcom setup is
  [tested weekly on real Ubuntu and macOS machines](https://github.com/daniel-trevino/dotfiles/actions) using
  [a GitHub Action](./.github/workflows/ci.yml)

## Packages Overview

- [Homebrew](https://brew.sh) (packages: [Brewfile](./install/Brewfile))
- [homebrew-cask](https://github.com/Homebrew/homebrew-cask) (packages: [Caskfile](./install/Caskfile))
- [Node.js + npm LTS](https://nodejs.org/en/download/) (packages: [npmfile](./install/npmfile))
- Latest Git, Bash 4, Python 3, GNU coreutils, curl, Ruby
- [Mackup](https://github.com/lra/mackup) (sync application settings)
- `$EDITOR` (and Git editor) is [GNU nano](https://www.nano-editor.org)

## Installation

### macOS

On a sparkling fresh installation of macOS:

```bash
sudo softwareupdate -i -a
xcode-select --install
```

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS). Now there are two options:

1. Install this repo with `curl` available:

```bash
bash -c "`curl -fsSL https://raw.githubusercontent.com/daniel-trevino/dotfiles/master/remote-install.sh`"
```

This will clone or download, this repo to `~/.dotfiles` depending on the availability of `git`, `curl` or `wget`.

1. Alternatively, clone manually into the desired location:

```bash
git clone https://github.com/daniel-trevino/dotfiles.git ~/.dotfiles
```

Use the [Makefile](./Makefile) to install everything [listed above](#package-overview), and symlink [runcom](./runcom)
and [config](./config) (using [stow](https://www.gnu.org/software/stow/)):

```bash
cd ~/.dotfiles
make
```

### Linux (Ubuntu/Debian)

On a fresh Ubuntu installation, `git` and `make` are needed first:

```bash
sudo apt-get update && sudo apt-get install -y git make
```

Then clone and install:

```bash
git clone https://github.com/daniel-trevino/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make
```

This will install system packages via `apt`, set up [Homebrew for Linux](https://docs.brew.sh/Homebrew-on-Linux), install all Brewfile packages (macOS-only packages are skipped automatically), Node.js, Oh My Zsh, Zinit, Rust/Cargo, Atuin, Vim, and switch the default shell to Zsh.

> **Note:** GUI cask apps are not installed on Linux. A few Brewfile formulae (`dockutil`, `terminal-notifier`, `wifi-password`) are macOS-only and will be skipped.

### Installation Profiles

Running `make` will prompt you to choose between two profiles:

| | **Full** (default) | **Light** |
|---|---|---|
| Shell config (zsh, oh-my-zsh, zinit, starship) | Yes | Yes |
| Core CLI tools (~23 packages) | Yes | Yes |
| Dev runtimes (Node.js, Python, Go, Rust) | Yes | Yes |
| Claude Code | Yes | Yes |
| Cloud CLIs, databases, GUI apps, extras | Yes | No |

To skip the prompt, use the shortcut targets:

```bash
make light-macos   # Light profile on macOS
make light-linux   # Light profile on Linux
```

Or pass the `PROFILE` variable directly:

```bash
make macos PROFILE=light
make linux PROFILE=full   # (default)
```

The installation process in the Makefile is tested on every push and every week in this
[GitHub Action](https://github.com/daniel-trevino/dotfiles/actions).

## Quick Package Updates

After the initial installation, you can quickly install or update individual package lists without running the full setup:

```bash
make brewfile   # Install/update Homebrew packages from Brewfile
make caskfile   # Install/update cask apps from Caskfile
make npmfile    # Install/update npm packages from npmfile
```

This is useful when you've added new packages to the install files and want to apply just those changes.

## Post-Installation

1. Close that terminal that you are using and open a new one. Then you can run the following commands
2. Compile zinit via `zinit self-update`

- `dotfiles dock` (set [Dock items](./macos/dock.sh))
- `dotfiles macos` (set [macOS defaults](./macos/defaults.sh), including Caps Lock → Control remap for tmux)
- Mackup
  - Log in to Dropbox (and wait until synced)
  - `ln -s ~/.config/mackup/.mackup.cfg ~` (until [#632](https://github.com/lra/mackup/pull/632) is fixed)
  - `mackup restore`
- Remove Spotlight and add setup Alfred command
- Set Aerial screen saver. Open `System Preferences` -> `Desktop & Screen Saver` -> `Screen Saver`

## The `dotfiles` command

```bash
$ dotfiles help
Usage: dotfiles <command>

Commands:
    clean            Clean up caches (brew, npm, gem, rvm)
    dock             Apply macOS Dock settings
    edit             Open dotfiles in IDE (code) and Git GUI (stree)
    help             This help message
    macos            Apply macOS system defaults
    test             Run tests
    update           Update packages and pkg managers (OS, brew, npm, gem)
```

## Customize

You can put your custom settings, such as Git credentials in the `system/.custom` file which will be sourced from
`.bash_profile` automatically. This file is in `.gitignore`.

Alternatively, you can have an additional, personal dotfiles repo at `~/.extra`. The runcom `.bash_profile` sources all
`~/.extra/runcom/*.sh` files.

### Agent CLI secrets

`codex/.codex/config.toml` is the only Codex configuration source. `make
link-macos` and `make link-linux` symlink `~/.codex/config.toml` to that tracked
file, so changes made by Codex update the dotfiles source directly. Orca keeps
an app-managed runtime mirror under its own `$CODEX_HOME`; that generated file
is deliberately not symlinked because Orca rewrites it atomically when syncing
settings and managed hooks.

The `codex` and `claude` aliases load secrets from the local, Git-ignored
`agent-config/secrets/env.cache`. Create or update it explicitly:

```bash
agent-secrets refresh
```

When testing from a worktree before it has become the active dotfiles checkout,
invoke the utility by path instead:

```bash
./bin/agent-secrets refresh
```

It reads the template from that worktree but stores the ignored cache under the
active `$DOTFILES_DIR`, so the cache remains available after the worktree is
merged or removed.

The refresh command resolves the references in
`agent-config/secrets/env.1password` with the 1Password CLI. It is the only
operation that contacts 1Password, so normal agent launches do not require an
approval. Run it again whenever a secret rotates.

The cache is plaintext local state. Its directory is restricted to mode `0700`
and the cache to `0600`; full-disk encryption and the local user account provide
the remaining at-rest protection. The cache must contain single-line dotenv
values. It is written atomically, and a failed refresh leaves the previous cache
intact.

Useful commands:

```bash
agent-secrets status  # Show cache metadata without values
agent-secrets clear   # Remove the cached secrets
```

To add a secret, put a `NAME={{ op://vault/item/field }}` reference in the
tracked template and configure the relevant MCP server to read `NAME` from its
environment. A missing, invalid, unresolved, or overly permissive cache prevents
Codex and Claude from starting and directs you to refresh it. Requires
1Password's Developer setting for CLI integration.

## Additional Resources

- [Homebrew](https://brew.sh)
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask)
- [Bash prompt](https://wiki.archlinux.org/index.php/Color_Bash_Prompt)
- [Solarized Color Theme for GNU ls](https://github.com/seebi/dircolors-solarized)

## FAQ

- `* existing target is not owned by stow: .bash_profile`
  You might have done the `make` command without having this repository on `~/.dotfiles` location.
  To fix it you have to move this repository to `~/.dotfiles` and manually remove the symlinks for those files that have that error using `rm -f symlink_to_dir/`. Then run `make` again.

- `warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory`
  You might have spelled the locale wrong. Check how the format of the locale is supposed to be written.

- `How to add new mac software?`
  Add the name of it on `/install/Caskfile`. Look at the names at: [Homebrew Cask](https://formulae.brew.sh/cask/)

## Credits

Many thanks to the [dotfiles community](https://dotfiles.github.io).
Code structure and inspiration by: [webpro](https://github.com/webpro/dotfiles)
