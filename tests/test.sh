#!/bin/bash

set -e
set -o pipefail

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $SCRIPT_PATH/..

SCRIPTS=$(ls *.sh)

for f in $SCRIPTS; do
    echo -e "\n[TEST] Testing script: $f"
    case $f in
        'docker-deploy.sh')
            echo 'FROM nginx:stable' > $SCRIPT_PATH/../Dockerfile
            PORT_INTERNAL=80 bash $f nginx
            docker rm -f nginx
            rm $SCRIPT_PATH/../Dockerfile
            ;;
        *)
            bash $f
            ;;  
    esac

    if [ $? -eq 0 ]; then
        echo "[OK] Tested script: $f"
    else
        echo "[FAIL] Tested script: $f"
    fi
done
