#!/bin/bash

source /app/libexec/logger.sh

component_name="dolphin"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set component_library_path
export component_library_path="$component_folder_path/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${component_library_path}"

# Set plugin paths
export qt_plugin_path="/app/retrodeck/components/shared-libs/plugins:${qt_plugin_path}"
export qt_qpa_platform_plugin_path="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins/platforms"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"
log d "QT plugin path is: $qt_plugin_path"
log d "QT QPA PLATFORM plugin path is: $qt_qpa_platform_plugin_path"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export qt_qpa_platformtheme=gtk2
        log d "qt_qpa_platformtheme is set to: $qt_qpa_platformtheme"
        ;;
esac

# Workaround for Wayland on Pop!_OS Cosmic (force X11 backend)
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export qt_qpa_platform=xcb
    log d "qt_qpa_platform is set to: $qt_qpa_platform"
fi

# Launch Dolphin
exec "$component_folder_path/bin/dolphin-emu" "$@"
