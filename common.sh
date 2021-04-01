VERSION=0.1.1

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

echo Roon Extension Generator version $VERSION
