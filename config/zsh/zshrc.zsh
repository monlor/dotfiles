#!/bin/bash

# zsh config
export ZSH_CONFIG_HOME="$HOME/.config/zsh"
export GPG_TTY=$TTY # https://unix.stackexchange.com/a/608921

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

if typeset -f zinit >/dev/null 2>&1; then
  # Synchronous: must be available before first prompt
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZL::key-bindings.zsh
  zinit light agkozak/zsh-z

  # Synchronous: OMZ snippets are tiny, load fast, and may call compdef
  zinit snippet OMZP::github
  zinit snippet OMZP::command-not-found
  zinit snippet OMZP::docker
  zinit snippet OMZP::docker-compose
  zinit snippet OMZP::genpass
  zinit snippet OMZP::asdf

  # Initialize completions after all synchronous plugins
  zinit ice blockf; zinit light zsh-users/zsh-completions
  autoload -Uz compinit && compinit
  zinit cdreplay -q

  # Turbo: only UI plugins that don't call compdef
  zinit wait lucid for \
    djui/alias-tips \
    hlissner/zsh-autopair \
    monlor/zsh-ai-assist \
    Aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-syntax-highlighting
fi

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
setopt share_history
setopt pushd_ignore_dups
setopt pushd_silent

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

export FZF_DEFAULT_OPTS='--reverse --bind ctrl-l:cancel'
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
