#!/bin/bash

COMPONENT_NAME="cemu"
RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$RD_MODULES/$COMPONENT_NAME/bin/Cemu" "$@"
