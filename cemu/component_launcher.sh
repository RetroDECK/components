#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_path/apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "$component_path/apprun-hooks/linuxdeploy-plugin-gtk.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $component_name"

exec "$component_path/bin/Cemu" "$@"
