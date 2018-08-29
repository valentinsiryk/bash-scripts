#!/bin/bash

set -e
set -o pipefail

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $SCRIPT_PATH/..

SCRIPTS=$(ls *.sh)

for f in $SCRIPTS; do
    echo "Testing script: $f"
    case $f in
        'docker-deploy.sh')
            echo 'FROM nginx' > $SCRIPT_PATH/../Dockerfile
            PORT_INTERNAL=80 bash $f nginx
            ;;
        *)
            bash $f
            ;;  
    esac

    if [ $? -eq 0 ]; then
        echo "[OK] $f"
    else
        echo "[FAIL] $f"
    fi    
done
