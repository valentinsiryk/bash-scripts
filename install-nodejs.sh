#!/bin/bash

NODE_VERSION='8'

if ! which curl 2>&1 >/dev/null; then
    apt-get install --no-install-recommends curl >/dev/null
fi

curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - 
apt-get install -y --no-install-recommends build-essential nodejs
