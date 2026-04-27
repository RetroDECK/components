#!/bin/bash

source /app/libexec/launcher_functions.sh

if [[ ! -f "$roms_path/satellaview_plus/bs-x.sfc" ]]; then
  rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK: Satellaview+ - Error: ROM not found" \
        --text="Satellaview+ ROM not found.\n\nPlease provide the 'bs-x.sfc' ROM file in the\n'$satellaview_plus_bsx_path'\n\ndirectory and try again."
  exit 1
else
  cp "$roms_path/satellaview_plus/bs-x.sfc" "$satellaview_plus_bsx_path/bs-x.sfc"
  # TODO: if we need to patch the roms we can do it here
fi

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

# This is merely a wrapper for .sh launchers
command=$(cat "$1")

case $command in

  run)
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME/satellaview_plus/snes9x" exec "$component_path/bin/snes9x-gtk" "$satellaview_plus_bsx_path/bs-x.sfc"
    ;;

  tuner)

    export LD_LIBRARY_PATH="$component_path/usr/lib/:$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"
    export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}"
    export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH}"

    # We move here because the config file is read from ./
    cd "$satellaview_plus_config_path"
    exec "$component_path/AppRun"
    ;;
  *)
    log e "Unknown command '$command' in launcher script '$1'"
    exit 1
    ;;
esac