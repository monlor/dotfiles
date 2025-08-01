#!/bin/bash

# dotfiles aliases
alias .f='cd ~/.config/zsh && cd -P ../..'
alias .fu='.f && git submodule update --init --recursive'
alias .fe='.f && vim .'
alias .fr='source ~/.zshrc; echo ".zshrc reloaded"'
alias .fgen='zgen reset;source ~/.zshrc'

if type systemctl >/dev/null 2>&1; then
  alias senable='sudo systemctl enable'
  alias srestart='sudo systemctl restart'
  alias sstatus='sudo systemctl status'
  alias sstop='sudo systemctl stop'
  alias sstart='sudo systemctl start'
fi

alias rm='trash'

# Easier navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias ~='cd ~/'

# macOS directories
alias 'dl'='cd ~/Downloads'
alias 'dt'='cd ~/Desktop'
alias 'p'='cd ~/Projects'

h() {
  if type fzf >/dev/null 2>&1; then
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac --height "50%" | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
  else
    history | grep -i "$1"
  fi
}

# Detect the platform (similar to $OSTYPE)
OS=$(uname)
case $OS in
'Linux')
  alias sagi='sudo apt-get install'
  alias sai='sudo apt install'
  alias sagu='sudo apt-get update'
  alias saar='sudo add-apt-repository'
  alias sagr='sudo apt-get remove'
  alias pbcopy='xclip -selection c'
  alias pbpaste='xclip -selection clipboard -o'
  alias traceroute='nexttrace'
  ;;
'Darwin') 
  alias traceroute='nexttrace'
  ;;
*) ;;
esac

# Other bash stuff
alias t="touch"

if type bat >/dev/null 2>&1; then
  alias cat="bat"
fi

if type eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza --long --header --git --group --all --icons'
  alias tr1='eza --long --header --git --group --all --tree --level=1 --icons'
  alias tr2='eza --long --header --git --group --all --tree --level=2 --icons'
  alias tr3='eza --long --header --git --group --all --tree --level=3 --icons'
else
  alias ls='ls --color=auto -p'
  alias ll='ls -la'
  alias tr1='tree -L 1 -C'
  alias tr2='tree -L 2 -C'
  alias tr3='tree -L 3 -C'
fi

alias to_lower="tr '[:upper:]' '[:lower:]'"
alias to_upper="tr '[:lower:]' '[:upper:]'"

alias cp="cp -i"
alias upxx="upx --lzma --ultra-brute"

# for code-server
if [ "${LOGNAME}" = "coder" ]; then
  alias pbcopy="code-server --stdin-to-clipboard"
fi

alias dri="docker run -it --rm --entrypoint=sh"
