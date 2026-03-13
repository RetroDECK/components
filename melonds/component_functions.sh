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
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         val = substr($0, index($0,"=")+2)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"] }
       index($0, key " =") == 1 {
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

_post_update::melonds() {
  local previous_version="$1"

}

_post_update_legacy::melonds() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.10.1b"; then

    log i "0.10.1b Upgrade - Fix Bios Path: MelonDS"

  #   set_setting_value "$melonds_config" "BIOS9Path" "$bios_path/bios9.bin" "DS" "melonds"
  #   set_setting_value "$melonds_config" "BIOS7Path" "$bios_path/bios7.bin" "DS" "melonds"
  #   set_setting_value "$melonds_config" "FirmwarePath" "$bios_path/firmware.bin" "DS" "melonds"
    sed -i "s#RETRODECKSTATESDIR#${states_path}#g" "$melonds_config"
    sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$melonds_config"
    sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$melonds_config"
  fi
}
