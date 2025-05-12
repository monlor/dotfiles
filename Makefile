.PHONY: install install_all brew_dump brew_install backup

# 判断系统架构（通过 `uname -m` 检测）
SYS_ARCH := $(shell uname -m)

# 根据架构设置 Homebrew 安装路径
ifeq ($(SYS_ARCH), arm64)
    BREW_PREFIX := /opt/homebrew
else
    BREW_PREFIX := /usr/local
endif

# 定义 brew 命令路径
BREW := $(BREW_PREFIX)/bin/brew

# Run dotbot install script
# todo: add support for other OS
install:
	./install.sh

install_all:
	ASDF=true ./install.sh

brew_install: 
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@grep -q "$(BREW_PREFIX)/bin/brew" $(HOME)/.zprofile &> /dev/null || echo 'eval "$$($(BREW) shellenv)"' >> $(HOME)/.zprofile
	@eval "$$($(BREW) shellenv)"

# Save snapshot of all Homebrew packages to macos/brewfile
brew_dump:
	brew bundle dump --brews -f --file=package/brew/brewfile
	brew bundle dump --casks -f --file=package/brew/brewfile.cask
	brew bundle dump --mas -f --file=package/brew/brewfile.mas
	# brew bundle --force cleanup --file=config/os/macos/brewfile

# Restore Homebrew packages
brew:
	brew update
	brew upgrade
	brew install mas
	brew bundle install --file=package/brew/brewfile
	brew bundle install --file=package/brew/brewfile.cask
	brew bundle install --file=package/brew/brewfile.mas
	brew cleanup

backup:
	mackup restore
	mackup backup 

