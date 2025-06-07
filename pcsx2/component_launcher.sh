#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="pcsx2"

source "$rd_components/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "$rd_components/$COMPONENT_NAME/apprun-hooks/default-to-x11.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

exec "$rd_components/$COMPONENT_NAME/bin/pcsx2-qt" "$@"
