#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="melonds"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:$rd_shared_libs/qt-6.7/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.7/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac

log d "QT_QPA_PLATFORMTHEME is set to: $QT_QPA_PLATFORMTHEME"

exec "$COMPONENT_FOLDER/bin/melonDS" "$@"
