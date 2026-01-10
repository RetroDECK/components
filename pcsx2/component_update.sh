#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Update PCSX2 and Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
  # - Disable auto-save/load in existing RA / PCSX2 / Duckstation installs for proper preset functionality

  mv -f "$pcsx2_config" "$pcsx2_config.bak"
  generate_single_patch "$config/PCSX2/PCSX2.ini" "$pcsx2_config.bak" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" pcsx2
  deploy_single_patch "$config/PCSX2/PCSX2.ini" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" "$pcsx2_config"
  rm -f "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch"

  dir_prep "$texture_packs_path/PCSX2/textures" "$pcsx2_textures_path"

  set_setting_value "$pcsx2_config" "SaveStateOnShutdown" "false" "pcsx2" "EmuCore"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the cheats for PCSX2..."
  create_dir "$cheats_path/PCSX2"
  set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "Folders"
  tar --strip-components=1 -xzf "/app/retrodeck/cheats/pcsx2.tar.gz" -C "$cheats_path/PCSX2" --overwrite && log i "Cheats for PCSX2 installed"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  log i "0.10.0b Upgrade: PCSX2 - Postmove, mods and cheats and folder creation"

  create_dir -d "$screenshots_path/PCSX2"
  create_dir -d "$logs_path/PCSX2"
  create_dir -d "$cheats_path/PCSX2/cheats_ws"
  create_dir -d "$cheats_path/PCSX2/cheats_ni"
  move "$cheats_path/pcsx2" "$cheats_path/PCSX2"
  tar -xzf "$pcsx2_rd_extras_dir/pcsx2-cheats.tar.gz" -C "$cheats_path/PCSX2" --overwrite
  create_dir -d "$storage_path/PCSX2/covers"
  create_dir -d "$texture_packs_path/PCSX2/textures"
  create_dir -d "$videos_path/PCSX2"
  prepare_component "postmove" "pcsx2"
  tar -xzf "$pcsx2_rd_extras_dir/pcsx2-patches.tar.gz" -C "$mods_path/PCSX2/patches" --overwrite

  set_setting_value "$pcsx2_config" "Renderer" "-1" "pcsx2" "EmuCore/GS"
fi
