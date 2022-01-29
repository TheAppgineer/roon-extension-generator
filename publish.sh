#!/bin/bash
source common.sh

generate_repository_entry() {
    echo Generating repository.json
    cat << EOF > out/$1/.reg/etc/repository.json
[{
    "display_name": "Test",
    "extensions": [{
        "author": "$AUTHOR",
        "display_name": "$FRIENDLY_NAME",
        "description": "$DESCRIPTION",
        "image": {
            "repo": "$REPO",
            "tags": {
                "amd64": "$2",
                "arm": "$3",
                "arm64": "$4"
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

if [ "$USER" = "" ]; then
    echo Publishing to Docker Hub requires a USER specified in settings
    exit 1
fi

declare -a image_list=()
declare -a tags=("amd64" "arm32v7" "arm64v8")

for tag in "${tags[@]}"
do
    get_tag_and_variant $tag $1 $2 $3

    docker push $REPO:$BASE_TAG-$tag
    if [ $? -gt 0 ]; then
        echo "Failed to push the image, has the account been setup?"
        exit 1
    fi
    image_list+=("$REPO:$BASE_TAG-$tag")
done

docker manifest > /dev/null 2>&1
if [ $? -eq 0 ]; then
    docker manifest create $REPO:$BASE_TAG ${image_list[@]}
    docker manifest annotate --arch arm --variant v7 $REPO:$BASE_TAG $REPO:$BASE_TAG-arm32v7
    docker manifest annotate --arch arm64 --variant v8 $REPO:$BASE_TAG $REPO:$BASE_TAG-arm64v8
    docker manifest push --purge $REPO:$BASE_TAG

    generate_repository_entry $1 $BASE_TAG $BASE_TAG $BASE_TAG
else
    echo "Warning: manifest not supported, specific tags used instead"

    generate_repository_entry $1 $BASE_TAG-${tags[0]} $BASE_TAG-${tags[1]} $BASE_TAG-${tags[2]}
fi

docker container inspect roon-extension-manager > /dev/null 2>&1
if [ $? -eq 0 ]; then
    docker exec roon-extension-manager mkdir -p /home/node/.rem/repos
    docker cp out/$1/.reg/etc/repository.json roon-extension-manager:/home/node/.rem/repos/$CONTAINER_NAME.json
    docker restart roon-extension-manager > /dev/null 2>&1
else
    echo "Warning: Extension Manager not found, repository file not copied"
fi
