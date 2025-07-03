.PHONY: install brew_dump brew_install backup

# Detect system architecture (via `uname -m`)
SYS_ARCH := $(shell uname -m)

# Set Homebrew prefix based on architecture
ifeq ($(SYS_ARCH), arm64)
    BREW_PREFIX := /opt/homebrew
else
    BREW_PREFIX := /usr/local
endif

# Define brew command path
BREW := $(BREW_PREFIX)/bin/brew

# Detect if running in CI
ifdef CI
    SKIP_CONFIRM := true
else
    SKIP_CONFIRM := false
endif

# Install dotfiles (interactive mode selection)
install:
	SKIP_CONFIRM=$(SKIP_CONFIRM) ./install.sh

brew_install: 
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@grep -q "$(BREW_PREFIX)/bin/brew" $(HOME)/.zprofile &> /dev/null || echo 'eval "$$($(BREW) shellenv)"' >> $(HOME)/.zprofile
	@eval "$$($(BREW) shellenv)"

# Save snapshot of all Homebrew packages
brew_dump:
	brew bundle dump --brews -f --file=package/brew/brewfile
	brew bundle dump --casks -f --file=package/brew/brewfile.cask
	brew bundle dump --mas -f --file=package/brew/brewfile.mas


backup:
	mackup restore
	mackup backup

