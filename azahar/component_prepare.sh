#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  create_dir -d "$azahar_config_path"
  create_dir -d "$azahar_mods_path"
  create_dir -d "$azahar_textures_path"
  create_dir "$screenshots_path/Azahar"
  create_dir "$saves_path/n3ds/azahar/nand/"
  create_dir "$saves_path/n3ds/azahar/sdmc/"

  cp -fT "$component_config/qt-config.ini" "$azahar_config_path/qt-config.ini"

  set_setting_value "$azahar_qtconfig" "use_custom_storage" "true" "azahar"
  set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/nand/" "azahar"
  set_setting_value "$azahar_qtconfig" "sdmc_directory" "$saves_path/n3ds/azahar/sdmc/" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\gamedirs\3\path" "$roms_path/n3ds" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\screenshotPath" "$screenshots_path/Azahar" "azahar"

  dir_prep "$mods_path/Azahar/mods" "$azahar_mods_path"
  dir_prep "$texture_packs_path/Azahar/textures" "$azahar_textures_path"
  dir_prep "$shaders_path/Azahar/" "$azahar_shaders_path"
  dir_prep "$logs_path/Azahar/" "$azahar_logs_path"
  dir_prep "$cheats_path/Azahar/" "$azahar_cheats_path"
fi

if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"

  set_setting_value "$azahar_qtconfig" "use_custom_storage" "true" "azahar"
  set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/nand/" "azahar"
  set_setting_value "$azahar_qtconfig" "sdmc_directory" "$saves_path/n3ds/azahar/sdmc/" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\gamedirs\3\path" "$roms_path/n3ds" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\screenshotPath" "$screenshots_path/Azahar" "azahar"

  dir_prep "$mods_path/Azahar/mods" "$azahar_mods_path"
  dir_prep "$texture_packs_path/Azahar/textures" "$azahar_textures_path"
  dir_prep "$shaders_path/Azahar/" "$azahar_shaders_path"
  dir_prep "$logs_path/Azahar/" "$azahar_logs_path"
  dir_prep "$cheats_path/Azahar/" "$azahar_cheats_path"
fi
