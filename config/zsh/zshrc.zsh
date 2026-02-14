#!/bin/bash

# zsh config
zstyle ':omz:update' mode disabled

# Get zinit
if [[ -f ~/.zinit/zinit.zsh ]]; then
  source ~/.zinit/zinit.zsh
else
  echo "zinit is not installed at ~/.zinit" >&2
fi

# asdf
if [[ -f /opt/asdf/asdf.sh ]]; then
  . /opt/asdf/asdf.sh
fi

export PATH="$HOME/.local/bin:$PATH"

export ZSH_CONFIG_HOME="$HOME/.config/zsh"
export GPG_TTY=$TTY # https://unix.stackexchange.com/a/608921

# Initialize completion system early so plugin scripts can use `compdef`.
autoload -Uz compinit
_zsh_compdump_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "${_zsh_compdump_file:h}"
compinit -d "${_zsh_compdump_file}"

if typeset -f zinit >/dev/null 2>&1; then
  # Plugins
  zinit snippet OMZP::git
  zinit snippet OMZP::github
  zinit snippet OMZP::sudo
  zinit snippet OMZP::command-not-found
  zinit snippet OMZP::docker
  zinit snippet OMZP::docker-compose
  zinit snippet OMZP::genpass

  zinit light agkozak/zsh-z

  zinit snippet OMZP::asdf

  if [[ -f ~/.oh-my-zsh/plugins/macos/macos.plugin.zsh ]]; then
    source ~/.oh-my-zsh/plugins/macos/macos.plugin.zsh
  fi

  # These 2 must be in this order
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-history-substring-search

  zinit light zsh-users/zsh-autosuggestions

  # Warn you when you run a command that you've got an alias for
  zinit light djui/alias-tips

  # AI assist plugin
  zinit light monlor/zsh-ai-assist

  # Completion-only repos
  zinit ice blockf
  zinit light zsh-users/zsh-completions
  zinit cdreplay -q
fi
unset _zsh_compdump_file

# History Options
setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify

# Share history across all your terminal windows
setopt share_history
# setopt noclobber

# set some more options
setopt pushd_ignore_dups
setopt pushd_silent

# Increase history size
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HIST_STAMPS="yyyy-mm-dd"

# Return time on long running processes
REPORTTIME=2
TIMEFMT="%U user %S system %P cpu %*Es total"

# Place to stash environment variables
if [[ -e ~/.secrets ]]; then source ~/.secrets; fi

# Load all path files
for f in $ZSH_CONFIG_HOME/path/*.path.sh; do source $f; done

# Load all init files
for f in $ZSH_CONFIG_HOME/init/*.init.sh; do source $f; done

# Load aliases
for f in $ZSH_CONFIG_HOME/aliases/*.aliases.sh; do source $f; done

# Load functions
for f in $ZSH_CONFIG_HOME/functions/*.functions.sh; do source $f; done

if type fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f'
fi

export FZF_DEFAULT_OPTS='--reverse --bind 'ctrl-l:cancel''
export FZF_TMUX_HEIGHT=80%
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export BAT_THEME='GitHub'
export AWS_PAGER='bat -p'

# default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

eval "$(starship init zsh)"

# load user zshrc
[ -f ${HOME}/.zshrc.user ] && source ${HOME}/.zshrc.user
