## Dotfiles

**Check all the files before you install.It may break your configuration of your computer.**

## Features

* 📦 Dotbot: Effortless Configuration Management Across Devices
* 🗂️ All terminal configurations are managed in one Git repository.
* 🧰 Favorite tools and applications are tracked and installed with a single command.
* 🔄 Synchronized configurations ensure a consistent experience on any machine.
* 🚀 One-click setup for quickly initializing a new computer.

## Installation

### Mac

```bash
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive
cd ~/.dotfiles
# install brew if not installed
make brew
# install git if not installed
xcode-select --install
# install dotfiles
make install
# install asdf packager including python, nodejs, golang ...
make install_all
# mackup backup and restore application config from icloud
make backup
```

### Linux

```bash
# install sudo git make 
sudo apt-get install -y sudo git make
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive
cd ~/.dotfiles
# install dotfiles
make install
# install asdf packager including python, nodejs, golang ...
make install_all
```

### Custom config

* ~/.zshrc.user (frps and openai config)
* ~/.gitconfig.user (Set up your git user)

## Inspired By

- https://github.com/denolfe/dotfiles
- https://github.com/craftzdog/dotfiles-public
- https://github.com/fisenkodv/dotfiles

## License

MIT
