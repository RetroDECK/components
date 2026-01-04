#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then
  log i "--------------------------------"
  log i "Resetting $component_name"
  log i "--------------------------------"

  rm -rf "$XDG_CONFIG_HOME/ES-DE"
  create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
  log d "Preparing es_settings.xml"
  cp -f "$component_config/es_settings.xml" "$es_de_config"
  set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es_settings"
  set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es_settings"
  set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es_settings"
  dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
  dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
  dir_prep "$rd_home_path/ES-DE/scripts" "$XDG_CONFIG_HOME/ES-DE/scripts"
  dir_prep "$rd_home_path/ES-DE/screensavers" "$XDG_CONFIG_HOME/ES-DE/screensavers"
  dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
  dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
  log d "Generating roms system folders"
  start_esde --create-system-dirs
  update_splashscreens
fi

if [[ "$action" == "postmove" ]]; then
  log i "--------------------------------"
  log i "Post-moving $component_name"
  log i "--------------------------------"

  set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es_settings"
  set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es_settings"
  set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es_settings"
  dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
fi
