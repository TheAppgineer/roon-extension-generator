VERSION=0.3.0

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
    if [ "$#" -gt 1 ]; then
        BASE_TAG=$1-$2
        VARIANT=$2.
    elif [ "$#" -gt 0 ]; then
        BASE_TAG=$1
    else
        BASE_TAG=latest
    fi
}

echo Roon Extension Generator version $VERSION
