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

  dir_prep "$texture_packs_folder/RetroArch-Mesen" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
  dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
  dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"

  dir_prep "$borders_folder" "$XDG_CONFIG_HOME/retroarch/overlays/borders"
  rsync -rlD --mkpath "/app/retrodeck/config/retroarch/borders/" "$XDG_CONFIG_HOME/retroarch/overlays/borders/"

  rsync -rlD --mkpath "$config/retrodeck/presets/remaps/" "$XDG_CONFIG_HOME/retroarch/config/remaps/"

  if [[ ! -f "$bios_folder/capsimg.so" ]]; then
    cp -f "/app/retrodeck/extras/Amiga/capsimg.so" "$bios_folder/capsimg.so"
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

  log i "Installing the missing ScummVM assets and renaming \"$mods_folder/RetroArch/ScummVM/themes\" into \"theme\""
  mv -f "$mods_folder/RetroArch/ScummVM/themes" "$mods_folder/RetroArch/ScummVM/theme"
  unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/extra/*' -d /tmp
  unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/theme/*' -d /tmp
  mv -f "/tmp/scummvm/extra" "$mods_folder/RetroArch/ScummVM"
  mv -f "/tmp/scummvm/theme" "$mods_folder/RetroArch/ScummVM"
  rm -rf "/tmp/extra /tmp/theme"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.0b") == "true" ]]; then
  log i "Forcing RetroArch to use the new libretro info path"
  set_setting_value "$raconf" "libretro_info_path" "$XDG_CONFIG_HOME/retroarch/cores" "retroarch"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the cheats for RetroArch..."
  create_dir "$cheats_folder/retroarch"
  set_setting_value "$raconf" "cheat_database_path" "$cheats_folder/retroarch" "retroarch"
  tar --strip-components=1 -xzf "/app/retrodeck/cheats/retroarch.tar.gz" -C "$cheats_folder/retroarch" --overwrite && log i "Cheats for RetroArch installed"
fi

#######################################
# These actions happen at every update
#######################################

retroarch_updater
