#!/bin/bash

# Usage:   ./build.sh [<name> <base-tag> <variant>]
# Example: ./build.sh roon-extension-manager v1.x standalone
# Output:  <user>/<name>:<base-tag>-<variant>-<arch>

source common.sh

generate_docker_run() {
    echo Generating docker_run.sh
    CWD=$(pwd)
    touch out/$NAME/.reg/etc/config.json
    cat << EOF > out/$NAME/.reg/bin/docker_run.sh
#!/bin/sh
docker container inspect $NAME > /dev/null 2>&1

if [ \$? -eq 0 ]; then
    docker stop $NAME
    docker rm $NAME
fi

docker run -d --network host --restart unless-stopped --name $NAME -v $CWD/out/$NAME/.reg/etc/config.json:/home/node/config.json $USER$NAME:$BASE_TAG-$ARCH
EOF
    chmod +x out/$NAME/.reg/bin/docker_run.sh
}

source_settings $1
get_tag_and_variant $2 $3

ARCH=$(docker version --format '{{.Server.Arch}}')

if [ "$ARCH" = "arm" ]; then
    ARCH=arm32v7
elif [ "$ARCH" = "arm64" ]; then
    ARCH=arm64v8
fi

echo Generating multiarch images for: $BASE_TAG
echo Using Dockerfile: ${VARIANT}Dockerfile
echo

if [ ! -d "out/$NAME" ]; then
    echo There is no output directory available for $NAME, generate or import the extension first
    exit 1
fi

if [ ! -f "out/$NAME/${VARIANT}Dockerfile" ]; then
    echo There is no ${VARIANT}Dockerfile available for $NAME, generate the extension first
    exit 1
fi

if [ "$USER" != "" ]; then
    USER=$USER/
fi

mkdir -p out/$NAME/.reg/{bin,etc}

docker run --rm --privileged multiarch/qemu-user-static:register --reset > /dev/null 2>&1

DISTRO=$(cat out/$NAME/${VARIANT}Dockerfile | grep -m 1 multiarch | cut -f2 -d/ | cut -f1 -d:)

if [ "$DISTRO" = "debian-debootstrap" ]; then
    declare -a archs=("amd64" "armhf" "arm64")
else
    declare -a archs=("amd64" "armv7" "arm64")
fi
declare -a tags=("amd64" "arm32v7" "arm64v8")
declare -a pkg_archs=("x64" "armv6" "arm64")

for i in "${!archs[@]}"
do
    docker build --rm --build-arg build_arch=${archs[$i]} --build-arg pkg_arch=${pkg_archs[$i]} -t $USER$NAME:$BASE_TAG-${tags[$i]} -f out/$NAME/${VARIANT}Dockerfile out/$NAME

    if [ $? -gt 0 ]; then
        exit 1
    fi
done

generate_docker_run
