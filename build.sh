#!/bin/bash

# Usage:   ./build.sh [<name> <base-tag> <variant>]
# Example: ./build.sh roon-extension-manager v1.x standalone
# Output:  <user>/<name>:<base-tag>-<variant>-<arch>

source common.sh

generate_docker_run() {
    echo Generating docker_run.sh
    CWD=$(pwd)
    touch out/$1/.reg/etc/config.json
    cat << EOF > out/$1/.reg/bin/docker_run.sh
#!/bin/sh
docker container inspect $NAME > /dev/null 2>&1

if [ \$? -eq 0 ]; then
    docker stop $NAME
    docker rm $NAME
fi

docker run -d --network host --restart unless-stopped --name $NAME -v $CWD/out/$1/.reg/etc/config.json:/home/node/config.json $REPO:$BASE_TAG-$ARCH
EOF
    chmod +x out/$1/.reg/bin/docker_run.sh
}

source_settings $1
get_tag_and_variant $1 $2 $3

ARCH=$(docker version --format '{{.Server.Arch}}')

if [ "$ARCH" = "arm" ]; then
    ARCH=arm32v7
elif [ "$ARCH" = "arm64" ]; then
    ARCH=arm64v8
fi

if [ ! -d "out/$1" ]; then
    echo There is no output directory available for $1, generate or import the extension first
    exit 1
fi

echo Generating multiarch images for: $REPO:$BASE_TAG
echo Using Dockerfile: $DOCKERFILE
echo

mkdir -p out/$1/.reg/{bin,etc}

docker run --rm --privileged multiarch/qemu-user-static:register --reset > /dev/null 2>&1

DISTRO=$(cat out/$1/$DOCKERFILE | grep -m 1 multiarch | cut -f2 -d/ | cut -f1 -d:)

if [ "$DISTRO" = "debian-debootstrap" ]; then
    declare -a archs=("amd64" "armhf" "arm64")
else
    declare -a archs=("amd64" "armv7" "arm64")
fi
declare -a tags=("amd64" "arm32v7" "arm64v8")
declare -a pkg_archs=("x64" "armv6" "arm64")

for i in "${!archs[@]}"
do
    docker build --rm --build-arg build_arch=${archs[$i]} --build-arg pkg_arch=${pkg_archs[$i]} -t $REPO:$BASE_TAG-${tags[$i]} -f out/$1/$DOCKERFILE out/$1

    if [ $? -gt 0 ]; then
        exit 1
    fi
done

generate_docker_run $1
