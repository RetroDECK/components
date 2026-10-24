#!/bin/bash

export retroarch_config="$XDG_CONFIG_HOME/retroarch/retroarch.cfg"
export retroarch_config_core_options="$XDG_CONFIG_HOME/retroarch/retroarch-core-options.cfg"
export retroarch_config_scummvm="$bios_path/scummvm.ini"
export retroarch_cores_path="$XDG_CONFIG_HOME/retroarch/cores"
export retroarch_extras_path="$rd_components/retroarch/rd_extras"
export retroarch_rd_config_dir="$rd_components/retroarch/rd_config"

_set_setting_value::retroarch() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  sed -i 's^\^'"$name"' = ".*"^'"$name"' = "'"$value"'"^' "$file"
}

_get_setting_value::retroarch() {
  local file="$1" name="$2"
  KEY="$name" awk -F'=' \
    'BEGIN { key=ENVIRON["KEY"] }
     index($0, key " =") == 1 {
       val=substr($0, index($0,"=")+2)
       gsub(/^"|"$/, "", val)
       print val; exit
     }' "$file"
}

_add_setting::retroarch() {
  local file="$1" name="$2" value="$3"
  local token ref_val calculated_value ref_resolution ref_w ref_h

  if [[ "$value" == *:* ]]; then
    token="${value%%:*}"
    ref_val="${value#*:}"

    case "$token" in
      pixel_w|pixel_h|ar_adjust|overlay_scale)
        ref_resolution="$(jq -r '.[] | .manifest | .retroarch.preset_variables.borders_ref_resolution // empty' "$component_manifest_cache_file")"
        ref_w="${ref_resolution%%x*}"
        ref_h="${ref_resolution##*x}"

        case "$token" in
          pixel_w)
            calculated_value="$(awk "BEGIN { printf \"%d\", int($ref_val * $system_display_width / $ref_w + 0.5) }")"
            ;;
          pixel_h)
            calculated_value="$(awk "BEGIN { printf \"%d\", int($ref_val * $system_display_height / $ref_h + 0.5) }")"
            ;;
          ar_adjust)
            calculated_value="$(awk "BEGIN { printf \"%.6f\", (1 + $ref_val) * ($ref_w / $ref_h) / ($system_display_width / $system_display_height) - 1 }")"
            ;;
          overlay_scale)
            calculated_value="$ref_val"
            ;;
        esac
        value="$calculated_value"
        ;;
      esac
  fi

  sed -i '$ a '"$name"' = "'"$value"'"' "$file"
}

_delete_setting::retroarch() {
  local file="$1" name="$2"
  sed -i '\^'"$name"'^d' "$file"
  sed -i '/^$/d' "$file" # Cleanup empty lines left behind
}

_set_setting_value::retroarch_scummvm() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  sed -i 's^\^'"$name"'=.*^'"$name"'='"$value"'^' "$file"
}

_get_setting_value::retroarch_scummvm() {
  local file="$1" name="$2" section="${3:-}"
  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key "=") == 1 {
         print substr($0, index($0,"=")+1); exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"] }
       index($0, key "=") == 1 {
         print substr($0, index($0,"=")+1); exit
       }' "$file"
  fi
}

