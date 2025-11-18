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
	brew bundle dump --brews -f --file=package/brew/minimal.brew
	brew bundle dump --casks -f --file=package/brew/desktop.cask
	brew bundle dump --mas -f --file=package/brew/desktop.mas


backup:
	mackup restore
	mackup backup

# Docker testing targets
.PHONY: test test-fedora test-rocky test-centos test-ubuntu test-alpine test-all test-clean

# Test all distributions with minimal mode
test:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh

# Test specific distributions
test-fedora:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d fedora -m "minimal devops"

test-rocky:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d rockylinux -m "minimal devops"

test-centos:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d centos-stream -m minimal

test-ubuntu:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d ubuntu -m minimal

test-alpine:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d alpine -m minimal

# Test all distributions and all modes
test-all:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d "fedora rockylinux centos-stream ubuntu alpine" -m "minimal devops development"

# Clean up test containers and images
test-clean:
	@cd tests/docker && docker-compose down --rmi all --volumes --remove-orphans

# Quick test for a specific distro and mode
test-quick:
	@chmod +x tests/docker/test-dotfiles.sh
	@tests/docker/test-dotfiles.sh -d fedora -m minimal -c

