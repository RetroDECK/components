#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="pcsx2"
RD_MODULES="/app/retrodeck/components"

source "$RD_MODULES/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "$RD_MODULES/$COMPONENT_NAME/apprun-hooks/default-to-x11.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

exec "$RD_MODULES/$COMPONENT_NAME/bin/pcsx2-qt" "$@"
