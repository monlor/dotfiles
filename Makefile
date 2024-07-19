.PHONY: install install_all brew_dump brew_install backup

# Run dotbot install script
# todo: add support for other OS
install:
	./install.sh

install_all:
	ASDF=true ./install.sh

brew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Save snapshot of all Homebrew packages to macos/brewfile
brew_dump:
	brew bundle dump --brews -f --file=package/brew/brewfile
	brew bundle dump --casks -f --file=package/brew/brewfile.cask
	brew bundle dump --mas -f --file=package/brew/brewfile.mas
	# brew bundle --force cleanup --file=config/os/macos/brewfile

# Restore Homebrew packages
brew_install:
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

