if [ -d "/usr/local/Homebrew" ]; then
  BREW_HOME=/usr/local/Homebrew
elif [ -d "/opt/homebrew" ]; then
  BREW_HOME=/opt/homebrew
fi
if [ -n "${BREW_HOME}" ]; then
  eval "$(${BREW_HOME}/bin/brew shellenv)"
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
fi
