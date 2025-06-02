#!/bin/bash

COMPONENT_NAME="pcsx2"
RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "apprun-hooks/default-to-x11.sh"

exec "$RD_MODULES/$COMPONENT_NAME/bin/pcsx2-qt" "$@"
