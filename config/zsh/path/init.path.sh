# golang
#export GO111MODULE=on
#export GOPROXY=${GOPROXY:-https://proxy.golang.org}
#export GOPATH=${HOME}/.go
#export PATH=${PATH}:${GOPATH}/bin

# krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*) ;;
  *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# toolbox
if [[ -d $HOME/.toolbox/ ]]; then
  export PATH=$PATH:$HOME/.toolbox/bin
fi
