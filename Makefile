.PHONY: install brew_dump brew_install brew_restore

# Run dotbot install script
# todo: add support for other OS
install:
	./install

# Save snapshot of all Homebrew packages to macos/brewfile
brew_dump:
	brew bundle dump --brews -f --file=config/os/macos/brewfile
	brew bundle dump --casks -f --file=config/os/macos/brewfile.cask
	brew bundle dump --mas -f --file=config/os/macos/brewfile.mas
	# brew bundle --force cleanup --file=config/os/macos/brewfile

# Restore Homebrew packages
brew_restore:
	brew update
	brew upgrade
	brew install mas
	brew bundle install --file=config/os/macos/brewfile
	brew bundle install --file=config/os/macos/brewfile.cask
	brew bundle install --file=config/os/macos/brewfile.mas
	brew cleanup

brew_install:
	/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
