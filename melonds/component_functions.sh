#!/bin/bash

export melonds_config="$XDG_CONFIG_HOME/melonds/melonds.toml"

_set_setting_value::melonds() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"
  local sed_cmd
  sed_cmd='s^\^'"$name"' = ".*"^'"$name"' = "'"$value"'"^; t end;'
  sed_cmd+='s^\^'"$name"' =.*^'"$name"' = '"$value"'^; :end'
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
      log i "Resetting melonDS"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/melonds/"
      cp -fv "$component_config/melonds.toml" "$melonds_config"

      create_dir "$saves_path/melonDS-SA/saves"
      create_dir "$states_path/melonDS-SA/states"
      create_dir "$cheats_path/melonDS/cheats"

      dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"

      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"

      set_setting_value "$melonds_config" "NANDPath" "\"$bios_path/dsi_nand.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/dsi_bios7.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/dsi_bios9.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/dsi_firmware.bin\"" "melonds" "DSi"

      set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/melonDS-SA/saves\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/melonDS-SA/states\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "CheatFilePath" "\"$cheats_path/melonDS/cheats\"" "melonds" "Instance0"


    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving melonDS"
      log i "----------------------"

      dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonds/bios"
      
      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"

      set_setting_value "$melonds_config" "NANDPath" "\"$bios_path/dsi_nand.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/dsi_bios7.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/dsi_bios9.bin\"" "melonds" "DSi"
      set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/dsi_firmware.bin\"" "melonds" "DSi"

      set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/melonDS-SA/saves\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/melonDS-SA/states\"" "melonds" "Instance0"
      set_setting_value "$melonds_config" "CheatFilePath" "\"$cheats_path/melonDS/cheats\"" "melonds" "Instance0"
      
    ;;

  esac
}

_post_update::melonds() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Upgrade - melonDS RA Conflict Migration"

    create_dir "$saves_path/melonDS-SA/saves"
    create_dir "$states_path/melonDS-SA/states"
    create_dir "$cheats_path/melonDS/cheats"

    cp -rfv "$saves_path/nds/melonds" "$saves_path/melonDS-SA/saves"
    cp -rfv "$states_path/nds/melonds" "$states_path/melonDS-SA/states"

    create_dir "$backups_path/0.11.0/melonDS-SA/saves"
    create_dir "$backups_path/0.11.0/melonDS-SA/states"

    cp -rfv "$saves_path/nds/melonds" "$backups_path/0.11.0/melonDS-SA/saves"
    cp -rfv "$states_path/nds/melonds" "$backups_path/0.11.0/melonDS-SA/states"

    set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/melonDS-SA/saves\"" "melonds" "Instance0"
    set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/melonDS-SA/states\"" "melonds" "Instance0"
    set_setting_value "$melonds_config" "CheatFilePath" "\"$cheats_path/melonDS/cheats\"" "melonds" "Instance0"

    create_dir "$saves_path/RetroArch"
    create_dir "$states_path/RetroArch"
    mv "$saves_path/nds" "$saves_path/RetroArch/"
    mv "$states_path/nds" "$states_path/RetroArch/"

 fi
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
