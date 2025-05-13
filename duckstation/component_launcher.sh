#!/bin/bash

RD_MODULES="/app/retrodeck/components"

source "apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$RD_MODULES/duckstation/bin/duckstation-qt" "$@"
