#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="cemu"
RD_MODULES="/app/retrodeck/components"

source "$RD_MODULES/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "$RD_MODULES/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$RD_MODULES/$COMPONENT_NAME/bin/Cemu" "$@"
