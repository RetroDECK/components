#!/bin/bash

source /app/libexec/launcher_functions.sh

if [[ ! -f "$satellaview_bsx_path/bs-x.sfc" ]]; then
  rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK: Satellaview+ - Error: ROM not found" \
        --text="Satellaview+ ROM not found. Please provide the 'bs-x.sfc' ROM file in the '$satellaview_bsx_path' directory and try again."
  exit 1
fi

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

# We move here because the config file is read from ./
cd "$satellaview_config_path"

# This is merely a wrapper for .sh launchers
exec "$@"