#!/bin/bash

echo "This script will inject all the component_files and the rd_config folder into the RetroDeck component folder."
read -r -p "Do you want to continue? (Y/n): " continue

# Default to "y" if input is empty
if [[ -z "$continue" ]]; then
    continue="y"
fi

if [[ "$continue" =~ ^[Yy]$ ]]; then

    flatpak_user_installation="$HOME/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files"
    flatpak_system_installation="/var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/files"
    force_user=false
    force_system=false

    # Determine installation path
    if [ "$force_user" = true ]; then
        echo "Forcing user mode installation."
        app="$flatpak_user_installation"
    elif [ "$force_system" = true ]; then
        echo "Forcing system mode installation."
        app="$flatpak_system_installation"
    elif [ -d "$flatpak_user_installation" ]; then
        echo "RetroDECK is installed in user mode, proceeding."
        app="$flatpak_user_installation"
    elif [ -d "$flatpak_system_installation" ]; then
        echo "RetroDECK is installed in system mode, proceeding."
        app="$flatpak_system_installation"
    else
        echo "RetroDECK installation not found, are you inside a flatpak? Quitting"
        exit 1
    fi

    for dir in */; do
        # Skip hidden folders and automation-tools
        [[ "$dir" == .* || "$dir" == "automation-tools/" ]] && continue
            echo "Injecting $dir into $app/retrodeck/components/$dir"
            mkdir -p "$app/retrodeck/components/$dir"
            cp -r "$dir"* "$app/retrodeck/components/$dir"
    done

else
    echo "Aborting the injection."
    exit 1
fi