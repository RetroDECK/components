#!/bin/bash

primehack_config="$XDG_CONFIG_HOME/primehack/Dolphin.ini"
primehack_config_DSUClient="$XDG_CONFIG_HOME/primehack/DSUClient.ini"
primehack_config_FreeLookController="$XDG_CONFIG_HOME/primehack/FreeLookController.ini"
primehack_config_GBA="$XDG_CONFIG_HOME/primehack/GBA.ini"
primehack_config_GCKeyNew="$XDG_CONFIG_HOME/primehack/GCKeyNew.ini"
primehack_config_GCPadNew="$XDG_CONFIG_HOME/primehack/GCPadNew.ini"
primehack_config_GFX="$XDG_CONFIG_HOME/primehack/GFX.ini"
primehack_config_Hotkeys="$XDG_CONFIG_HOME/primehack/Hotkeys.ini"
primehack_config_Logger="$XDG_CONFIG_HOME/primehack/Logger.ini"
primehack_config_GCKeyNew="$XDG_CONFIG_HOME/primehack/GCKeyNew.ini"
primehack_config_Qt="$XDG_CONFIG_HOME/primehack/Qt.ini"
primehack_config_RetroAchievements="$XDG_CONFIG_HOME/primehack/RetroAchievements.ini"
primehack_config_WiimoteNew="$XDG_CONFIG_HOME/primehack/WiimoteNew.ini"
primehack_dynamic_input_textures_path="$XDG_DATA_HOME/primehack/Load/DynamicInputTextures"
primehack_rd_config_dir="$rd_components/primehack/rd_config"

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