_prepare_component::retroarch() {
  local action="$1"
  shift

  local component_path="$(get_own_component_path)"
  local component_config="$component_path/rd_config"
  

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting RetroArch"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/retroarch"
      dir_prep "$logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
      if [[ -d "$cheats_path/retroarch" && "$(ls -A "$cheats_path/retroarch")" ]]; then
        backup_file="$backups_path/cheats/retroarch-$(date +%y%m%d).tar.gz"
        create_dir "$(dirname "$backup_file")"
        tar -czf "$backup_file" -C "$cheats_path" retroarch
        log i "RetroArch cheats backed up to $backup_file"
      fi

      log i "--------------------------------"
      log i "Preparing RetroArch Config Settings"
      log i "--------------------------------"

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
      set_setting_value "$retroarch_config" "audio_filter_dir" "$shaders_path/retroarch/filters/audio" "retroarch"
      set_setting_value "$retroarch_config" "video_filter_dir" "$shaders_path/retroarch/filters/video" "retroarch"
      set_setting_value "$retroarch_config" "video_shader_dir" "$shaders_path/retroarch/shaders" "retroarch"
      set_setting_value "$retroarch_config" "overlay_directory" "$borders_path/retroarch" "retroarch"
      set_setting_value "$retroarch_config" "system_directory" "$bios_path" "retroarch"

      if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        log d "Wayland compositor detected, changing rendered to OpenGL as a workaround"
        set_setting_value "$retroarch_config" "video_driver" "gl" "retroarch"
      fi

      log i "--------------------------------"
      log i "Preparing RetroArch Extra Directories"
      log i "--------------------------------"

      # Video
      create_dir "$videos_path/retroarch"

      # BIOS Directories
      create_dir "$bios_path/np2kai"
      create_dir "$bios_path/quasi88"
      create_dir "$bios_path/same_cdi/bios"

      log i "-----------------------------------------------------------"
      log i "Preparing RetroArch Cores"
      log i "-----------------------------------------------------------"

      # AMIGA
      log i "-----------------------------------------------------------"
      log i "Prepearing AMIGA LIBRETRO"
      log i "-----------------------------------------------------------"

      log i "Copying \"$retroarch_extras_path/Amiga/capsimg.so\" in \"$bios_path/capsimg.so\""
      cp -f "$retroarch_extras_path/Amiga/capsimg.so" "$bios_path/capsimg.so"

      # Amiberry core is hardcoded and looks for it in $bios_path/amiga/
      cp -f "$retroarch_extras_path/Amiga/capsimg.so" "$bios_path/amiga/capsimg.so"

      # Azahar
      log i "-----------------------------------------------------------"
      log i "Prepearing Azahar LIBRETRO"
      log i "-----------------------------------------------------------"    

      dir_prep "$texture_packs_path/retroarch-core/Azahar/textures" "$saves_path/n3ds/Azahar/load/textures"
      dir_prep "$mods_path/retroarch-core/Azahar/mods" "$saves_path/n3ds/Azahar/load/mods"
      dir_prep "$shaders_path/retroarch-core/Azahar/shaders" "$saves_path/n3ds/Azahar/shaders"
      dir_prep "$cheats_path/retroarch-core/Azahar/cheats" "$saves_path/n3ds/Azahar/cheats"

      # Citra
      log i "-----------------------------------------------------------"
      log i "Prepearing Citra LIBRETRO"
      log i "-----------------------------------------------------------"    

      dir_prep "$mods_path/retroarch-core/Citra/mods" "$saves_path/n3ds/Citra/load/mods"
      dir_prep "$texture_packs_path/retroarch-core/Citra/textures" "$saves_path/n3ds/Citra/load/textures"
      dir_prep "$shaders_path/retroarch-core/Citra/shaders" "$saves_path/n3ds/Citra/shaders"
      dir_prep "$cheats_path/retroarch-core/Citra/cheats" "$saves_path/n3ds/Citra/cheats"

      # Cemu
      log i "-----------------------------------------------------------"
      log i "Prepearing Cemu LIBRETRO"
      log i "-----------------------------------------------------------"    

      dir_prep "$texture_packs_path/retroarch-core/Cemu/graphicPacks" "$bios_path/Cemu/graphicPacks"
      dir_prep "$shaders_path/retroarch-core/Cemu/transferable" "$bios_path/Cemu/shaderCache/transferable"

      # Dolphin
      log i "-----------------------------------------------------------"
      log i "Prepearing Dolphin LIBRETRO"
      log i "-----------------------------------------------------------"     

      # Filestructure is Generated both in GC and Wii linked to the same source

      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/gc/User/Load/Textures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/wii/User/Load/Textures"

      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/gc/User/Load/DynamicInputTextures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/wii/User/Load/DynamicInputTextures"

      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/gc/User/Load/GraphicMods"
      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/wii/User/Load/GraphicMods"

      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/gc/User/Shaders"
      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/wii/User/Shaders"

      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/gc/User/Dump"
      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/wii/User/Dump"

      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/gc/User/Dump"
      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/wii/User/Dump"

      ### These are the NON RA States function, built into the Dolphin core.
      dir_prep "$states_path/gc/retroarch-core/Dolphin/StateSave" "$saves_path/gc/User/StateSaves"
      dir_prep "$states_path/wii/retroarch-core/Dolphin/StateSave" "$saves_path/wii/User/StateSaves"

      ### These are the NON RA Screenshot function, built into the Dolphin core.
      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/gc/ScreenShots" "$saves_path/gc/User/ScreenShots"
      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/wii/ScreenShots" "$saves_path/wii/User/ScreenShots"

      # ECWOLF
      log i "--------------------------------"
      log i "Preparing ECWOLF LIBRETRO"
      log i "--------------------------------"

      cp -f "$retroarch_extras_path/ecwolf.pk3" "$bios_path/ecwolf.pk3"

      # Flycast
      log i "-----------------------------------------------------------"
      log i "Prepearing Flycast LIBRETRO"
      log i "-----------------------------------------------------------"    

      create_dir "$bios_path/dc"
      dir_prep "$texture_packs_path/retroarch-core/Flycast/textures" "$bios_path/dc/textures"

      # Flycast VMUs
      mkdir -p "$saves_path/dreamcast/flycast_libretro"
      if [ -d "$bios_path/dc" ]; then
        for vmu_file in vmu_save_A1.bin vmu_save_A2.bin vmu_save_B1.bin vmu_save_B2.bin vmu_save_C1.bin vmu_save_C2.bin vmu_save_D1.bin vmu_save_D2.bin; do
          if [ ! -L "$bios_path/dc/$vmu_file" ]; then # if file is not a symlink, move it to the new location
            mv -f "$bios_path/dc/$vmu_file" "$saves_path/dreamcast/flycast_libretro/$vmu_file"
            ln -s "$saves_path/dreamcast/flycast_libretro/$vmu_file" "$bios_path/dc/$vmu_file"
          fi
        done
      fi

      # FBNEO
      log i "--------------------------------"
      log i "Preparing FBNEO LIBRETRO"
      log i "--------------------------------"

      create_dir "$bios_path/fbneo/samples"
      cp -f "$retroarch_extras_path/fbneo/hiscore.dat" "$bios_path/fbneo/hiscore.dat"

      dir_prep "$cheats_path/retroarch-core/fbneo" "$bios_path/fbneo/cheats"
      dir_prep "$shaders_path/retroarch-core/fbneo/blend" "$bios_path/fbneo/blend"
      dir_prep "$mods_path/retroarch-core/fbneo/patched" "$bios_path/fbneo/patched"
      dir_prep "$mods_path/retroarch-core/fbneo/ips" "$bios_path/fbneo/ips"
      dir_prep "$mods_path/retroarch-core/fbneo/romdata" "$bios_path/fbneo/romdata"

      # MAME
      log i "--------------------------------"
      log i "Preparing MAME LIBRETRO"
      log i "--------------------------------"

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
        tar -czf "$backup_file" -C "$bios_path" mame2003-plus
        log i "MAME 2003-Plus BIOS data backed up to $backup_file"
      fi
      tar -xzf "$retroarch_extras_path/mame2003-plus.tar.gz" -C "$bios_path/mame2003-plus" --overwrite

      retroarch_updater

      # Avoid these paths being clobbered by the updater
      ln -s "$retroarch_extras_path/cores" "$XDG_CONFIG_HOME/retroarch/cores" # Link RO cores to RA config dir so ES-DE can find it
      dir_prep "$borders_path/retroarch/overlays" "$XDG_CONFIG_HOME/retroarch/overlays"

      # Mesen
      log i "-----------------------------------------------------------"
      log i "Prepearing Mesen LIBRETRO"
      log i "-----------------------------------------------------------"    

      dir_prep "$texture_packs_path/retroarch-core/Mesen/HdPacks" "$bios_path/HdPacks"

      # Mupen64Plus
      log i "-----------------------------------------------------------"
      log i "Prepearing Mupen64Plus LIBRETRO"
      log i "-----------------------------------------------------------"  

      create_dir "$bios_path/Mupen64plus"
      dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/cache" "$bios_path/Mupen64plus/cache"
      dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/hires_texture" "$bios_path/Mupen64plus/hires_texture"

      # MSX / SVI / ColecoVision / SG-1000
      log i "-----------------------------------------------------------"
      log i "Preparing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
      log i "-----------------------------------------------------------"
    
      log i "Copying \"$retroarch_extras_path/MSX/Databases\" in \"$bios_path/Databases\""
      cp -rfv "$retroarch_extras_path/MSX/Databases" "$bios_path/Databases"

      log i "Copying \"$retroarch_extras_path/MSX/Machines\" in \"$bios_path/Machines\""
      cp -rfv "$retroarch_extras_path/MSX/Machines" "$bios_path/Machines"


      # PCSX Redux
      log i "-----------------------------------------------------------"
      log i "Prepearing PCSX Redux Openbios"
      log i "-----------------------------------------------------------"

      cp -f "$retroarch_extras_path/pcsx-redux/openbios.bin" "$bios_path/openbios.bin"

      # PCSX2, LRPS2, PCEE2
      log i "--------------------------------"
      log i "Preparing PCSX2, LRPS2, PCEE2 LIBRETRO"
      log i "--------------------------------"

      dir_prep "$bios_path" "$bios_path/pcsx2/bios"
      dir_prep "$saves_path/ps2/pcsx2/memcards" "$bios_path/pcsx2/memcards"
      dir_prep "$storage_path/retroarch-core/pcsx2/inis" "$bios_path/pcsx2/inis"
      dir_prep "$storage_path/retroarch-core/pcsx2/resources" "$bios_path/pcsx2/resources"
      dir_prep "$shaders_path/retroarch-core/pcsx2/shaders" "$bios_path/pcsx2/shaders"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats" "$bios_path/pcsx2/cheats"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ws" "$bios_path/pcsx2/cheats_ws"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ni" "$bios_path/pcsx2/cheats_ni"
      dir_prep "$texture_packs_path/retroarch-core/pcsx2/textures" "$bios_path/pcsx2/textures"

      cp -rfv "$retroarch_extras_path/pcsx2/resources" "$storage_path/retroarch-core/pcsx2/resources" 

      # PRBOOM
      log i "--------------------------------"
      log i "Preparing PRBOOM LIBRETRO"
      log i "--------------------------------"

      cp -f "$retroarch_extras_path/prboom.wad" "$bios_path/prboom.wad"

      # PPSSPP
      log i "-----------------------------------------------------------"
      log i "Prepearing PPSSPP LIBRETRO"
      log i "-----------------------------------------------------------"     

      dir_prep "$texture_packs_path/retroarch-core/PPSSPP/TEXTURES" "$saves_path/PSP/TEXTURES"
      dir_prep "$mods_path/retroarch-core/PPSSPP/PLUGINS" "$saves_path/PSP/PLUGINS"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/CACHE" "$saves_path/PSP/SYSTEM/CACHE"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/shaders" "$bios_path/PPSSPP/shaders"
      dir_prep "$storage_path/retroarch-core/PPSSPP/GAME" "$saves_path/PSP/GAME"

      ### Generally not used, uses RA Standard State function instead
      dir_prep "$states_path/PSP/PPSSPP/PPSSPP_STATE" "$saves_path/PSP/PPSSPP_STATE"

      # RPCS3
      log i "--------------------------------"
      log i "Preparing RPCS3 LIBRETRO"
      log i "--------------------------------"

      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd0" "$bios_path/rpcs3/dev_hdd0"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd1" "$bios_path/rpcs3/dev_hdd1"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash" "$bios_path/rpcs3/dev_flash"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash2" "$bios_path/rpcs3/dev_flash2"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash3" "$bios_path/rpcs3/dev_flash3"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_bdvd" "$bios_path/rpcs3/dev_bdvd"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_usb000" "$bios_path/rpcs3/dev_usb000"
      dir_prep "$storage_path/retroarch-core/rpcs3/captures" "$bios_path/rpcs3/captures"
      dir_prep "$storage_path/retroarch-core/rpcs3/patches" "$bios_path/rpcs3/patches"
      dir_prep "$saves_path/ps3/rpcs3/savedata" "$storage_path/retroarch-core/rpcs3/dev_hdd0/home/00000001/savedata"

      # ScummVM
      log i "-----------------------------------------------------------"
      log i "Prepearing ScummVM LIBRETRO"
      log i "-----------------------------------------------------------"

      cp -fv "$component_config/scummvm.ini" "$retroarch_config_scummvm"
      log i "Installing ScummVM assets"
      unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/extra/*' -d /tmp
      unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/theme/*' -d /tmp

      create_dir "$storage_path/retroarch-core/ScummVM/icons"
      create_dir "$storage_path/retroarch-core/ScummVM/extra"
      create_dir "$storage_path/retroarch-core/ScummVM/theme"
      mv -f /tmp/scummvm/extra/* "$storage_path/retroarch-core/ScummVM/extra"
      mv -f /tmp/scummvm/theme/* "$storage_path/retroarch-core/ScummVM/theme"
      rm -rf /tmp/extra /tmp/theme /tmp/scummvm/extra /tmp/scummvm/theme

      set_setting_value "$retroarch_config_scummvm" "iconspath" "$storage_path/retroarch-core/ScummVM/icons" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "extrapath" "$storage_path/retroarch-core/ScummVM/extra" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "themepath" "$storage_path/retroarch-core/ScummVM/theme" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "savepath" "$saves_path/scummvm" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "browser_lastpath" "$roms_path/scummvm" "retroarch_scummvm" "scummvm"

      # Supermodel
      log i "-----------------------------------------------------------"
      log i "Prepearing Supermodel LIBRETRO"
      log i "-----------------------------------------------------------"
      cp -f "$retroarch_extras_path/supermodel" "$bios_path/supermodel"

      # Vita3K
      log i "-----------------------------------------------------------"
      log i "Prepearing Vita3K LIBRETRO"
      log i "-----------------------------------------------------------"

      dir_prep "$storage_path/retroarch-core/Vita3K/ux0"  "$bios_path/vita3k/ux0"
      dir_prep "$storage_path/retroarch-core/Vita3K/data"  "$bios_path/vita3k/data"

      dir_prep "$saves_path/psvita/Vita3K/savedata" "$storage_path/retroarch-core/Vita3K/ux0/user/00/savedata"
      
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders-builtin" "$bios_path/vita3k/shaders-builtin"
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders"  "$bios_path/vita3k/shaders"

      dir_prep "$texture_packs_path/retroarch-core/Vita3K/textures" "$bios_path/vita3k/ux0/textures"

      # xemu
      log i "-----------------------------------------------------------"
      log i "Prepearing xemu LIBRETRO"
      log i "-----------------------------------------------------------"

      dir_prep "$shaders_path/retroarch-core/xemu/shaders" "$bios_path/xemu/xemu/shaders"
      create_dir "$saves_path/xbox/xemu" 

      ln -sfn "$bios_path/mcpx_1.0.bin" "$bios_path/xemu/mcpx_1.0.bin"
      ln -sfn "$bios_path/Complex_4627v1.03.bin" "$bios_path/xemu/Complex_4627v1.03.bin"
      ln -sfn "$saves_path/xbox/xemu/xbox_hdd.qcow2" "$bios_path/xemu/xbox_hdd.qcow2" 
      ln -sfn "$saves_path/xbox/xemu/xbox_eeprom.bin" "$bios_path/xemu/xbox_eeprom.bin"

      # Xenia Edge
      log i "-----------------------------------------------------------"
      log i "Prepearing Xenia Edge LIBRETRO"
      log i "-----------------------------------------------------------"

      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache" "$bios_path/Xenia-Edge/cache"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache0" "$bios_path/Xenia-Edge/cache0"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache1" "$bios_path/Xenia-Edge/cache1"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/library" "$bios_path/Xenia-Edge/library"

      dir_prep "$saves_path/xbox360/Xenia-Edge/content" "$bios_path/Xenia-Edge/content"

      dir_prep "$mods_path/retroarch-core/Xenia-Edge/plugins" "$bios_path/Xenia-Edge/plugins"
      dir_prep "$mods_path/retroarch-core/Xenia-Edge/patches" "$bios_path/Xenia-Edge/patches"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving RetroArch"
      log i "------------------------"

      # Azahar
      dir_prep "$texture_packs_path/retroarch-core/Azahar/textures" "$saves_path/n3ds/Azahar/load/textures"
      dir_prep "$mods_path/retroarch-core/Azahar/mods" "$saves_path/n3ds/Azahar/load/mods"
      dir_prep "$shaders_path/retroarch-core/Azahar/shaders" "$saves_path/n3ds/Azahar/shaders"
      dir_prep "$cheats_path/retroarch-core/Azahar/cheats" "$saves_path/n3ds/Azahar/cheats"

      # Citra
      dir_prep "$mods_path/retroarch-core/Citra/mods" "$saves_path/n3ds/Citra/load/mods"
      dir_prep "$texture_packs_path/retroarch-core/Citra/textures" "$saves_path/n3ds/Citra/load/textures"
      dir_prep "$shaders_path/retroarch-core/Citra/shaders" "$saves_path/n3ds/Citra/shaders"
      dir_prep "$cheats_path/retroarch-core/Citra/cheats" "$saves_path/n3ds/Citra/cheats"

      # Cemu
      dir_prep "$texture_packs_path/retroarch-core/Cemu/graphicPacks" "$bios_path/Cemu/graphicPacks"
      dir_prep "$shaders_path/retroarch-core/Cemu/transferable" "$bios_path/Cemu/shaderCache/transferable"

      # Dolphin
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/gc/User/Load/Textures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/wii/User/Load/Textures"

      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/gc/User/Load/DynamicInputTextures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/wii/User/Load/DynamicInputTextures"

      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/gc/User/Load/GraphicMods"
      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/wii/User/Load/GraphicMods"

      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/gc/User/Shaders"
      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/wii/User/Shaders"

      ### These are the NON RA States function, built into the Dolphin core.
      dir_prep "$states_path/gc/retroarch-core/Dolphin/StateSave" "$saves_path/gc/User/StateSaves"
      dir_prep "$states_path/wii/retroarch-core/Dolphin/StateSave" "$saves_path/wii/User/StateSaves"

      ### These are the NON RA Screenshot function, built into the Dolphin core.
      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/gc/ScreenShots" "$saves_path/gc/User/ScreenShots"
      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/wii/ScreenShots" "$saves_path/wii/User/ScreenShots"

      # Flycast
      dir_prep "$texture_packs_path/retroarch-core/Flycast/textures" "$bios_path/dc/textures"

      # FBNEO
      dir_prep "$cheats_path/retroarch-core/fbneo" "$bios_path/fbneo/cheats"
      dir_prep "$shaders_path/retroarch-core/fbneo/blend" "$bios_path/fbneo/blend"
      dir_prep "$mods_path/retroarch-core/fbneo/patched" "$bios_path/fbneo/patched"
      dir_prep "$mods_path/retroarch-core/fbneo/ips" "$bios_path/fbneo/ips"
      dir_prep "$mods_path/retroarch-core/fbneo/romdata" "$bios_path/fbneo/romdata"

      # MESEN
      dir_prep "$texture_packs_path/retroarch-core/Mesen/HdPacks" "$bios_path/HdPacks"

      # Mupen64Plus
      dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/cache" "$bios_path/Mupen64plus/cache"
      dir_prep "$texture_packs_path/retroarch-core/Mupen64Plus/hires_texture" "$bios_path/Mupen64plus/hires_texture"

      # ScummVM
      set_setting_value "$retroarch_config_scummvm" "iconspath" "$storage_path/retroarch-core/ScummVM/icons" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "extrapath" "$storage_path/retroarch-core/ScummVM/extra" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "themepath" "$storage_path/retroarch-core/ScummVM/theme" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "savepath" "$saves_path/scummvm" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "browser_lastpath" "$roms_path/scummvm" "retroarch_scummvm" "scummvm"

      # PCSX2, LRPS2, PCEE2
      dir_prep "$bios_path" "$bios_path/pcsx2/bios"
      dir_prep "$saves_path/ps2/pcsx2/memcards" "$bios_path/pcsx2/memcards"
      dir_prep "$storage_path/retroarch-core/pcsx2/inis" "$bios_path/pcsx2/inis"
      dir_prep "$storage_path/retroarch-core/pcsx2/resources" "$bios_path/pcsx2/resources"
      dir_prep "$shaders_path/retroarch-core/pcsx2/shaders" "$bios_path/pcsx2/shaders"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats" "$bios_path/pcsx2/cheats"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ws" "$bios_path/pcsx2/cheats_ws"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ni" "$bios_path/pcsx2/cheats_ni"
      dir_prep "$texture_packs_path/retroarch-core/pcsx2/textures" "$bios_path/pcsx2/textures"

      # PPSSPP
      dir_prep "$texture_packs_path/retroarch-core/PPSSPP/TEXTURES" "$saves_path/PSP/TEXTURES"
      dir_prep "$mods_path/retroarch-core/PPSSPP/PLUGINS" "$saves_path/PSP/PLUGINS"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/CACHE" "$saves_path/PSP/SYSTEM/CACHE"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/shaders" "$bios_path/PPSSPP/shaders"
      dir_prep "$storage_path/retroarch-core/PPSSPP/GAME" "$saves_path/PSP/GAME"
      dir_prep "$states_path/PSP/PPSSPP/PPSSPP_STATE" "$saves_path/PSP/PPSSPP_STATE"

      # RPCS3
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd0" "$bios_path/rpcs3/dev_hdd0"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd1" "$bios_path/rpcs3/dev_hdd1"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash" "$bios_path/rpcs3/dev_flash"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash2" "$bios_path/rpcs3/dev_flash2"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash3" "$bios_path/rpcs3/dev_flash3"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_bdvd" "$bios_path/rpcs3/dev_bdvd"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_usb000" "$bios_path/rpcs3/dev_usb000"
      dir_prep "$storage_path/retroarch-core/rpcs3/captures" "$bios_path/rpcs3/captures"
      dir_prep "$storage_path/retroarch-core/rpcs3/patches" "$bios_path/rpcs3/patches"
      dir_prep "$saves_path/ps3/rpcs3/savedata" "$storage_path/retroarch-core/rpcs3/dev_hdd0/home/00000001/savedata"

      # Vita3K
      dir_prep "$storage_path/retroarch-core/Vita3K/ux0"  "$bios_path/vita3k/ux0"
      dir_prep "$storage_path/retroarch-core/Vita3K/data"  "$bios_path/vita3k/data"
      dir_prep "$saves_path/psvita/Vita3K/savedata" "$storage_path/retroarch-core/Vita3K/ux0/user/00/savedata"
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders-builtin" "$bios_path/vita3k/shaders-builtin"
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders"  "$bios_path/vita3k/shaders"
      dir_prep "$texture_packs_path/retroarch-core/Vita3K/textures" "$bios_path/vita3k/ux0/textures"

      # xemu
      dir_prep "$shaders_path/retroarch-core/xemu/shaders" "$bios_path/xemu/xemu/shaders"

      ln -sfn "$bios_path/mcpx_1.0.bin" "$bios_path/xemu/mcpx_1.0.bin"
      ln -sfn "$bios_path/Complex_4627v1.03.bin" "$bios_path/xemu/Complex_4627v1.03.bin"
      ln -sfn "$saves_path/xbox/xemu/xbox_hdd.qcow2" "$bios_path/xemu/xbox_hdd.qcow2" 
      ln -sfn "$saves_path/xbox/xemu/xbox_eeprom.bin" "$bios_path/xemu/xbox_eeprom.bin"

      # Xenia Edge
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache" "$bios_path/Xenia-Edge/cache"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache0" "$bios_path/Xenia-Edge/cache0"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache1" "$bios_path/Xenia-Edge/cache1"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/library" "$bios_path/Xenia-Edge/library"
      dir_prep "$saves_path/xbox360/Xenia-Edge/content" "$bios_path/Xenia-Edge/content"
      dir_prep "$mods_path/retroarch-core/Xenia-Edge/plugins" "$bios_path/Xenia-Edge/plugins"
      dir_prep "$mods_path/retroarch-core/Xenia-Edge/patches" "$bios_path/Xenia-Edge/patches"

      # RetroArch Settings
      set_setting_value "$retroarch_config" "system_directory" "$bios_path" "retroarch"
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
      set_setting_value "$retroarch_config" "audio_filter_dir" "$shaders_path/retroarch/filters/audio" "retroarch"
      set_setting_value "$retroarch_config" "video_filter_dir" "$shaders_path/retroarch/filters/video" "retroarch"
      set_setting_value "$retroarch_config" "video_shader_dir" "$shaders_path/retroarch/shaders" "retroarch"
      set_setting_value "$retroarch_config" "overlay_directory" "$borders_path/retroarch" "retroarch"

      dir_prep "$logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"


    ;;

  esac
}

_post_update::retroarch() {
  local previous_version="$1"

  if check_version_is_older_than "$version_being_updated" "0.11.0"; then
    create_dir "$bios_path/same_cdi/bios"

    # Flycast VMUs migration: Move existing VMU files to the new saves location and create symlinks in the bios directory
    mkdir -p "$saves_path/dreamcast/flycast_libretro"
    if [ -d "$bios_path/dc" ]; then
      for vmu_file in vmu_save_A1.bin vmu_save_A2.bin vmu_save_B1.bin vmu_save_B2.bin vmu_save_C1.bin vmu_save_C2.bin vmu_save_D1.bin vmu_save_D2.bin; do
        if [ ! -L "$bios_path/dc/$vmu_file" ]; then # if file is not a symlink, move it to the new location
          mv -f "$bios_path/dc/$vmu_file" "$saves_path/dreamcast/flycast_libretro/$vmu_file"
          ln -s "$saves_path/dreamcast/flycast_libretro/$vmu_file" "$bios_path/dc/$vmu_file"
        fi
      done
    fi

  fi
  
  if check_version_is_older_than "$previous_version" "1.0.0"; then
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
      log d "Wayland compositor detected, changing rendered to OpenGL as a workaround"
      set_setting_value "$retroarch_config" "video_driver" "gl" "retroarch"
    fi
  fi

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Upgrade - RetroArch Conflict Mitigation and Core Dir Prepare"

      # PSX Open BIOS
      cp -f "$retroarch_extras_path/pcsx-redux/openbios.bin" "$bios_path/openbios.bin"

      # PS2 Cores
      create_dir "$saves_path/ps2/pcsx2/memcards"
      create_dir "$backups_path/0.11.0/retroarch-core/pcsx2/memcards"
      create_dir "$backups_path/0.11.0/retroarch-core/LRPS2/memcards"

      cp -rfv "$bios_path/pcsx2/memcards" "$backups_path/0.11.0/retroarch-core/pcsx2/memcards"
      cp -rfv "$saves_path/ps2/retroarch-core/LRPS2/memcards" "$backups_path/0.11.0/retroarch-core/LRPS2/memcards"

      cp -rfv "$bios_path/pcsx2/memcards" "$saves_path/ps2/pcsx2/memcards"
      cp -rfv "$saves_path/ps2/retroarch-core/LRPS2/memcards" "$saves_path/ps2/pcsx2/memcards"

      create_dir "$storage_path/retroarch-core/pcsx2/resources"
      cp -rfv "$retroarch_extras_path/pcsx2/resources" "$storage_path/retroarch-core/pcsx2/resources" 

      dir_prep "$bios_path" "$bios_path/pcsx2/bios"
      
      dir_prep "$saves_path/ps2/pcsx2/memcards" "$bios_path/pcsx2/memcards"
      dir_prep "$storage_path/retroarch-core/pcsx2/inis" "$bios_path/pcsx2/inis"
      dir_prep "$storage_path/retroarch-core/pcsx2/resources" "$bios_path/pcsx2/resources"
      dir_prep "$shaders_path/retroarch-core/pcsx2/shaders" "$bios_path/pcsx2/shaders"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats" "$bios_path/pcsx2/cheats"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ws" "$bios_path/pcsx2/cheats_ws"
      dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ni" "$bios_path/pcsx2/cheats_ni"
      dir_prep "$texture_packs_path/retroarch-core/pcsx2/textures" "$bios_path/pcsx2/textures"

      # RPCS3
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd0" "$bios_path/rpcs3/dev_hdd0"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_hdd1" "$bios_path/rpcs3/dev_hdd1"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash" "$bios_path/rpcs3/dev_flash"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash2" "$bios_path/rpcs3/dev_flash2"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_flash3" "$bios_path/rpcs3/dev_flash3"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_bdvd" "$bios_path/rpcs3/dev_bdvd"
      dir_prep "$storage_path/retroarch-core/rpcs3/dev_usb000" "$bios_path/rpcs3/dev_usb000"
      dir_prep "$storage_path/retroarch-core/rpcs3/captures" "$bios_path/rpcs3/captures"
      dir_prep "$storage_path/retroarch-core/rpcs3/patches" "$bios_path/rpcs3/patches"
      dir_prep "$saves_path/ps3/rpcs3/savedata" "$storage_path/retroarch-core/rpcs3/dev_hdd0/home/00000001/savedata"

      # N3DS Cores
      dir_prep "$mods_path/retroarch-core/Citra/mods" "$saves_path/n3ds/Citra/load/mods"
      dir_prep "$texture_packs_path/retroarch-core/Citra/textures" "$saves_path/n3ds/Citra/load/textures"
      dir_prep "$shaders_path/retroarch-core/Citra/shaders" "$saves_path/n3ds/Citra/shaders"
      dir_prep "$cheats_path/retroarch-core/Citra/cheats" "$saves_path/n3ds/Citra/cheats"

      dir_prep "$texture_packs_path/retroarch-core/Azahar/textures" "$saves_path/n3ds/Azahar/load/textures"
      dir_prep "$mods_path/retroarch-core/Azahar/mods" "$saves_path/n3ds/Azahar/load/mods"
      dir_prep "$shaders_path/retroarch-core/Azahar/shaders" "$saves_path/n3ds/Azahar/shaders"
      dir_prep "$cheats_path/retroarch-core/Azahar/cheats" "$saves_path/n3ds/Azahar/cheats"

      # PPSSPP
      dir_prep "$texture_packs_path/retroarch-core/PPSSPP/TEXTURES" "$saves_path/PSP/TEXTURES"
      dir_prep "$mods_path/retroarch-core/PPSSPP/PLUGINS" "$saves_path/PSP/PLUGINS"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/CACHE" "$saves_path/PSP/SYSTEM/CACHE"
      dir_prep "$shaders_path/retroarch-core/PPSSPP/shaders" "$bios_path/PPSSPP/shaders"
      dir_prep "$storage_path/retroarch-core/PPSSPP/GAME" "$saves_path/PSP/GAME"
      dir_prep "$states_path/PSP/PPSSPP/PPSSPP_STATE" "$saves_path/PSP/PPSSPP_STATE"

      # Dolphin Wii + GC
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/gc/User/Load/Textures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/Textures" "$saves_path/wii/User/Load/Textures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/gc/User/Load/DynamicInputTextures"
      dir_prep "$texture_packs_path/retroarch-core/Dolphin/DynamicInputTextures" "$saves_path/wii/User/Load/DynamicInputTextures"
      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/gc/User/Load/GraphicMods"
      dir_prep "$mods_path/retroarch-core/Dolphin/GraphicMods" "$saves_path/wii/User/Load/GraphicMods"
      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/gc/User/Shaders"
      dir_prep "$shaders_path/retroarch-core/Dolphin/Shaders" "$saves_path/wii/User/Shaders"
      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/gc/User/Dump"
      dir_prep "$storage_path/retroarch-core/Dolphin/Dump" "$saves_path/wii/User/Dump"     

      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/gc/ScreenShots" "$saves_path/gc/User/ScreenShots"      ### NON Standard Screenshots
      dir_prep "$screenshots_path/retroarch/retroarch-core/Dolphin/wii/ScreenShots" "$saves_path/wii/User/ScreenShots"

      dir_prep "$states_path/gc/retroarch-core/Dolphin/StateSaves" "$saves_path/gc/User/StateSaves"     ### NON Standard Savestates, most likely not used.
      dir_prep "$states_path/wii/retroarch-core/Dolphin/StateSaves" "$saves_path/wii/User/StateSaves"

      cp -rfv "$saves_path/gc/User/StateSaves" "$states_path/gc/retroarch-core/Dolphin/StateSaves"
      cp -rfv "$saves_path/wii/User/StateSaves" "$states_path/wii/retroarch-core/Dolphin/StateSaves"
      
      # Cemu
      dir_prep "$texture_packs_path/retroarch-core/Cemu/graphicPacks" "$bios_path/Cemu/graphicPacks"
      dir_prep "$shaders_path/retroarch-core/Cemu/transferable" "$bios_path/Cemu/shaderCache/transferable"

      # Vita3K
      dir_prep "$storage_path/retroarch-core/Vita3K/ux0"  "$bios_path/vita3k/ux0"
      dir_prep "$storage_path/retroarch-core/Vita3K/data"  "$bios_path/vita3k/data"
      dir_prep "$saves_path/psvita/Vita3K/savedata" "$storage_path/retroarch-core/Vita3K/ux0/user/00/savedata"
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders-builtin" "$bios_path/vita3k/shaders-builtin"
      dir_prep "$shaders_path/retroarch-core/Vita3K/shaders"  "$bios_path/vita3k/shaders"
      dir_prep "$texture_packs_path/retroarch-core/Vita3K/textures" "$bios_path/vita3k/ux0/textures"

      # Xenia Edge
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache" "$bios_path/Xenia-Edge/cache"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache0" "$bios_path/Xenia-Edge/cache0"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/cache1" "$bios_path/Xenia-Edge/cache1"
      dir_prep "$storage_path/retroarch-core/Xenia-Edge/library" "$bios_path/Xenia-Edge/library"
      dir_prep "$saves_path/xbox360/Xenia-Edge/content" "$bios_path/Xenia-Edge/content"
      dir_prep "$mods_path/retroarch-core/Xenia-Edge/plugins" "$bios_path/Xenia-Edge/plugins"
      dir_prep "$mods_path/retroarch-core/Xenia-Edge/patches" "$bios_path/Xenia-Edge/patches"

      # Xemu
      dir_prep "$shaders_path/retroarch-core/xemu/shaders" "$bios_path/xemu/xemu/shaders"
      create_dir "$saves_path/xbox/xemu" 

      ln -sfn "$bios_path/mcpx_1.0.bin" "$bios_path/xemu/mcpx_1.0.bin"
      ln -sfn "$bios_path/Complex_4627v1.03.bin" "$bios_path/xemu/Complex_4627v1.03.bin"
      ln -sfn "$saves_path/xbox/xemu/xbox_hdd.qcow2" "$bios_path/xemu/xbox_hdd.qcow2" 
      ln -sfn "$saves_path/xbox/xemu/xbox_eeprom.bin" "$bios_path/xemu/xbox_eeprom.bin"

      # ScummVM
      cp -fv "$component_config/scummvm.ini" "$retroarch_config_scummvm"
      log i "Installing ScummVM assets"
      unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/extra/*' -d /tmp
      unzip -o "$retroarch_extras_path/ScummVM.zip" 'scummvm/theme/*' -d /tmp

      create_dir "$storage_path/retroarch-core/ScummVM/icons"
      create_dir "$storage_path/retroarch-core/ScummVM/extra"
      create_dir "$storage_path/retroarch-core/ScummVM/theme"
      mv -f /tmp/scummvm/extra/* "$storage_path/retroarch-core/ScummVM/extra"
      mv -f /tmp/scummvm/theme/* "$storage_path/retroarch-core/ScummVM/theme"
      rm -rf /tmp/extra /tmp/theme /tmp/scummvm/extra /tmp/scummvm/theme

      set_setting_value "$retroarch_config_scummvm" "iconspath" "$storage_path/retroarch-core/ScummVM/icons" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "extrapath" "$storage_path/retroarch-core/ScummVM/extra" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "themepath" "$storage_path/retroarch-core/ScummVM/theme" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "savepath" "$saves_path/scummvm" "retroarch_scummvm" "scummvm"
      set_setting_value "$retroarch_config_scummvm" "browser_lastpath" "$roms_path/scummvm" "retroarch_scummvm" "scummvm"
    fi

  #######################################
  # These actions happen at every update
  #######################################

  retroarch_updater
}

_post_update_legacy::retroarch() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$version_being_updated" "0.7.0b"; then
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

    set_setting_value "$retroarch_config" "savestate_auto_load" "false" "retroarch"
    set_setting_value "$retroarch_config" "savestate_auto_save" "false" "retroarch"
  fi

  if check_version_is_older_than "$version_being_updated" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- Force disable global rewind in RA in prep for preset system"

    log i "Force disabling rewind, you can re-enable it via the Configurator"
    set_setting_value "$retroarch_config" "rewind_enable" "false" "retroarch"
  fi

  if check_version_is_older_than "$version_being_updated" "0.8.1b"; then
    log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

    log i "Installing the missing ScummVM assets and renaming \"$storage_path/retroarch/ScummVM/themes\" into \"theme\""
    mv -f "$storage_path/retroarch/ScummVM/themes" "$s/retroarch/ScummVM/themes"
    unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/extra/*' -d /tmp
    unzip -o "$config/retroarch/ScummVM.zip" 'scummvm/theme/*' -d /tmp
    mv -f "/tmp/scummvm/extra" "$storage_path/retroarch/ScummVM/extra"
    mv -f "/tmp/scummvm/theme" "$storage_path/retroarch/ScummVM/theme"

    rm -rf "/tmp/extra /tmp/theme"
  fi

  if check_version_is_older_than "$version_being_updated" "0.9.0b"; then
    log i "Forcing RetroArch to use the new libretro info path"
    set_setting_value "$retroarch_config" "libretro_info_path" "$XDG_CONFIG_HOME/retroarch/cores" "retroarch"
  fi

  if check_version_is_older_than "$version_being_updated" "0.9.1b"; then
    log i "Preparing the cheats for RetroArch..."
    create_dir "$cheats_path/retroarch"
    set_setting_value "$retroarch_config" "cheat_database_path" "$cheats_path/retroarch" "retroarch"
    tar --strip-components=1 -xzf "/app/retrodeck/cheats/retroarch.tar.gz" -C "$cheats_path/retroarch" --overwrite && log i "Cheats for RetroArch installed"
  fi

  if check_version_is_older_than "$version_being_updated" "0.10.0b"; then
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

  if check_version_is_older_than "$version_being_updated" "0.10.3b"; then
    create_dir "$shaders_path/retroarch/filters"
    move "$shaders_path/retroarch/shaders_cg" "$shaders_path/retroarch/shaders/shaders_cg"
    move "$shaders_path/retroarch/shaders_glsl" "$shaders_path/retroarch/shaders/shaders_glsl"
    move "$shaders_path/retroarch/shaders_slang" "$shaders_path/retroarch/shaders/shaders_slang"
    set_setting_value "$retroarch_config" "audio_filter_dir" "$shaders_path/retroarch/filters/audio" "retroarch"
    set_setting_value "$retroarch_config" "video_filter_dir" "$shaders_path/retroarch/filters/video" "retroarch"
    set_setting_value "$retroarch_config" "video_shader_dir" "$shaders_path/retroarch/shaders" "retroarch"
    set_setting_value "$retroarch_config" "overlay_directory" "$borders_path/retroarch" "retroarch"
    set_setting_value "$retroarch_config" "system_directory" "$bios_path" "retroarch"
  fi

  if [[ $(check_version_is_older_than "$version_being_updated" "0.10.9b") == "true" ]]; then
    create_dir "$screenshots_path/retroarch"
    set_setting_value "$retroarch_config" "screenshot_directory" "$screenshots_path/retroarch" "retroarch"
    cp -rfv "$retroarch_extras_path/cannonball" "$bios_path/cannonball"
    cp -rfv "$retroarch_extras_path/dinothawr" "$bios_path/dinothawr"
    cp -rfv "$retroarch_extras_path/DirkSimple" "$bios_path/DirkSimple"
    cp -rfv "$retroarch_extras_path/dolphin-emu" "$bios_path/dolphin-emu"
    cp -rfv "$retroarch_extras_path/ecwolf.pk3" "$bios_path/ecwolf.pk3"
    cp -rfv "$retroarch_extras_path/nxengine" "$bios_path/nxengine"
    cp -rfv "$retroarch_extras_path/prboom.wad" "$bios_path/prboom.wad"
    cp -rfv "$retroarch_extras_path/qemu" "$bios_path/qemu"
    cp -rfv "$retroarch_extras_path/xrick" "$bios_path/xrick"

    dir_prep "$saves_path/ps2/pcsx2/memcards" "$bios_path/pcsx2/memcards"
    dir_prep "$shaders_path/retroarch-core/pcsx2/shaders" "$bios_path/pcsx2/shaders"
    dir_prep "$cheats_path/retroarch-core/pcsx2/cheats" "$bios_path/pcsx2/cheats"
    dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ws" "$bios_path/pcsx2/cheats_ws"
    dir_prep "$cheats_path/retroarch-core/pcsx2/cheats_ni" "$bios_path/pcsx2/cheats_ni"
    dir_prep "$texture_packs_path/retroarch-core/pcsx2/textures" "$bios_path/pcsx2/textures"

  fi

  if [[ $(check_version_is_older_than "$version_being_updated" "0.10.10b") == "true" ]]; then

    dir_prep "$mods_path/retroarch-core/PPSSPP/PLUGINS" "$saves_path/PPSSPP/PSP/PLUGINS"
    dir_prep "$shaders_path/retroarch-core/PPSSPP/shaders" "$saves_path/PPSSPPPSP/shaders"

    create_dir -d "$storage_path/retroarch-core/PPSSPP/GAME"
    cp -fv "$XDG_CONFIG_HOME/retroarch/saves/PPSSPP/PSP/GAME/"* "$storage_path/retroarch-core/PPSSPP/GAME"
    dir_prep "$storage_path/retroarch-core/PPSSPP/GAME" "$saves_path/PPSSPP/PSP/GAME"

    set_setting_value "$retroarch_config_core_options" "melonds_opengl_better_polygons" "enabled" "retroarch"
    set_setting_value "$retroarch_config_core_options" "melonds_opengl_filtering" "nearest" "retroarch"
    set_setting_value "$retroarch_config_core_options" "melonds_opengl_resolution" "3" "retroarch"
    delete_setting "$retroarch_config_core_options" "melonds_opengl_renderer" "retroarch"
    add_setting "$retroarch_config_core_options" "melonds_number_of_screen_layouts" "8" "retroarch"
    add_setting "$retroarch_config_core_options" "melonds_render_mode" "opengl" "retroarch"
  fi

  

  #######################################
  # These actions happen at every update
  #######################################

  retroarch_updater
}

retroarch_updater() {
  # This function updates RetroArch by synchronizing shaders, cores, and border overlays.
  # It should be called whenever RetroArch is reset or updated.

  log i "Running RetroArch updater"

  log i "Updating overlays/borders..."
  create_dir "$borders_path/retroarch/overlays"
  tar -h -xzf "$retroarch_extras_path/overlays.tar.gz" -C "$borders_path/retroarch/overlays" --overwrite && log d "RetroArch overlays and borders updated correctly"

  log i "Updating shaders..."
  create_dir "$shaders_path/retroarch/shaders"
  tar -h -xzf "$retroarch_extras_path/shaders.tar.gz" -C "$shaders_path/retroarch/shaders" --overwrite && log d "RetroArch shaders updated correctly"

  log i "Updating filters..."
  create_dir "$shaders_path/retroarch/filters"
  tar -h -xzf "$retroarch_extras_path/filters.tar.gz" -C "$shaders_path/retroarch/filters" --overwrite && log d "RetroArch filters updated correctly"

  log i "Updating cheats..."
  create_dir "$cheats_path/retroarch"
  tar -h -xzf "$retroarch_extras_path/cheats.tar.gz" -C "$cheats_path/retroarch" --overwrite && log d "RetroArch cheats updated correctly"

  log i "Updating autoconfig..."
  create_dir "$XDG_CONFIG_HOME/retroarch/autoconfig"
  tar -h -xzf "$retroarch_extras_path/autoconfig.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/autoconfig" --overwrite && log d "RetroArch autoconfig updated correctly"
}
