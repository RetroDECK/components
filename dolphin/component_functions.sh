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
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"] }
        index($0, key " =") == 1 {
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
  local component_path="$(get_component_path "dolphin")"
  local source_file="$1"
  local dest_file="$2"
  /bin/bash "$component_path/component_launcher.sh" rvz_compression convert -f rvz -b 131072 -c zstd -l 5 -i "$source_file" -o "$dest_file.rvz"
}

_post_compression_cleanup::rvz() {
  local file_to_cleanup="$1"
  log i "Removing $file_to_cleanup as part of post-compression cleanup"
  rm -f "$file_to_cleanup"
}

_post_update::dolphin() {

  #######################################
  # These actions happen at every update
  #######################################

  if [[ -d "$dolphin_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Dolphin..."
    rsync -rlD --delete --mkpath "$rd_components/shared-data/DynamicInputTextures/" "$dolphin_dynamic_input_textures_path/" && log i "Done"
  fi
}

_post_update_legacy::dolphin() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.6.3b"; then
    # In version 0.6.3b, the following changes were made that required config file updates/reset:
    # - Put Dolphin and Primehack save states in different folders inside $rdhome/states

    dir_prep "$rdhome/states/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
  fi

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Move Dolphin and Primehack save folder names
    # - Disable ask-on-exit in existing Citra / Dolphin / Duckstation / Primehack installs for proper preset functionality

    dir_prep "$mods_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
    dir_prep "$texture_packs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"

    mv "$saves_path/gc/dolphin/EUR" "$saves_path/gc/dolphin/EU"
    mv "$saves_path/gc/dolphin/USA" "$saves_path/gc/dolphin/US"
    mv "$saves_path/gc/dolphin/JAP" "$saves_path/gc/dolphin/JP"
    dir_prep "$saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
    dir_prep "$saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
    dir_prep "$saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"

    set_setting_value "$dolphin_config" "ConfirmStop" "False" "dolphin" "Interface"
  fi

  if check_version_is_older_than "$previous_version" "0.9.1b"; then
    log i "Preparing the RetroAchievements for Dolphin..."
    cp -vn "$config/dolphin/"* "$XDG_CONFIG_HOME/dolphin-emu/"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    log i "0.10.0b Upgrade - Postmove: Dolphin with Config Changes"

    set_setting_value "$dolphin_config" "CPUThread" "False" "dolphin" "Core"
    set_setting_value "$dolphin_config" "LanguageCode" " " "dolphin" "Interface"
    set_setting_value "$dolphin_config" "SIDevice1" "6" "dolphin" "Core"
    set_setting_value "$dolphin_config" "SIDevice2" "6" "dolphin" "Core"
    set_setting_value "$dolphin_config" "SIDevice3" "6" "dolphin" "Core"

    prepare_component "postmove" "dolphin"

  fi

  #######################################
  # These actions happen at every update
  #######################################

  if [[ -d "$dolphin_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Dolphin..."
    rsync -rlD --delete --mkpath "$rd_components/shared-data/DynamicInputTextures/" "$dolphin_dynamic_input_textures_path/" && log i "Done"
  fi
}
