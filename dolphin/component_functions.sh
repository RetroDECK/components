#!/bin/bash

export dolphin_config="$XDG_CONFIG_HOME/dolphin-emu/Dolphin.ini"
export dolphin_config_DSUClient="$XDG_CONFIG_HOME/dolphin-emu/DSUClient.ini"
export dolphin_config_FreeLookControlle="$XDG_CONFIG_HOME/dolphin-emu/FreeLookController.ini"
export dolphin_config_GBA="$XDG_CONFIG_HOME/dolphin-emu/GBA.ini"
export dolphin_config_GCKeyNew="$XDG_CONFIG_HOME/dolphin-emu/GCKeyNew.ini"
export dolphin_config_GCPadNew="$XDG_CONFIG_HOME/dolphin-emu/GCPadNew.ini"
export dolphin_config_GFX="$XDG_CONFIG_HOME/dolphin-emu/GFX.ini"
export dolphin_config_Hotkeys="$XDG_CONFIG_HOME/dolphin-emu/Hotkeys.ini"
export dolphin_config_Logger="$XDG_CONFIG_HOME/dolphin-emu/Logger.ini"
export dolphin_config_GCKeyNew="$XDG_CONFIG_HOME/dolphin-emu/GCKeyNew.ini"
export dolphin_config_Qt="$XDG_CONFIG_HOME/dolphin-emu/Qt.ini"
export dolphin_config_RetroAchievements="$XDG_CONFIG_HOME/dolphin-emu/RetroAchievements.ini"
export dolphin_config_WiimoteNew="$XDG_CONFIG_HOME/dolphin-emu/WiimoteNew.ini"
export dolphin_dynamic_input_textures_path="$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures"
export dolphin_rd_config_dir="$rd_components/dolphin/rd_config"
export dolphin_textures_path="$XDG_DATA_HOME/dolphin-emu/Load/Textures"
export dolphin_mods_path="$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"

_set_setting_value::dolphin() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^s^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  fi
}

_get_setting_value::dolphin() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  fi
}

_prepare_component::dolphin() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Dolphin"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/dolphin-emu/"
      cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/dolphin-emu/"
      set_setting_value "$dolphin_config" "BIOS" "$bios_path" "dolphin" "GBA"
      set_setting_value "$dolphin_config" "SavesPath" "$saves_path/gba" "dolphin" "GBA"
      set_setting_value "$dolphin_config" "ISOPath0" "$roms_path/wii" "dolphin" "General"
      set_setting_value "$dolphin_config" "ISOPath1" "$roms_path/gc" "dolphin" "General"
      set_setting_value "$dolphin_config" "WiiSDCardPath" "$saves_path/wii/dolphin/sd.raw" "dolphin" "General"
      dir_prep "$saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
      dir_prep "$saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
      dir_prep "$saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"
      dir_prep "$screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
      dir_prep "$states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
      dir_prep "$saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
      dir_prep "$mods_path/Dolphin/GraphicMods" "$dolphin_mods_path"
      dir_prep "$texture_packs_path/Dolphin/Textures" "$dolphin_textures_path"
      dir_prep "$shaders_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Shaders"
      dir_prep "$logs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Logs"
      dir_prep "$storage_path/Dolphin/Dump" "$XDG_DATA_HOME/dolphin-emu/Dump"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Dolphin"
      log i "----------------------"

      dir_prep "$saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
      dir_prep "$saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
      dir_prep "$saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"
      dir_prep "$screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
      dir_prep "$states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
      dir_prep "$saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
      dir_prep "$mods_path/Dolphin/GraphicMods" "$dolphin_mods_path"
      dir_prep "$texture_packs_path/Dolphin/Textures" "$dolphin_textures_path"
      dir_prep "$shaders_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Shaders"
      dir_prep "$logs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Logs"
      dir_prep "$storage_path/Dolphin/Dump" "$XDG_DATA_HOME/dolphin-emu/Dump"
      set_setting_value "$dolphin_config" "BIOS" "$bios_path" "dolphin" "GBA"
      set_setting_value "$dolphin_config" "SavesPath" "$saves_path/gba" "dolphin" "GBA"
      set_setting_value "$dolphin_config" "ISOPath0" "$roms_path/wii" "dolphin" "General"
      set_setting_value "$dolphin_config" "ISOPath1" "$roms_path/gc" "dolphin" "General"
      set_setting_value "$dolphin_config" "WiiSDCardPath" "$saves_path/wii/dolphin/sd.raw" "dolphin" "General"
    ;;

  esac
}

_validate_for_compression::rvz() {
  local file="$1"
  local normalized_filename=$(echo "$file" | tr '[:upper:]' '[:lower:]')
  if echo "$normalized_filename" | grep -qE '\.iso|\.gcm'; then
    return 0
  else
    return 1
  fi
}

_compress_game::rvz() {
  local source_file="$1"
  local dest_file="$2"
  /bin/bash "$rd_components/dolphin/component_launcher.sh" rvz_compression convert -f rvz -b 131072 -c zstd -l 5 -i "$source_file" -o "$dest_file.rvz"
}
