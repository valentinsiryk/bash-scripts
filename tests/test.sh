#!/bin/bash

set -e
set -o pipefail

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $SCRIPT_PATH/..

SCRIPTS=$(ls *.sh)

for f in $SCRIPTS; do
    bash $f 2>&1 >/dev/null
    if [ $? -eq 0 ]; then
        echo "[OK] $f"
    else
        echo "[FAIL] $f"
    fi    
done
