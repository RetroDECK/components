#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"
component_extras="/app/retrodeck/components/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  # General Folders
  create_dir -d "$XDG_CONFIG_HOME/PCSX2/inis"
  cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/PCSX2/inis"
  set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"

  # Screenshots
  create_dir -d "$screenshots_path/PCSX2"
  set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path/PCSX2" "pcsx2" "Folders"

  # Saves
  create_dir "$states_path/ps2/pcsx2"
  set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
  create_dir "$saves_path/ps2/pcsx2/memcards"
  set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"

  # Logs
  create_dir -d "$logs_path/PCSX2"
  set_setting_value "$pcsx2_config" "Logs" "$logs_path/PCSX2/" "pcsx2" "Folders"

  # Cheats
  create_dir -d "$cheats_path/PCSX2/cheats_ws"
  create_dir -d "$cheats_path/PCSX2/cheats_ni"
  tar -xzf "$component_extras/pcsx2-cheats.tar.gz" -C "$cheats_path/PCSX2" --overwrite
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "Folders"
  set_setting_value "$pcsx2_config" "CheatsWS" "$cheats_path/PCSX2/cheats_ws" "Folders"
  set_setting_value "$pcsx2_config" "CheatsNI" "$cheats_path/PCSX2/cheats_ni" "Folders"

  # Covers
  create_dir -d "$storage_path/PCSX2/covers"
  set_setting_value "$pcsx2_config" "Covers" "$storage_path/PCSX2/covers" "Folders"

  # Textures
  create_dir -d "$texture_packs_path/PCSX2/textures"
  set_setting_value "$pcsx2_config" "Textures" "$texture_packs_path/PCSX2/textures" "Folders"

  # Textures
  create_dir -d "$videos_path/PCSX2/"
  set_setting_value "$pcsx2_config" "Videos" "$videos_path/PCSX2/" "Folders"

  # Mods
  dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"

  ## Backups Old Cheats
  if [[ -d "$cheats_path/PCSX2" && "$(ls -A "$cheats_path/PCSX2")" ]]; then
    backup_file="$backups_path/cheats/PCSX2-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$cheats_path" PCSX2
    log i "PCSX2 cheats backed up to $backup_file"
  fi

  ## Backups Mods / Patches
  if [[ -d "$mods_path/PCSX2" && "$(ls -A "$mods_path/PCSX2")" ]]; then
    backup_file="$backups_path/mods/PCSX2-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$mods_path/PCSX2" PCSX2
    log i "PCSX2 patches backed up to $backup_file"
  fi
  tar -xzf "$component_extras/pcsx2-patches.tar.gz" -C "$mods_path/PCSX2/patches" --overwrite

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"

  set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"
  set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path/PCSX2" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "Logs" "$logs_path/PCSX2/" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "Folders"
  set_setting_value "$pcsx2_config" "CheatsWS" "$cheats_path/PCSX2/cheats_ws" "Folders"
  set_setting_value "$pcsx2_config" "CheatsNI" "$cheats_path/PCSX2/cheats_ni" "Folders"
  set_setting_value "$pcsx2_config" "Covers" "$storage_path/PCSX2/covers" "Folders"
  set_setting_value "$pcsx2_config" "Textures" "$texture_packs_path/PCSX2/textures" "Folders"
  set_setting_value "$pcsx2_config" "Videos" "$videos_path/PCSX2/" "Folders"
  dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"
fi
