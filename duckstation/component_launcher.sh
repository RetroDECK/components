#!/bin/bash

source /app/libexec/logger.sh

component_name="duckstation"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_folder_path/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

log i "RetroDECK is now launching $component_name"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$component_folder_path/bin/duckstation-qt" "$@"
