#!/bin/bash

set -e

DOTBOT_DIR="modules/dotbot"

DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

if which brew &> /dev/null; then 
  which python3 &> /dev/null || brew install python3
  which git &> /dev/null || brew install git
  which curl &> /dev/null || brew install curl
  CONFIG="dotbot/install.base.yaml dotbot/install.brew.yaml dotbot/install.asdf.yaml"
  PLUGIN_DIR="--plugin-dir ${BASEDIR}/modules/dotbot-brewfile --plugin-dir ${BASEDIR}/modules/dotbot-asdf"
elif which apt &> /dev/null; then
  sudo apt update && sudo apt install -y git python3
  CONFIG="dotbot/install.base.yaml dotbot/install.apt.yaml"
  PLUGIN_DIR=""
else
  echo "Unknown environment. Exiting."
  exit 1
fi

echo ${CONFIG}
cat ${CONFIG} > install.conf.yaml

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" ${PLUGIN_DIR} \
  -d "${BASEDIR}" \
  -c install.conf.yaml -x "${@}"

cat <<-EOF
Installation complete. 
* Run 'chsh -s $(which zsh)' to make zsh your default shell.
* Change terminal font to 'Nerd'.
* Run 'zsh' to start a new shell.
* Run 'make brew_restore' to restore all brew package.
When zgen initialization fails:
* zgen reset
* rm -rf ~/.zgen/zsh-users
EOF
