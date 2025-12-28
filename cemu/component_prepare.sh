#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/Cemu/"
  cp -fr "$component_config/"* "$XDG_CONFIG_HOME/Cemu/"
  set_setting_value "$cemu_config" "mlc_path" "$bios_path/cemu" "cemu"
  set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"
  if [[ -e "$bios_path/cemu/keys.txt" ]]; then
    rm -rf "$XDG_DATA_HOME/Cemu/keys.txt" && ln -s "$bios_path/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt" && log d "Linked $bios_path/cemu/keys.txt to $XDG_DATA_HOME/Cemu/keys.txt"
  fi
  dir_prep "$saves_path/wiiu/cemu" "$bios_path/cemu/usr/save"
  dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
  dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"
  
fi
if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"
  
  set_setting_value "$cemu_config" "mlc_path" "$bios_path/cemu" "cemu"
  set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"
  dir_prep "$saves_path/wiiu/cemu" "$bios_path/cemu/usr/save"
  dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
  dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"
fi
