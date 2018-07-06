#!/bin/bash

apt-get update
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates curl \
    gnupg

curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - 
echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list 

apt-get update
apt-get install -y --no-install-recommends \
    google-chrome-stable
