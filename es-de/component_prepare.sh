#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config=""$config/"config/$component_name/rd_config"

log i "--------------------------------"
log i "Prepearing ES-DE"
log i "--------------------------------"

if [[ "$action" == "reset" ]]; then
    rm -rf "$XDG_CONFIG_HOME/ES-DE"
    create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
    log d "Prepearing es_settings.xml"
    cp -f ""$config/"es_settings.xml" "$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
    set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
    set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
    set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
    dir_prep "$rdhome/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
    dir_prep "$rdhome/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
    log d "Generating roms system folders"
    es-de --create-system-dirs
    update_splashscreens
fi

if [[ "$action" == "postmove" ]]; then
    set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
    set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
    set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
fi