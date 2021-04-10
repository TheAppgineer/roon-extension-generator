#!/bin/bash
source common.sh

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
            "repo": "$USER/$NAME",
            "tags": {
                "amd64": "$1",
                "arm": "$2",
                "arm64": "$3"
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

declare -a image_list=()
declare -a tags=("amd64" "arm32v7" "arm64v8")

for tag in "${tags[@]}"
do
    docker push $USER/$NAME:$tag
    if [ $? -gt 0 ]; then
        echo "Failed to push the image, has the account been setup?"
        exit 1
    fi
    image_list+=("$USER/$NAME:$tag")
done

docker manifest > /dev/null 2>&1
if [ $? -eq 0 ]; then
    docker manifest create $USER/$NAME:latest ${image_list[@]}
    docker manifest annotate --arch arm --variant v7 $USER/$NAME:latest $USER/$NAME:arm32v7
    docker manifest annotate --arch arm64 --variant v8 $USER/$NAME:latest $USER/$NAME:arm64v8
    docker manifest push --purge $USER/$NAME:latest

    generate_repository_entry "latest" "latest" "latest"
else
    echo "Warning: manifest not supported, specific tags used instead"

    generate_repository_entry ${tags[@]}
fi

docker container inspect roon-extension-manager > /dev/null 2>&1
if [ $? -eq 0 ]; then
    docker exec roon-extension-manager mkdir -p /home/node/.rem/repos
    docker cp out/$NAME/.reg/etc/repository.json roon-extension-manager:/home/node/.rem/repos/$NAME.json
    docker restart roon-extension-manager > /dev/null 2>&1
else
    echo "Warning: Extension Manager not found, repository file not copied"
fi
