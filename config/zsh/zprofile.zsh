if [ -d "/usr/local/Homebrew" ]; then
  BREW_HOME=/usr/local/Homebrew
elif [ -d "/opt/homebrew" ]; then
  BREW_HOME=/opt/homebrew
fi
if [ -n "${BREW_HOME}" ]; then
  eval "$(${BREW_HOME}/bin/brew shellenv)"
  # export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_AUTO_UPDATE_SECS=86400
fi

# Added by OrbStack: command-line tools and integration
if [ -f ~/.orbstack/shell/init.zsh ]; then
  source ~/.orbstack/shell/init.zsh 2>/dev/null || :
fi

# asdf
export ASDF_DIR="$HOME/.asdf"
export ASDF_DATA_DIR="$ASDF_DIR"

export PATH="$ASDF_DIR/shims:$HOME/.local/bin:$PATH"