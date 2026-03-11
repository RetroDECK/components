#!/bin/bash

export azahar_config_path="$XDG_CONFIG_HOME/azahar-emu"
export azahar_qtconfig="$azahar_config_path/qt-config.ini"
export azahar_mods_path="$XDG_DATA_HOME/azahar-emu/load/mods"
export azahar_textures_path="$XDG_DATA_HOME/azahar-emu/load/textures"
export azahar_shaders_path="$XDG_DATA_HOME/azahar-emu/shaders"
export azahar_logs_path="$XDG_DATA_HOME/azahar-emu/log"
export azahar_cheats_path="$XDG_DATA_HOME/azahar-emu/cheats"

_set_setting_value::azahar() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  local sed_cmd
  sed_cmd='s^'"$name"'=".*"^'"$name"'="'"$value"'"^; t end;'
  sed_cmd+='s^'"$name"'=.*^'"$name"'='"$value"'^; :end'

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"'=^{'"$sed_cmd"'}' "$file"
  else
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::azahar() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -F'=' -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && $1 == key {
         val = substr($0, index($0,"=")+1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    awk -F'=' -v key="$name" \
      '/^\[/ { exit }
       $1 == key {
         val = substr($0, index($0,"=")+1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  fi
}

_prepare_component::azahar() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Azahar"
      log i "----------------------"

      create_dir -d "$azahar_config_path"
      create_dir -d "$azahar_mods_path"
      create_dir -d "$azahar_textures_path"
      create_dir "$screenshots_path/Azahar"
      create_dir "$saves_path/n3ds/azahar/nand/"
      create_dir "$saves_path/n3ds/azahar/sdmc/"

      cp -fT "$component_config/qt-config.ini" "$azahar_config_path/qt-config.ini"

      set_setting_value "$azahar_qtconfig" "use_custom_storage" "true" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/nand/" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "sdmc_directory" "$saves_path/n3ds/azahar/sdmc/" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "Paths\gamedirs\3\path" "$roms_path/n3ds" "azahar" "UI"
      set_setting_value "$azahar_qtconfig" "Paths\screenshotPath" "$screenshots_path/Azahar" "azahar" "UI"

      dir_prep "$mods_path/Azahar/mods" "$azahar_mods_path"
      dir_prep "$texture_packs_path/Azahar/textures" "$azahar_textures_path"
      dir_prep "$shaders_path/Azahar/" "$azahar_shaders_path"
      dir_prep "$logs_path/Azahar/" "$azahar_logs_path"
      dir_prep "$cheats_path/Azahar/" "$azahar_cheats_path"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Azahar"
      log i "----------------------"

      set_setting_value "$azahar_qtconfig" "use_custom_storage" "true" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/nand/" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "sdmc_directory" "$saves_path/n3ds/azahar/sdmc/" "azahar" "Data%20Storage"
      set_setting_value "$azahar_qtconfig" "Paths\gamedirs\3\path" "$roms_path/n3ds" "azahar" "UI"
      set_setting_value "$azahar_qtconfig" "Paths\screenshotPath" "$screenshots_path/Azahar" "azahar" "UI"

      dir_prep "$mods_path/Azahar/mods" "$azahar_mods_path"
      dir_prep "$texture_packs_path/Azahar/textures" "$azahar_textures_path"
      dir_prep "$shaders_path/Azahar/" "$azahar_shaders_path"
      dir_prep "$logs_path/Azahar/" "$azahar_logs_path"
      dir_prep "$cheats_path/Azahar/" "$azahar_cheats_path"
    ;;

  esac
}

_post_update::azahar() {
  local previous_version="$1"

}

_post_update_legacy::azahar() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher

  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Init Azahar as it is a new emulator
    # - Migrate legacy Citra saves to Azahar saves dir

    log i "0.10.0b Upgrade - Reset: Azahar"

    prepare_component "reset" "azahar"

    if [[ -d "$XDG_DATA_HOME/citra-emu/nand" ]]; then
      move "$XDG_DATA_HOME/citra-emu/nand" "$saves_path/n3ds/azahar/"
    fi
    if [[ -d "$XDG_DATA_HOME/citra-emu/sdmc" ]]; then
      move "$XDG_DATA_HOME/citra-emu/sdmc" "$saves_path/n3ds/azahar/"
    fi
    if [[ -d "$saves_path/n3ds/citra/" ]]; then
      move "$saves_path/n3ds/citra/" "$saves_path/n3ds/azahar/"
    fi
    if [[ -d "$mods_path/citra/" ]]; then
      move "$mods_path/citra/" "$mods_path/n3ds/azahar/"
    fi
    if [[ -d "$texture_packs_path/citra/" ]]; then
      move "$texture_packs_path/citra/" "$texture_packs_path/n3ds/azahar/"
    fi
  fi

  if check_version_is_older_than "$previous_version" "0.10.2b"; then
    log i "0.10.2b Upgrade - Reset: Azahar"
    prepare_component "reset" "azahar"
  fi

  if check_version_is_older_than "$previous_version" "0.10.3b"; then
    log i "0.10.3b Upgrade - Reset: Azahar"
    set_setting_value "$azahar_qtconfig" "Shortcuts\Main%20Window\Rotate%20Screens%20Upright\KeySeq" "Alt+Y" "azahar" "UI"
    set_setting_value "$azahar_qtconfig" "Shortcuts\Main%20Window\Toggle%20Screen%20Layout\KeySeq" "Ctrl+L" "azahar" "UI"
  fi
}
