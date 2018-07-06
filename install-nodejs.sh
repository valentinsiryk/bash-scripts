#!/bin/bash

# Arguments:
#   [nodejs_version]    - will be used default if not set

if [ $UID -ne 0 ]; then
    echo "Expected run this script as root user!"
    exit 1
fi

NODE_VERSION="$1"

if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION='8'
fi

if ! which curl 2>&1 >/dev/null; then
    apt-get install --no-install-recommends curl >/dev/null
fi

curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - 
apt-get install -y --no-install-recommends build-essential nodejs
