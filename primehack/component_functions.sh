#!/bin/bash

export primehack_config="$XDG_CONFIG_HOME/primehack/Dolphin.ini"
export primehack_config_DSUClient="$XDG_CONFIG_HOME/primehack/DSUClient.ini"
export primehack_config_FreeLookController="$XDG_CONFIG_HOME/primehack/FreeLookController.ini"
export primehack_config_GBA="$XDG_CONFIG_HOME/primehack/GBA.ini"
export primehack_config_GCKeyNew="$XDG_CONFIG_HOME/primehack/GCKeyNew.ini"
export primehack_config_GCPadNew="$XDG_CONFIG_HOME/primehack/GCPadNew.ini"
export primehack_config_GFX="$XDG_CONFIG_HOME/primehack/GFX.ini"
export primehack_config_Hotkeys="$XDG_CONFIG_HOME/primehack/Hotkeys.ini"
export primehack_config_Logger="$XDG_CONFIG_HOME/primehack/Logger.ini"
export primehack_config_GCKeyNew="$XDG_CONFIG_HOME/primehack/GCKeyNew.ini"
export primehack_config_Qt="$XDG_CONFIG_HOME/primehack/Qt.ini"
export primehack_config_RetroAchievements="$XDG_CONFIG_HOME/primehack/RetroAchievements.ini"
export primehack_config_WiimoteNew="$XDG_CONFIG_HOME/primehack/WiimoteNew.ini"
export primehack_dynamic_input_textures_path="$XDG_DATA_HOME/primehack/Load/DynamicInputTextures"
export primehack_rd_config_dir="$rd_components/primehack/rd_config"

_set_setting_value::primehack() {
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

_get_setting_value::primehack() {
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

_prepare_component::primehack() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Primehack"
      log i "------------------------"
      
      create_dir -d "$XDG_CONFIG_HOME/primehack/"
      cp -fvr "$component_config/config/"* "$XDG_CONFIG_HOME/primehack/"
      set_setting_value "$primehack_config" "ISOPath0" "$roms_path/primehack" "primehack" "General"
      dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
      dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
      dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
      dir_prep "$screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
      dir_prep "$states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
      dir_prep "$saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii"
      dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
      dir_prep "$shaders_path/Primehack" "$XDG_DATA_HOME/primehack/Shaders"
      dir_prep "$logs_path/Primehack" "$XDG_DATA_HOME/primehack/Logs"
      dir_prep "$storage_path/Primehack/Dump" "$XDG_DATA_HOME/Primehack/Dump"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Primehack"
      log i "------------------------"

      dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
      dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
      dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
      dir_prep "$screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
      dir_prep "$states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
      dir_prep "$saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii/"
      dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
      dir_prep "$shaders_path/Primehack" "$XDG_DATA_HOME/primehack/Shaders"
      dir_prep "$logs_path/Primehack" "$XDG_DATA_HOME/primehack/Logs"
      dir_prep "$storage_path/Primehack/Dump" "$XDG_DATA_HOME/Primehack/Dump"
      set_setting_value "$primehack_config" "ISOPath0" "$roms_path/primehack" "primehack" "General"
    ;;

  esac
}

_post_update::primehack() {
  local previous_version="$1"

  #######################################
  # These actions happen at every update
  #######################################

  if [[ -d "$primehack_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Primehack..."
    rsync -rlD --delete --mkpath "$rd_components/shared-data/DynamicInputTextures/" "$primehack_dynamic_input_textures_path/" && log i "Done"
  fi
}

_post_update_legacy::primehack() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.6.2b"; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Primehack preconfiguration completely redone. "Stop emulation" hotkey set to Start+Select, Xbox and Nintendo keymap profiles were created, Xbox set as default.

    rm -rf "$XDG_CONFIG_HOME/primehack" # Purge old Primehack config files. Saves are safe as they are linked into $XDG_DATA_HOME/primehack.
    prepare_component "reset" "primehack"
  fi

  if check_version_is_older_than "$previous_version" "0.6.3b"; then
    # In version 0.6.3b, the following changes were made that required config file updates/reset:
    # - Put Dolphin and Primehack save states in different folders inside $rdhome/states

    dir_prep "$rdhome/states/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
  fi

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Move Dolphin and Primehack save folder names
    # - Disable ask-on-exit in existing Citra / Dolphin / Duckstation / Primehack installs for proper preset functionality

    dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
    dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"

    mv "$saves_path/gc/primehack/EUR" "$saves_path/gc/primehack/EU"
    mv "$saves_path/gc/primehack/USA" "$saves_path/gc/primehack/US"
    mv "$saves_path/gc/primehack/JAP" "$saves_path/gc/primehack/JP"
    dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
    dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
    dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"

    set_setting_value "$primehackconf" "ConfirmStop" "False" "primehack" "Interface"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then

    log i "0.10.0b Upgrade - Postmove: PrimeHack"

    set_setting_value "$primehack_config" "CPUThread" "False" "primehack" "Core"
    set_setting_value "$primehack_config" "LanguageCode" " " "primehack" "Interface"
    prepare_component "postmove" "primehack"
  fi

  if check_version_is_older_than "$previous_version" "0.10.2b"; then

    log i "0.10.2b Upgrade - Postmove: PrimeHack"

    create_dir "$roms_path/primehack"
    set_setting_value "$primehack_config" "SIDevice0" "0" "primehack" "Core"
    set_setting_value "$primehack_config" "ISOPath0" "$roms_path/primehack" "primehack" "General"
    set_setting_value "$primehack_config" "ISOPaths" "1" "primehack" "General"
    sed -i '/ISOPath1/d' "$primehack_config" # Remove unneeded second ISO path
    rsync -rlD --mkpath "$primehack_rd_config_dir/config/Profiles/Wiimote/" "$XDG_CONFIG_HOME/primehack/Profiles/Wiimote/"
    rsync -rlD --mkpath "$primehack_rd_config_dir/config/WiimoteNew.ini" "$XDG_CONFIG_HOME/primehack/WiimoteNew.ini"
  fi

  #######################################
  # These actions happen at every update
  #######################################

  if [[ -d "$primehack_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Primehack..."
    rsync -rlD --delete --mkpath "$rd_components/shared-data/DynamicInputTextures/" "$primehack_dynamic_input_textures_path/" && log i "Done"
  fi
}
