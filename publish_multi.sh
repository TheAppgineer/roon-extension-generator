#!/bin/bash
source common.sh

source_settings $1

TAG=$(docker version --format '{{.Server.Arch}}')

image_list=("$USER/$NAME:$TAG")

if [ "$#" -gt 1 ]; then
    declare -a extra_pulls=("$@")

    for extra_pull in "${extra_pulls[@]}"
    do
        if [ "$extra_pull" != "$1" ]; then
            docker pull $USER/$NAME:$extra_pull
            image_list+=("$USER/$NAME:$extra_pull")
        fi
    done
fi

docker manifest create $USER/$NAME:latest ${image_list[@]}

docker manifest push --purge $USER/$NAME:latest
