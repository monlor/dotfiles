OS=$(uname)

if [[ $OS == 'Darwin' ]]; then
  export PATH="/opt/homebrew/opt/trash-cli/bin:$PATH"
fi