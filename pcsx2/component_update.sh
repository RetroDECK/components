#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Update PCSX2 and Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
  # - Disable auto-save/load in existing RA / PCSX2 / Duckstation installs for proper preset functionality

  mv -f "$pcsx2conf" "$pcsx2conf.bak"
  generate_single_patch "$config/PCSX2/PCSX2.ini" "$pcsx2conf.bak" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" pcsx2
  deploy_single_patch "$config/PCSX2/PCSX2.ini" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" "$pcsx2conf"
  rm -f "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch"

  dir_prep "$texture_packs_path/pcsx2/textures" "$pcsx2_textures_path"

  set_setting_value "$pcsx2conf" "SaveStateOnShutdown" "false" "pcsx2" "EmuCore"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the cheats for PCSX2..."
  create_dir "$cheats_folder/pcsx2"
  set_setting_value "$pcsx2conf" "Cheats" "$cheats_folder/pcsx2" "Folders"
  tar --strip-components=1 -xzf "/app/retrodeck/cheats/pcsx2.tar.gz" -C "$cheats_folder/pcsx2" --overwrite && log i "Cheats for PCSX2 installed"
fi
