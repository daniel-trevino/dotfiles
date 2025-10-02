[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

# dotfiles

My dotfiles for Mac and Ubuntu setup.

## Highlights

- Minimal efforts to install everything, using a [Makefile](./Makefile)
- Mostly based around Homebrew, Caskroom and Node.js, latest Bash + GNU Utils
- Fast and colored prompt
- Updated macOS defaults
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

The installation process in the Makefile is tested on every push and every week in this
[GitHub Action](https://github.com/daniel-trevino/dotfiles/actions).

## Post-Installation

1. Close that terminal that you are using and open a new one. Then you can run the following commands
2. Compile zinit via `zinit self-update`

- `dotfiles dock` (set [Dock items](./macos/dock.sh))
- `dotfiles macos` (set [macOS defaults](./macos/defaults.sh))
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
