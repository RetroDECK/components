#!/bin/bash

RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "apprun-hooks/default-to-x11.sh"

exec "$RD_MODULES/pcsx2/bin/pcsx2-qt" "$@"
