#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

log i "--------------------------------"
log i "Preparing $component_name"
log i "--------------------------------"

if [[ "$action" == "reset" ]]; then
  rm -rf "$XDG_CONFIG_HOME/ES-DE"
  create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
  log d "Prepearing es_de_config_es_settings.xml"
  cp -f "$component_config/es_de_config_es_settings.xml" "$es_de_config"
  set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es_de_config_es_settings"
  set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es_de_config_es_settings"
  set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es_de_config_es_settings"
  dir_prep "$path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
  dir_prep "$path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
  dir_prep "$path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
  log d "Generating roms system folders"
  start_esde --create-system-dirs
  update_splashscreens
fi

if [[ "$action" == "postmove" ]]; then
  set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es_de_config_es_settings"
  set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es_de_config_es_settings"
  set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es_de_config_es_settings"
  dir_prep "$path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
fi
