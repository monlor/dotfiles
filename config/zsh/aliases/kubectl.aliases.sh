alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kgn='kubectl get nodes'

alias kaf='kubectl apply -f'
alias kdelf='kubectl delete -f'
alias kdesc='kubectl describe'
alias kctx='kubectl config use-context'

alias kgpo='kubectl get pods -o wide'
alias kgdow='kubectl get deployment -o wide'
alias kgnow='kubectl get nodes -o wide'
alias kgnamow='kubectl get nodes -o wide --show-labels'

alias klog='kubectl logs'
alias klf='kubectl logs -f'
alias klogpo='kubectl logs pods'
alias klfpo='kubectl logs -f pods'

alias ktail='kubetail'
alias ktailpo='kubetail -p'

alias kns='kubectl config set-context --current --namespace'
