#!/bin/bash

# Args: <container_name>

# docker -p <LISTEN_INTERFACE>:<PORT_EXTERNAL>:<PORT_INTERNAL>
LISTEN_INTERFACE="${LISTEN_INTERFACE:-127.0.0.1}"
PORT_INTERNAL="${PORT_INTERNAL:-8080}"
PORT_EXTERNAL="${PORT_EXTERNAL:-8080}"

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$1" ]; then
    echo "Missing arguments: <container_name>"
    exit 1
fi

if [ ! -e $SCRIPT_PATH/Dockerfile ]; then
    "[ERROR] Dockerfile '$SCRIPT_PATH/Dockerfile' doesn't exist!"
    exit 1
fi

let "PORT_TEST = $PORT_EXTERNAL + 10000"

CONTAINER_NAME="$1"
CONTAINER_NAME_TEST="${CONTAINER_NAME}.test"
IMAGE_NAME="${CONTAINER_NAME}:latest"
IMAGE_NAME_TEST="${CONTAINER_NAME}.test:latest"


## Cleaning up

cleanup() {
    echo "[INFO] Removing dangling and test docker images..."
    docker rm -f ${CONTAINER_NAME_TEST} >/dev/null 2>&1
    docker rmi $IMAGE_NAME_TEST >/dev/null 2>&1
    docker rmi $(docker images -q -f dangling=true) > /dev/null 2>&1
}

trap cleanup EXIT


## Docker installation

install_docker() {
    if hash docker 2>/dev/null; then
        echo "[INFO] Docker already installed. Installation was skipped."
        return
    fi
    
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker $USER
    
    echo "[OK] Docker was installed"
}


## Test build

test_build() {
	docker build -f $SCRIPT_PATH/Dockerfile -t "$IMAGE_NAME_TEST" $SCRIPT_PATH/

	docker run -d --name "$CONTAINER_NAME_TEST" -p 127.0.0.1:$PORT_TEST:$PORT_INTERNAL $IMAGE_NAME_TEST

    echo "[INFO] Waiting until test container response..."
    MAX_TRIES=12
    TRY=0
    while ! curl -sSf 127.0.0.1:$PORT_TEST >/dev/null 2>&1; do
        let "TRY = TRY + 1"
        
        if [ $TRY -ge $MAX_TRIES ]; then
            echo '[ERROR] Test container has not responsed'
            return 1 
        fi
        
	    sleep 1    
	done
	
    TEST_IMAGE_ID=$(docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}" | grep -w "$IMAGE_NAME_TEST" | cut -f 1 -d ' ')
    CURRENT_IMAGE_ID=$(docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}" | grep -w "$IMAGE_NAME" | cut -f 1 -d ' ')
    
	return 0
}


install_docker

echo "[INFO] Test image building..."
if ! test_build; then
	echo "[ERROR] Test build failed!"
	exit 1
fi

echo "[INFO] Current/new image ID: ${CURRENT_IMAGE_ID}/${TEST_IMAGE_ID}"

echo "[INFO] Removing current '$CONTAINER_NAME' container"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1

## Swap images
docker rmi "$IMAGE_NAME" >/dev/null 2>&1
docker tag "$IMAGE_NAME_TEST" "$IMAGE_NAME"

echo "[INFO] Running new '$CONTAINER_NAME' container..."
docker run --restart unless-stopped -d --name $CONTAINER_NAME -p $LISTEN_INTERFACE:$PORT_EXTERNAL:$PORT_INTERNAL $IMAGE_NAME >/dev/null

