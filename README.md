![cover](./assets/screenshot.png)

# Dotfiles

[![Actions Status](https://github.com/monlor/dotfiles/workflows/Dotfiles%20Install/badge.svg)](https://github.com/monlor/dotfiles/actions)

**Warning**: Don’t blindly use my settings unless you know what that entails. Use at your own risk!

* The environment with brew and pacman is recognized as a local development environment, and a full set of software packages will be installed.
* The presence of apt and yum is recognized as a server environment, and only the basic terminal environment is configured.

## Shell setup (macOS)

- [Dotbot](https://github.com/anishathalye/dotbot) - a tool that bootstraps dotfiles
- [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) - framework for managing `zsh` configuration
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - theme
  - [Meslo Nerd Font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) Meslo Nerd Font patched for Powerlevel10k

## Installation

### Required

#### Mac

* brew

需要安装brew并添加brew环境变量，保证brew命令可用

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

* git 

```bash
xcode-select --install
```

#### Linux

* sudo
* git

### Install

```bash
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive
cd ~/.dotfiles
make install
```

install asdf

```
make install_all
```

install brew cask

```
make brew_restore
```

### Custom config

* ~/.zshrc.user
* ~/.gitconfig.user (Set up your git user)

### App Backup and Restore

restore application config from iCloud

```
make restore
```

backup application config to iCloud

```
make backup
```

## Inspired By

- https://github.com/denolfe/dotfiles
- https://github.com/craftzdog/dotfiles-public
- https://github.com/fisenkodv/dotfiles

## License

MIT
