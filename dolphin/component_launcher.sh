#!/bin/bash

RD_MODULES="/app/retrodeck/components"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$RD_MODULES/dolphin/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

# Set plugin paths
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins/platforms"

# Workaround for Wayland on Pop!_OS Cosmic (force X11 backend)
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export QT_QPA_PLATFORM=xcb
fi

# Launch Dolphin
exec "$RD_MODULES/dolphin/bin/dolphin-emu" "$@"