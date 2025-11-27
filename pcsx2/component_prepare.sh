#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"
component_extras="/app/retrodeck/components/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/PCSX2/inis"
  cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/PCSX2/inis/"
  set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/pcsx2" "Folders"
  if [[ -d "$cheats_path/pcsx2" && "$(ls -A "$cheats_path/pcsx2")" ]]; then
    backup_file="$backups_path/cheats/pcsx2-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$cheats_path" pcsx2
    log i "PCSX2 cheats backed up to $backup_file"
  fi
  create_dir -d "$cheats_path/pcsx2"
  tar -xzf "$component_extras/pcsx2-cheats.tar.gz" -C "$cheats_path/pcsx2" --overwrite
  create_dir "$saves_path/ps2/pcsx2/memcards"
  create_dir "$states_path/ps2/pcsx2"
  dir_prep "$texture_packs_path/pcsx2" "$XDG_CONFIG_HOME/PCSX2/textures"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/pcsx2" "Folders"
  dir_prep "$texture_packs_path/pcsx2" "$XDG_CONFIG_HOME/PCSX2/textures"
fi
