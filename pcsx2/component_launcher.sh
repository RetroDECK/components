#!/bin/bash

source /app/libexec/logger.sh

component_name="pcsx2"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_folder_path/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "$component_folder_path/apprun-hooks/default-to-x11.sh"

log i "RetroDECK is now launching $component_name"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

exec "$component_folder_path/bin/pcsx2-qt" "$@"
