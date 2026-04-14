#!/bin/bash

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_COMPLETION="${OPENCLAW_COMPLETION:-$OPENCLAW_HOME/completions/openclaw.zsh}"

which helm &> /dev/null && source <(helm completion zsh)
which kubectl &> /dev/null && source <(kubectl completion zsh)
which k9s &> /dev/null && source <(k9s completion zsh)
which asdf &> /dev/null && source <(asdf completion zsh)
which docker &> /dev/null && source <(docker completion zsh)
which pv-migrate &> /dev/null && source <(pv-migrate completion zsh)
which gh &> /dev/null && source <(gh completion -s zsh)
[ -f "$OPENCLAW_COMPLETION" ] && source "$OPENCLAW_COMPLETION"
