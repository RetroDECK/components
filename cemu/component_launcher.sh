#!/bin/bash

source /app/libexec/logger.sh

component_name="cemu"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_folder_path/apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "$component_folder_path/apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $component_name"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$component_folder_path/bin/Cemu" "$@"
