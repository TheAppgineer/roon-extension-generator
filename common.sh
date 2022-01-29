VERSION=0.5.0

source_settings() {
    if [ -f "out/$1/.reg/settings" ]; then
        echo Reading settings from: out/$1/.reg/settings
        echo
        source out/$1/.reg/settings
    elif [ "$1" = "" ]; then
        if [ ! -f "settings" ]; then
            cp settings.sample settings
        fi

        echo Reading settings from: settings
        echo
        source settings
    else
        echo No settings found for: $1
        exit 1
    fi
}

get_tag_and_variant() {
    CONTAINER_NAME=$NAME

    if [ "$#" -gt 3 ]; then
        VARIANT=$4
    fi

    if [ "$#" -gt 2 ]; then
        BASE_TAG=$3
    else
        BASE_TAG=latest
    fi

    if [ "$VARIANT" = "" ]; then
        if [ -f "out/$2/Dockerfile" ]; then
            DOCKERFILE=Dockerfile
            REPO=$NAME
        else
            echo There is no Dockerfile found for $2, generate the extension first
            exit 1
        fi
    else
        if [ -f "out/$2/$1.$VARIANT.Dockerfile" ]; then
            DOCKERFILE=$1.$VARIANT.Dockerfile
            REPO=$NAME
            BASE_TAG=$BASE_TAG-$VARIANT
        elif [ -f "out/$2/$VARIANT.Dockerfile" ]; then
            DOCKERFILE=$VARIANT.Dockerfile
            REPO=$NAME
            BASE_TAG=$BASE_TAG-$VARIANT
        elif [ -f "out/$2/$VARIANT/$1.Dockerfile" ]; then
            DOCKERFILE=$VARIANT/$1.Dockerfile
            REPO=$NAME-$VARIANT
            CONTAINER_NAME=$NAME-$VARIANT
        elif [ -f "out/$2/$VARIANT/Dockerfile" ]; then
            DOCKERFILE=$VARIANT/Dockerfile
            REPO=$NAME-$VARIANT
            CONTAINER_NAME=$NAME-$VARIANT
        else
            echo There is no Dockerfile found for variant $VARIANT
            exit 1
        fi
    fi

    if [ "$USER" != "" ]; then
        REPO=$USER/$REPO
    fi

    DISTRO=$(cat out/$2/$DOCKERFILE | grep -m 1 multiarch | cut -f2 -d/ | cut -f1 -d:)

    if [ "$1" = "arm32v7" ]; then
        if [ "$DISTRO" = "debian-debootstrap" ]; then
            ARCH=armhf
        else
            ARCH=armv7
        fi
    elif [ "$1" = "arm64v8" ]; then
        ARCH=arm64
    else
        ARCH=$1
    fi
}

echo Roon Extension Generator version $VERSION
