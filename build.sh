#!/bin/bash
source common.sh

generate_docker_run() {
    echo Generating docker_run.sh
    CWD=$(pwd)
    touch out/$NAME/.reg/etc/config.json
    cat << EOF > out/$NAME/.reg/bin/docker_run.sh
docker container inspect $NAME > /dev/null 2>&1

if [ \$? -eq 0 ]; then
    docker stop $NAME
    docker rm $NAME
fi

docker run -d --network host --restart unless-stopped --name $NAME -v $CWD/out/$NAME/.reg/etc/config.json:/home/node/config.json $NAME:$TAG
EOF
    chmod +x out/$NAME/.reg/bin/docker_run.sh
}

generate_repository_entry() {
    echo Generating repository.json
    cat << EOF > out/$NAME/.reg/etc/repository.json
[{
    "display_name": "Test",
    "extensions": [{
        "author": "$AUTHOR",
        "display_name": "$FRIENDLY_NAME",
        "description": "$DESCRIPTION",
        "image": {
            "repo": "$IMAGE",
            "tags": {
                "$TAG": "$TAG"
            },
            "binds": [
                "/home/node/config.json"
            ]
        }
    }]
}]
EOF
}

source_settings $1

TAG=$(docker version --format '{{.Server.Arch}}')

if [ ! -d "out/$NAME" ]; then
    echo There is no output directory available for $NAME, generate or import the extension first
    exit 1
fi

mkdir -p out/$NAME/.reg/{bin,etc}

if [ "$USER" = "" ]; then
    docker build --rm -t $NAME:$TAG out/$NAME
    generate_docker_run
else
    docker build --rm -t $USER/$NAME:$TAG out/$NAME
    docker push $USER/$NAME:$TAG
    if [ $? -gt 0 ]; then
        echo "Failed to push the image, has the account been setup?"
        exit 1
    fi

    generate_repository_entry
    docker cp out/$NAME/.reg/etc/repository.json roon-extension-manager:/home/node/.rem/repos/
fi
