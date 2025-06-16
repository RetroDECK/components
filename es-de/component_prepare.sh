#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

log i "--------------------------------"
log i "Preparing $component_name"
log i "--------------------------------"

if [[ "$action" == "reset" ]]; then
    rm -rf "$XDG_CONFIG_HOME/ES-DE"
    create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
    log d "Prepearing es_settings.xml"
    cp -f "$config/es_settings.xml" "$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
    set_setting_value "$es_settings" "ROMDirectory" "$rd_home_roms_path" "es_settings"
    set_setting_value "$es_settings" "MediaDirectory" "$rd_home_downloaded_media_path" "es_settings"
    set_setting_value "$es_settings" "UserThemeDirectory" "$rd_home_themes_path" "es_settings"
    dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
    dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
    dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
    log d "Generating roms system folders"
    start_esde --create-system-dirs
    update_splashscreens
fi

if [[ "$action" == "postmove" ]]; then
    set_setting_value "$es_settings" "ROMDirectory" "$rd_home_roms_path" "es_settings"
    set_setting_value "$es_settings" "MediaDirectory" "$rd_home_downloaded_media_path" "es_settings"
    set_setting_value "$es_settings" "UserThemeDirectory" "$rd_home_themes_path" "es_settings"
    dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
fi
