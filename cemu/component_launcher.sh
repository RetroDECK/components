#!/bin/bash

RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$RD_MODULES/cemu/bin/Cemu" "$@"
