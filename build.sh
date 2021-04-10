#!/bin/bash
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

docker run -d --network host --restart unless-stopped --name $NAME -v $CWD/out/$NAME/.reg/etc/config.json:/home/node/config.json $USER/$NAME:$ARCH
EOF
    chmod +x out/$NAME/.reg/bin/docker_run.sh
}

source_settings $1

ARCH=$(docker version --format '{{.Server.Arch}}')

if [ "$ARCH" = "arm" ]; then
    ARCH=arm32v7
elif [ "$ARCH" = "arm64" ]; then
    ARCH=arm64v8
fi

if [ ! -d "out/$NAME" ]; then
    echo There is no output directory available for $NAME, generate or import the extension first
    exit 1
fi

if [ ! -f "out/$NAME/Dockerfile" ]; then
    echo There is no Dockerfile available for $NAME, generate the extension first
    exit 1
fi

if [ "$USER" = "" ]; then
    echo There is no USER specified, update your settings file
    exit 1
fi

mkdir -p out/$NAME/.reg/{bin,etc}

docker run --rm --privileged multiarch/qemu-user-static:register --reset

declare -a archs=("amd64" "armv7" "arm64")
declare -a tags=("amd64" "arm32v7" "arm64v8")

for i in "${!archs[@]}"
do
    docker build --rm --build-arg build_arch=${archs[$i]} -t $USER/$NAME:${tags[$i]} out/$NAME

    if [ $? -gt 0 ]; then
        exit 1
    fi
done

generate_docker_run
