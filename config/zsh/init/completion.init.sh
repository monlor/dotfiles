#!/bin/bash

which helm &> /dev/null && source <(helm completion zsh)
which kubectl &> /dev/null && source <(kubectl completion zsh)
which k9s &> /dev/null && source <(k9s completion zsh)
which asdf &> /dev/null && source <(asdf completion zsh)
which docker &> /dev/null && source <(docker completion zsh)