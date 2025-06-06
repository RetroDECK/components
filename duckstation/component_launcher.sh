#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="duckstation"

source "$rd_components/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$rd_components/$COMPONENT_NAME/bin/duckstation-qt" "$@"
