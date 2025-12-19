#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Copy new borders into RA config location
  # - Copy new RetroArch control remaps into RA config location
  # - Add shipped Amiga bios if it doesn't already exist
  # - Disable auto-save/load in existing RA / PCSX2 / Duckstation installs for proper preset functionality

  dir_prep "$texture_packs_path/retroarch/Mesen/HdPacks" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
  dir_prep "$texture_packs_path/retroarch/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
  dir_prep "$texture_packs_path/retroarch/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"

  dir_prep "$borders_path/retroarch/" "$XDG_CONFIG_HOME/retroarch/overlays/borders"
  rsync -rlD --mkpath "/app/retrodeck/config/retroarch/borders/" "$XDG_CONFIG_HOME/retroarch/overlays/borders/"

  rsync -rlD --mkpath "$config/retrodeck/presets/remaps/" "$XDG_CONFIG_HOME/retroarch/config/remaps/"

  if [[ ! -f "$bios_path/capsimg.so" ]]; then
    cp -f "/app/retrodeck/extras/Amiga/capsimg.so" "$bios_path/capsimg.so"
  fi

  set_setting_value "$raconf" "savestate_auto_load" "false" "retroarch"
  set_setting_value "$raconf" "savestate_auto_save" "false" "retroarch"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- Force disable global rewind in RA in prep for preset system"

  log i "Force disabling rewind, you can re-enable it via the Configurator"
  set_setting_value "$raconf" "rewind_enable" "false" "retroarch"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.1b") == "true" ]]; then
  log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

  log i "Installing the missing ScummVM assets and renaming \"$storage_path/retroarch/ScummVM/themes\" into \"theme\""
  mv -f "$storage_path/retroarch/ScummVM/themes" "$s/retroarch/ScummVM/themes"
  unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/extra/*' -d /tmp
  unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/theme/*' -d /tmp
  mv -f "/tmp/scummvm/extra" "$storage_path/retroarch/ScummVM/extra"
  mv -f "/tmp/scummvm/theme" "$storage_path/retroarch/ScummVM/theme"

  rm -rf "/tmp/extra /tmp/theme"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.0b") == "true" ]]; then
  log i "Forcing RetroArch to use the new libretro info path"
  set_setting_value "$raconf" "libretro_info_path" "$XDG_CONFIG_HOME/retroarch/cores" "retroarch"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the cheats for RetroArch..."
  create_dir "$cheats_path/retroarch"
  set_setting_value "$raconf" "cheat_database_path" "$cheats_path/retroarch" "retroarch"
  tar --strip-components=1 -xzf "/app/retrodeck/cheats/retroarch.tar.gz" -C "$cheats_path/retroarch" --overwrite && log i "Cheats for RetroArch installed"
fi

#######################################
# These actions happen at every update
#######################################

retroarch_updater
