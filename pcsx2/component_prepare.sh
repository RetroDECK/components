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
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "Folders"

  ## Backups Old Cheats
  if [[ -d "$cheats_path/PCSX2" && "$(ls -A "$cheats_path/PCSX2")" ]]; then
    backup_file="$backups_path/cheats/PCSX2-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$cheats_path" PCSX2
    log i "PCSX2 cheats backed up to $backup_file"
  fi

  create_dir -d "$cheats_path/PCSX2"
  tar -xzf "$component_extras/pcsx2-cheats.tar.gz" -C "$cheats_path/PCSX2" --overwrite
  create_dir "$saves_path/ps2/pcsx2/memcards"
  create_dir "$states_path/ps2/pcsx2"
  dir_prep "$texture_packs_path/PCSX2/textures" "$pcsx2_textures_path"
  dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"
  dir_prep "$logs_path/PCSX2/" "$pcsx2_logs_path"
  dir_prep "$cheats_path/PCSX2/" "$pcsx2_cheats_path"
  dir_prep "$videos_path/PCSX2/" "$pcsx2_vidoes_path"

  ## Backups Mods / Patches
  if [[ -d "$mods_path/PCSX2" && "$(ls -A "$mods_path/PCSX2")" ]]; then
    backup_file="$backups_path/mods/PCSX2-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$mods_path" PCSX2
    log i "PCSX2 patches backed up to $backup_file"
  fi
  tar -xzf "$component_extras/pcsx2-patches.tar.gz" -C "$mods_path/PCSX2/patches" --overwrite

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
  set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/pcsx2" "Folders"
  dir_prep "$texture_packs_path/PCSX2/textures" "$pcsx2_textures_path"
  dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"
  dir_prep "$logs_path/PCSX2/" "$pcsx2_logs_path"
  dir_prep "$cheats_path/PCSX2/" "$pcsx2_cheats_path"
  dir_prep "$videos_path/PCSX2/" "$pcsx2_vidoes_path"
fi
