#!/bin/bash

# Usage:   ./build.sh <name> [<base-tag> <variant>]
# Example: ./build.sh roon-extension-manager v1.x standalone
# Output:  <user>/<name>:<base-tag>-<variant>-<arch>

source common.sh

generate_docker_run() {
    echo Generating docker_run.sh
    CWD=$(pwd)
    touch out/$1/.reg/etc/config.json

    arch=$(docker version --format '{{.Server.Arch}}')

    if [ "$arch" = "arm" ]; then
        arch=arm32v7
    elif [ "$arch" = "arm64" ]; then
        arch=arm64v8
    fi

    cat << EOF > out/$1/.reg/bin/docker_run.sh
#!/bin/sh
docker container inspect $CONTAINER_NAME > /dev/null 2>&1

if [ \$? -eq 0 ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

docker run -d --network host --restart unless-stopped --name $CONTAINER_NAME -v $CWD/out/$1/.reg/etc/config.json:/home/node/config.json $REPO:$BASE_TAG-$arch
EOF
    chmod +x out/$1/.reg/bin/docker_run.sh
}

source_settings $1

if [ "$1" = "" ]; then
    echo Please specify the name of the extension to build
    echo "Usage:   ./build.sh <name> [<base-tag> <variant>]"
    exit 1
fi

if [ ! -d "out/$1" ]; then
    echo There is no output directory available for $1, generate or import the extension first
    exit 1
fi

mkdir -p out/$1/.reg/{bin,etc}

docker run --rm --privileged multiarch/qemu-user-static:register --reset > /dev/null 2>&1

declare -a tags=("amd64" "arm32v7" "arm64v8")
declare -a pkg_archs=("x64" "armv6" "arm64")

for i in "${!tags[@]}"
do
    get_tag_and_variant ${tags[$i]} $1 $2 $3

    echo Building ${tags[$i]} image: $REPO:$BASE_TAG-${tags[$i]}
    echo Using Dockerfile: $DOCKERFILE
    echo

    docker build --rm --build-arg build_arch=$ARCH --build-arg pkg_arch=${pkg_archs[$i]} -t $REPO:$BASE_TAG-${tags[$i]} -f out/$1/$DOCKERFILE out/$1

    if [ $? -gt 0 ]; then
        exit 1
    fi
done

generate_docker_run $1
