# asdf 
if [[ -f $HOME/.local/bin/asdf ]]; then
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
fi

# golang
export GO111MODULE=on
export GOPROXY=${GOPROXY:-https://proxy.golang.org}
export GOPATH=${HOME}/.go
export PATH=${PATH}:${GOPATH}/bin

# scripts
export PATH=$PATH:$HOME/.local/bin

# toolbox
if [[ -d $HOME/.toolbox/ ]]; then
  export PATH=$PATH:$HOME/.toolbox/bin
fi
