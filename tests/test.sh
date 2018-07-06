#!/bin/bash

set -e
set -o pipefail

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for f in "$SCRIPT_PATH/../*.sh"; do
    bash f
done
