#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="dolphin"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

# Set plugin paths
export QT_PLUGIN_PATH="$rd_shared_libs/plugins:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$rd_shared_libs/qt-6.8/lib/plugins/platforms"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"
log d "QT QPA PLATFORM plugin path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        log d "QT_QPA_PLATFORMTHEME is set to: $QT_QPA_PLATFORMTHEME"
        ;;
esac

# Workaround for Wayland on Pop!_OS Cosmic (force X11 backend)
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export QT_QPA_PLATFORM=xcb
    log d "QT_QPA_PLATFORM is set to: $QT_QPA_PLATFORM"
fi

# Launch Dolphin
exec "$COMPONENT_FOLDER/bin/dolphin-emu" "$@"
