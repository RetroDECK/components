#!/bin/bash

# This script is used in the shared-libs component to gather Qt plugins and Flatpak extensions from the installed Flatpak runtime.
# It takes one argument, which is the Qt version to gather plugins for (e.g., "5.15", "6.7", "6.9").
# The script checks for the existence of the plugins directory in both system-wide and user-specific Flatpak installations.
# If found, it copies the plugins and extensions to a designated build directory for inclusion in the Flatpak package.

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

# Ensure logfile is set and exported for all log calls
if [ -z "$logfile" ]; then
    export logfile="assemble.log"
else
    export logfile
fi

# Source logger functions
source ".tmpfunc/logger.sh"

gather_plugins(){    

    local extension_name="$1"
    local qt_version="$2"
    local arch="x86_64"

    log i "Gathering plugins and extensions for $extension_name Qt version $qt_version"

    # Check for system-wide installation
    if [ -d "/var/lib/flatpak/runtime/$extension_name/$arch/$qt_version/active/files/" ]; then
        local extension_path="/var/lib/flatpak/runtime/$extension_name/$arch/$qt_version/active/files/"
    # Check for user installation
    elif [ -d "$HOME/.local/share/flatpak/runtime/$extension_name/$arch/$qt_version/active/files/" ]; then
        local extension_path="$HOME/.local/share/flatpak/runtime/$extension_name/$arch/$qt_version/active/files/"
    else
        log e "Could not find extension $extension_name for Qt version $qt_version"
        return 1
    fi

    log i "Using extension path: $extension_path"
    
    local extension_dest="$WORK_DIR/shared-libs-$qt_version-build-dir/files/"
    mkdir -p "$extension_dest"
    log i "Copying extensions of $extension_name from $extension_path to $extension_dest"
    cp -r "$extension_path/"* "$extension_dest/"
    log i "Extensions of $extension_name//$arch//$qt_version copied successfully"

    # Determine plugins path - typically in /usr/lib/x86_64-linux-gnu/qt5/plugins or similar
    local plugins_path=""
    if [ -d "$extension_path/usr/lib/x86_64-linux-gnu/qt${qt_version/./}/plugins" ]; then
        plugins_path="$extension_path/usr/lib/x86_64-linux-gnu/qt${qt_version/./}/plugins"
    elif [ -d "$extension_path/usr/lib/x86_64-linux-gnu/plugins" ]; then
        plugins_path="$extension_path/usr/lib/x86_64-linux-gnu/plugins"
    elif [ -d "$extension_path/usr/lib/plugins" ]; then
        plugins_path="$extension_path/usr/lib/plugins"
    fi

    if [ -n "$plugins_path" ] && [ -d "$plugins_path" ]; then
        local plugin_dest="$WORK_DIR/shared-libs-$qt_version-build-dir/files/usr/lib/plugins/"
        mkdir -p "$plugin_dest"
        log i "Copying plugins of $extension_name from $plugins_path to $plugin_dest"
        cp -r "$plugins_path/"* "$plugin_dest/"
        log i "Plugins of $extension_name//$arch//$qt_version copied successfully"
    else
        log w "Could not find plugins directory for $extension_name Qt version $qt_version"
    fi
}
