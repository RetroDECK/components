#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="cemu"

source "$rd_components/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "$rd_components/$COMPONENT_NAME/apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$rd_components/$COMPONENT_NAME/bin/Cemu" "$@"
