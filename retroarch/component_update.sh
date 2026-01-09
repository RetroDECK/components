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

  dir_prep "$texture_packs_path/retroarch-core/Mesen/HdPacks" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"

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

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  log i "0.10.0b Upgrade - Postmove: RetroArch, Folder Creation, MAME2003+ Asset files"

  create_dir "$videos_path/retroarch"
  create_dir "$bios_path/np2kai"
  create_dir "$bios_path/dc"
  create_dir "$bios_path/Mupen64plus"
  create_dir "$bios_path/quasi88"
  create_dir "$bios_path/fbneo/samples"
  create_dir "$bios_path/mame2003/samples"
  create_dir "$bios_path/mame2003/artwork"
  create_dir "$bios_path/mame2003-plus/samples"
  create_dir "$bios_path/mame2003-plus/artwork"
  create_dir "$bios_path/mame2010/samples"
  create_dir "$bios_path/mame2010/artwork"
  create_dir "$bios_path/mame2010/crosshairs"
  create_dir "$bios_path/mame2010/fonts"
  tar -xzf "$retroarch_extras_path/mame2003-plus.tar.gz" -C "$bios_path/mame2003-plus" --overwrite

  prepare_component "postmove" "retroarch"

  set_setting_value "$retroarch_config" "assets_directory" "/app/retrodeck/components/retroarch/assets" "retroarch"
  set_setting_value "$retroarch_config" "audio_filter_dir" "/app/retrodeck/components/retroarch/filters/audio" "retroarch"
  set_setting_value "$retroarch_config" "content_database_path" "/app/retrodeck/components/retroarch/database/rdb" "retroarch"
  set_setting_value "$retroarch_config" "cursor_directory" "/app/retrodeck/components/retroarch/database/cursors" "retroarch"
  set_setting_value "$retroarch_config" "joypad_autoconfig_dir" "/app/retrodeck/components/retroarch/autoconfig" "retroarch"
  set_setting_value "$retroarch_config" "libretro_directory" "$retroarch_extras_path/cores" "retroarch"
  set_setting_value "$retroarch_config" "libretro_info_path" "$retroarch_extras_path/cores" "retroarch"
  set_setting_value "$retroarch_config" "video_filter_dir" "/app/retrodeck/components/retroarch/filters/video" "retroarch"

  move "$texture_packs_path/RetroArch-Mesen" "$texture_packs_path/retroarch-core/Mesen"
  move "$texture_packs_path/RetroArch-Mupen64Plus" "$texture_packs_path/retroarch-core/Mupen64Plus"
fi

#######################################
# These actions happen at every update
#######################################

retroarch_updater
