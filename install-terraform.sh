#!/bin/bash

# Arguments:
#   [terraform_version]    - will be used latest if not set

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $UID -ne 0 ]; then
    echo "Expected run this script as root user!"
    exit 1
fi

APP_VERSION="$1"

APP_NAME='terraform'

APP_BIN_PATH="/usr/bin/$APP_NAME"
APP_TMP_DIR=$(mktemp -d)

OS=$(uname | tr '[:upper:]' '[:lower:]')

function cleanup() {
        rm -r $APP_TMP_DIR
}
trap cleanup EXIT

function install_app() {
    APP_URL="https://releases.hashicorp.com/$APP_NAME/$APP_VERSION/${APP_NAME}_${APP_VERSION}_${OS}_amd64.zip"

    if ! which curl 2>&1 >/dev/null; then
        apt-get install -y --no-install-recommends curl >/dev/null
    fi

    cd $APP_TMP_DIR
    echo "Downloading ${APP_URL}..."
    curl ${APP_URL} --fail -o $APP_TMP_DIR/$APP_NAME.zip 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "[ERROR] Cannot download from $APP_URL"
        exit 1
    fi
    unzip $APP_TMP_DIR/$APP_NAME.zip 1>/dev/null
    mv $APP_TMP_DIR/$APP_NAME $APP_BIN_PATH
    chmod +x $APP_BIN_PATH
    echo "The $APP_NAME $APP_VERSION was installed"
}

CURRENT_APP_BIN_PATH=$(which $APP_NAME)
if [ -n "$CURRENT_APP_BIN_PATH" ]; then
    APP_BIN_PATH=$CURRENT_APP_BIN_PATH
fi

apt-get update >/dev/null

if [ -z "$APP_VERSION" ]; then
    if ! which jq 2>&1 >/dev/null; then
        apt-get install -y --no-install-recommends jq >/dev/null
    fi

    if ! which curl 2>&1 >/dev/null; then
        apt-get install -y --no-install-recommends curl >/dev/null
    fi

    APP_VERSION=$(curl https://releases.hashicorp.com/index.json 2>/dev/null \
                    | jq "{$APP_NAME}" \
                    | egrep "${OS}.*amd64" \
                    | grep -v "\-alpha\|\-rc\|\-beta" \
                    | sort --version-sort -r \
                    | head -1 \
                    | awk -F[_] '{print $2}')
fi

if which $APP_NAME >/dev/null; then
    CURRENT_APP_VERSION="$($APP_NAME -v | awk -F'v' '{print $2}' | head -n 1)"

    if [ "$CURRENT_APP_VERSION" == "${APP_VERSION}" ]; then
        echo "Already installed actual $APP_NAME version $CURRENT_APP_VERSION"
        exit 0
    fi

    echo -e "Current $APP_NAME version: $CURRENT_APP_VERSION\nWill be installed version: $APP_VERSION"
fi

install_app

