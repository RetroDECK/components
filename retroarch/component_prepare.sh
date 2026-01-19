#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
component_config="$component_path/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "--------------------------------"
  log i "Resetting $component_name"
  log i "--------------------------------"

  create_dir -d "$XDG_CONFIG_HOME/retroarch"
  dir_prep "$bios_path" "$XDG_CONFIG_HOME/retroarch/system"
  dir_prep "$logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
  if [[ -d "$cheats_path/retroarch" && "$(ls -A "$cheats_path/retroarch")" ]]; then
    backup_file="$backups_path/cheats/retroarch-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$cheats_path" retroarch
    log i "RetroArch cheats backed up to $backup_file"
  fi

  # Configure the Config
  cp -fv "$component_config/retroarch.cfg" "$retroarch_config"
  cp -fv "$component_config/retroarch-core-options.cfg" "$retroarch_config_core_options"
  rsync -rlD --mkpath "$component_config/core-overrides/" "$XDG_CONFIG_HOME/retroarch/config/"
  rsync -rlD --mkpath "$component_config/remaps/" "$XDG_CONFIG_HOME/retroarch/config/remaps/"
  set_setting_value "$retroarch_config" "savefile_directory" "$saves_path" "retroarch"
  set_setting_value "$retroarch_config" "savestate_directory" "$states_path" "retroarch"
  set_setting_value "$retroarch_config" "screenshot_directory" "$screenshots_path/retroarch" "retroarch"
  set_setting_value "$retroarch_config" "recording_output_directory" "$videos_path/retroarch" "retroarch"
  set_setting_value "$retroarch_config" "log_dir" "$logs_path" "retroarch"
  set_setting_value "$retroarch_config" "rgui_browser_directory" "$roms_path" "retroarch"
  set_setting_value "$retroarch_config" "cheat_database_path" "$cheats_path/retroarch" "retroarch"
  set_setting_value "$retroarch_config" "assets_directory" "$component_path/assets" "retroarch"
  set_setting_value "$retroarch_config" "joypad_autoconfig_dir" "$component_path/autoconfig" "retroarch"
  set_setting_value "$retroarch_config" "cursor_directory" "$component_path/database/cursors" "retroarch"
  set_setting_value "$retroarch_config" "content_database_path" "$component_path/database/rdb" "retroarch"
  set_setting_value "$retroarch_config" "libretro_directory" "$retroarch_extras_path/cores" "retroarch"
  set_setting_value "$retroarch_config" "libretro_info_path" "$retroarch_extras_path/cores" "retroarch"

  # Video
  create_dir "$videos_path/retroarch"

  # BIOS Directories
  create_dir "$bios_path/np2kai"
  create_dir "$bios_path/dc"
  create_dir "$bios_path/Mupen64plus"
  create_dir "$bios_path/quasi88"

  # BIOS MAME Directories
  create_dir "$bios_path/mame2003/samples"
  create_dir "$bios_path/mame2003/artwork"
  create_dir "$bios_path/mame2003-plus/samples"
  create_dir "$bios_path/mame2003-plus/artwork"
  create_dir "$bios_path/mame2010/samples"
  create_dir "$bios_path/mame2010/artwork"
  create_dir "$bios_path/mame2010/crosshairs"
  create_dir "$bios_path/mame2010/fonts"

  # MAME 2003 Plus BIOS Files

  if [[ -d "$bios_path/mame2003-plus" && "$(ls -A "$bios_path/mame2003-plus")" ]]; then
    backup_file="$backups_path/bios/mame2003-plus-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$bios_path/mame2003-plus" retroarch
    log i "MAME 2003-Plus BIOS data backed up to $backup_file"
  fi
  tar -xzf "$retroarch_extras_path/mame2003-plus.tar.gz" -C "$bios_path/mame2003-plus" --overwrite

  retroarch_updater

  # Avoid these paths being clobbered by the updater
  dir_prep "$borders_path/retroarch/" "$XDG_CONFIG_HOME/retroarch/overlays/borders"
  log d "Linking shaders folder to ensure retroarch can find it $XDG_CONFIG_HOME/retroarch/shaders to $shaders_path/retroarch"
  dir_prep "$shaders_path/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"
  ln -s "$retroarch_extras_path/cores" "$XDG_CONFIG_HOME/retroarch/cores" # Link RO cores to RA config dir so ES-DE can find it
  
  # FBNEO
  log i "--------------------------------"
  log i "Preparing FBNEO_LIBRETRO"
  log i "--------------------------------"
  create_dir "$bios_path/fbneo/samples"
  dir_prep "$cheats_path/retroarch-core/fbneo" "$bios_path/fbneo/cheats"
  dir_prep "$shaders_path/retroarch-core/fbneo/blend" "$bios_path/fbneo/blend"
  dir_prep "$mods_path/retroarch-core/fbneo/patched" "$bios_path/fbneo/patched"
  dir_prep "$mods_path/retroarch-core/fbneo/ips" "$bios_path/fbneo/ips"
  dir_prep "$mods_path/retroarch-core/fbneo/romdata" "$bios_path/fbneo/romdata"

  # MSX / SVI / ColecoVision / SG-1000
  log i "-----------------------------------------------------------"
  log i "Preparing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
  log i "-----------------------------------------------------------"
  log i "Copying \"$retroarch_extras_path/MSX/Databases\" in \"$bios_path/Databases\""
  cp -rf "$retroarch_extras_path/MSX/Databases" "$bios_path/Databases"
  log i "Copying \"$retroarch_extras_path/MSX/Machines\" in \"$bios_path/Machines\""
  cp -rf "$retroarch_extras_path/MSX/Machines" "$bios_path/Machines"

  # AMIGA
  log i "-----------------------------------------------------------"
  log i "Prepearing AMIGA LIBRETRO"
  log i "-----------------------------------------------------------"
  log i "Copying \"$retroarch_extras_path/Amiga/capsimg.so\" in \"$bios_path/capsimg.so\""
  cp -f "$retroarch_extras_path/Amiga/capsimg.so" "$bios_path/capsimg.so"

  # ScummVM
  log i "-----------------------------------------------------------"
  log i "Prepearing ScummVM LIBRETRO"
  log i "-----------------------------------------------------------"
  cp -fv "$component_config/scummvm.ini" "$retroarch_config_scummvm"
  log i "Installing ScummVM assets"
  unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/extra/*' -d /tmp
  unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/theme/*' -d /tmp
  create_dir "$storage_path/retroarch/ScummVM/icons"
  create_dir "$storage_path/retroarch/ScummVM/extra"
  create_dir "$storage_path/retroarch/ScummVM/theme"
  mv -f /tmp/scummvm/extra/* "$storage_path/retroarch/ScummVM/extra"
  mv -f /tmp/scummvm/theme/* "$storage_path/retroarch/ScummVM/theme"
  rm -rf /tmp/extra /tmp/theme /tmp/scummvm/extra /tmp/scummvm/theme
  set_setting_value "$retroarch_config_scummvm" "iconspath" "$storage_path/retroarch/ScummVM/icons" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "extrapath" "$storage_path/retroarch/ScummVM/extra" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "themepath" "$storage_path/retroarch/ScummVM/theme" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "savepath" "$saves_path/scummvm" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "browser_lastpath" "$roms_path/scummvm" "libretro_scummvm" "scummvm"

  # Texture Packs
  dir_prep "$texture_packs_path/retroarch-core/Mesen/HdPacks" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"
  dir_prep "$texture_packs_path/retroarch-core/Citra/textures" "$XDG_CONFIG_HOME/retroarch/saves/Citra/load/textures"
  dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$XDG_CONFIG_HOME/retroarch/saves/dolphin-emu/User/Load/Textures/"
  dir_prep "$texture_packs_path/retroarch-core/PPSSPP/TEXTURES" "$XDG_CONFIG_HOME/retroarch/saves/PPSSPP/PSP/TEXTURES"
  dir_prep "$texture_packs_path/retroarch-core/Flycast/textures" "$bios_path/dc/textures"

  # Mods
  dir_prep "$mods_path/retroarch-core/Citra/mods" "$XDG_CONFIG_HOME/retroarch/saves/Citra/load/mods"
  dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$XDG_CONFIG_HOME/retroarch/saves/dolphin-emu/User/Load/GraphicMods"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  log i "--------------------------------"
  log i "Post-moving $component_name"
  log i "--------------------------------"

  # ScummVM
  set_setting_value "$retroarch_config_scummvm" "iconspath" "$storage_path/retroarch/ScummVM/icons" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "extrapath" "$storage_path/retroarch/ScummVM/extra" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "themepath" "$storage_path/retroarch/ScummVM/theme" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "savepath" "$saves_path/scummvm" "libretro_scummvm" "scummvm"
  set_setting_value "$retroarch_config_scummvm" "browser_lastpath" "$roms_path/scummvm" "libretro_scummvm" "scummvm"

  # BIOS
  dir_prep "$bios_path" "$XDG_CONFIG_HOME/retroarch/system"

  # Logs
  dir_prep "$logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"

  # Texture Packs
  dir_prep "$texture_packs_path/retroarch-core/Mesen/HdPacks" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
  dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"
  dir_prep "$texture_packs_path/retroarch-core/Citra/textures" "$XDG_CONFIG_HOME/retroarch/saves/Citra/load/textures"
  dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$XDG_CONFIG_HOME/retroarch/saves/dolphin-emu/User/Load/Textures/"
  dir_prep "$texture_packs_path/retroarch-core/PPSSPP/TEXTURES" "$XDG_CONFIG_HOME/retroarch/saves/PPSSPP/PSP/TEXTURES"
  dir_prep "$texture_packs_path/retroarch-core/Flycast/textures" "$bios_path/dc/textures"

  # Cheats
  dir_prep "$cheats_path/retroarch-core/fbneo" "$bios_path/fbneo/cheats"

  # Shaders
  dir_prep "$shaders_path/retroarch-core/fbneo/blend" "$bios_path/fbneo/blend"
  dir_prep "$shaders_path/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"

  # Mods
  dir_prep "$mods_path/retroarch-core/Citra/mods" "$XDG_CONFIG_HOME/retroarch/saves/Citra/load/mods"
  dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$XDG_CONFIG_HOME/retroarch/saves/dolphin-emu/User/Load/GraphicMods"
  dir_prep "$mods_path/retroarch-core/fbneo/patched" "$bios_path/fbneo/patched"
  dir_prep "$mods_path/retroarch-core/fbneo/ips" "$bios_path/fbneo/ips"
  dir_prep "$mods_path/retroarch-core/fbneo/romdata" "$bios_path/fbneo/romdata"

  # Settings
  set_setting_value "$retroarch_config" "savefile_directory" "$saves_path" "retroarch"
  set_setting_value "$retroarch_config" "savestate_directory" "$states_path" "retroarch"
  set_setting_value "$retroarch_config" "screenshot_directory" "$screenshots_path/retroarch" "retroarch"
  set_setting_value "$retroarch_config" "recording_output_directory" "$videos_path/retroarch" "retroarch"
  set_setting_value "$retroarch_config" "log_dir" "$logs_path" "retroarch"
  set_setting_value "$retroarch_config" "rgui_browser_directory" "$roms_path" "retroarch"
  set_setting_value "$retroarch_config" "cheat_database_path" "$cheats_path/retroarch" "retroarch"
fi
