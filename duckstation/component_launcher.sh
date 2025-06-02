#!/bin/bash

COMPONENT_NAME="duckstation"
RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$RD_MODULES/$COMPONENT_NAME/bin/duckstation-qt" "$@"
