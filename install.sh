#!/bin/bash

set -e

DOTBOT_DIR="modules/dotbot"

DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASDF=${ASDF:-false}

cd "${BASEDIR}"
git submodule update --init --recursive

echo "Installing prerequisites..."
if which brew &> /dev/null; then 
  which python3 &> /dev/null || brew install python3
  which git &> /dev/null || brew install git
  which curl &> /dev/null || brew install curl
  CONFIG="dotbot/install.base.yaml dotbot/install.brew.yaml"
  PLUGIN_DIR="--plugin-dir ${BASEDIR}/modules/dotbot-brewfile"
  if [ "${ASDF}" = "true" ]; then
    CONFIG="${CONFIG} dotbot/install.asdf.yaml"
    PLUGIN_DIR="${PLUGIN_DIR} --plugin-dir ${BASEDIR}/modules/dotbot-asdf"
  fi
elif which apt &> /dev/null; then
  sudo apt update && sudo apt install -y git python3
  CONFIG="dotbot/install.base.yaml dotbot/install.apt.yaml"
  PLUGIN_DIR=""
  if [ "${ASDF}" = "true" ]; then
    CONFIG="${CONFIG} dotbot/install.asdf.yaml"
    PLUGIN_DIR="${PLUGIN_DIR} --plugin-dir ${BASEDIR}/modules/dotbot-asdf"
  fi
else
  echo "Unknown environment. Exiting."
  exit 1
fi

# show config
cat <<-EOF

Dotbot will install the following:
* Configs
${CONFIG}
* Plugins
${PLUGIN_DIR}
EOF

sleep 3

cat ${CONFIG} > install.conf.yaml

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" ${PLUGIN_DIR} \
  -d "${BASEDIR}" \
  -c install.conf.yaml -x "${@}"

cat <<-EOF
Installation complete. 
* Run 'chsh -s $(which zsh)' to make zsh your default shell.
* Change terminal font to 'Nerd'.
* Run 'zsh' to start a new shell.
* Run 'asdf reshim python' for the binary to be in your path.
* Run 'make brew_restore' to restore all brew package.
When zgen initialization fails:
* zgen reset
* rm -rf ~/.zgen/zsh-users
Initialization:
* brew: make brew_install; make brew_restore
* mackup: make restore
EOF
