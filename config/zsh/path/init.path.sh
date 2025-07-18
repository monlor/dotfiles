# golang
export GO111MODULE=on
export GOPROXY=${GOPROXY:-https://proxy.golang.org}
export GOPATH=${HOME}/.go
export PATH=${PATH}:${GOPATH}/bin

# toolbox
if [[ -d $HOME/.toolbox/ ]]; then
  export PATH=$PATH:$HOME/.toolbox/bin
fi
