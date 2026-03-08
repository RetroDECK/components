#!/bin/bash

export melonds_config="$XDG_CONFIG_HOME/melonDS/melonDS.toml"

_set_setting_value::melonds() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  local sed_cmd
  sed_cmd='s^'"$name"' = ".*"^'"$name"' = "'"$value"'"^; t end;'
  sed_cmd+='s^'"$name"' =.*^'"$name"' = '"$value"'^; :end'

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^{'"$sed_cmd"'}' "$file"
  else
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::melonds() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         val = substr($0, index($0,"=")+2)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " =") == 1 {
         val = substr($0, index($0,"=")+2)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  fi
}

_prepare_component::melonds() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting MelonDS"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/melonDS/"
      cp -fv "$component_config/melonDS.toml" "$melonds_config"
      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/nds/melonds\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/nds/melonds\"" "melonds" "Instance0"
      create_dir "$saves_path/nds/melonds"
      create_dir "$states_path/nds/melonds"
      dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving MelonDS"
      log i "----------------------"

      dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/nds/melonds\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/nds/melonds\"" "melonds" "Instance0"
    ;;

  esac
}
