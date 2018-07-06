#!/bin/bash

# Arguments:
#   [packer_version]    - will be used latest if not set

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $UID -ne 0 ]; then
    echo "Expected run this script as root user!"
    exit 1
fi

PACKER_VERSION="$1"

PACKER_BIN_PATH='/usr/bin/packer'
PACKER_TMP_DIR=$(mktemp -d)

function cleanup() {
        rm -r $PACKER_TMP_DIR
}
trap cleanup EXIT

function install_packer() {
    PACKER_URL="https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_amd64.zip"

    if ! which curl 2>&1 >/dev/null; then
        apt-get install --no-install-recommends curl >/dev/null
    fi

    cd $PACKER_TMP_DIR
    echo "Downloading ${PACKER_URL}..."
    curl ${PACKER_URL} --fail -o $PACKER_TMP_DIR/packer.zip 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "[ERROR] Cannot download from $PACKER_URL"
        exit 1
    fi
    unzip $PACKER_TMP_DIR/packer.zip 1>/dev/null
    mv $PACKER_TMP_DIR/packer $PACKER_BIN_PATH
    chmod +x $PACKER_BIN_PATH
    echo "Packer $PACKER_VERSION was installed"
}

CURRENT_PACKER_BIN_PATH=$(which packer)
if [ -n "$CURRENT_PACKER_BIN_PATH" ]; then
    PACKER_BIN_PATH=$CURRENT_PACKER_BIN_PATH
fi


if [ -z "$PACKER_VERSION" ]; then
    if ! which jq 2>&1 >/dev/null; then
        apt-get install --no-install-recommends jq >/dev/null
    fi

    if ! which curl 2>&1 >/dev/null; then
        apt-get install --no-install-recommends curl >/dev/null
    fi

    PACKER_VERSION=$(curl https://releases.hashicorp.com/index.json 2>/dev/null \
                    | jq '{packer}' \
                    | egrep "linux.*amd64" \
                    | sort --version-sort -r \
                    | head -1 \
                    | awk -F[_] '{print $2}')
fi

if which packer >/dev/null; then
    CURRENT_PACKER_VERSION="$(packer -v)"

    if [ "$CURRENT_PACKER_VERSION" == "$PACKER_VERSION" ]; then
        echo "Already installed actual Packer version $CURRENT_PACKER_VERSION"
        exit 0
    fi

    echo -e "Current Packer version: $CURRENT_PACKER_VERSION\nWill be installed version: $PACKER_VERSION"
fi

install_packer
