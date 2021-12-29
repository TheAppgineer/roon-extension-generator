VERSION=0.4.0

source_settings() {
    if [ -f "out/$1/.reg/settings" ]; then
        echo Reading settings from: out/$1/.reg/settings
        source out/$1/.reg/settings
    else
        if [ ! -f "settings" ]; then
            cp settings.sample settings
        fi

        echo Reading settings from: settings
        source settings
    fi
}

get_tag_and_variant() {
    if [ "$#" -gt 2 ]; then
        VARIANT=$3
    fi
    if [ "$#" -gt 1 ]; then
        BASE_TAG=$2
    else
        BASE_TAG=latest
    fi

    if [ "$USER" != "" ]; then
        USER=$USER/
    fi

    if [ -f "out/$1/$VARIANT.Dockerfile" ]; then
        DOCKERFILE=$VARIANT.Dockerfile
        REPO=$USER$NAME
        BASE_TAG=$BASE_TAG-$VARIANT
    elif [ -f "out/$1/$VARIANT/Dockerfile" ]; then
        DOCKERFILE=$VARIANT/Dockerfile
        REPO=$USER$NAME-$VARIANT
        NAME=$NAME-$VARIANT
    elif [ -f "out/$1/Dockerfile" ]; then
        DOCKERFILE=Dockerfile
        REPO=$USER$NAME
    else
        echo There is no Dockerfile found for $1, generate the extension first
        exit 1
    fi
}

echo Roon Extension Generator version $VERSION
