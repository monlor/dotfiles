#!/bin/bash

export GO111MODULE=on
export GOPROXY=${GOPROXY:-https://proxy.golang.org}
export GOPATH=${HOME}/.go
export PATH=${PATH}:${GOPATH}/bin
