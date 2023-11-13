#!/bin/bash

export GO111MODULE=on
export GOPROXY=${GOPROXY:-https://goproxy.cn}
export GOPATH=${HOME}/golang
export PATH=${PATH}:${GOPATH}/bin
