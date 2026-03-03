#!/bin/bash

dolphin_config="$XDG_CONFIG_HOME/dolphin-emu/Dolphin.ini"
dolphin_config_DSUClient="$XDG_CONFIG_HOME/dolphin-emu/DSUClient.ini"
dolphin_config_FreeLookControlle="$XDG_CONFIG_HOME/dolphin-emu/FreeLookController.ini"
dolphin_config_GBA="$XDG_CONFIG_HOME/dolphin-emu/GBA.ini"
dolphin_config_GCKeyNew="$XDG_CONFIG_HOME/dolphin-emu/GCKeyNew.ini"
dolphin_config_GCPadNew="$XDG_CONFIG_HOME/dolphin-emu/GCPadNew.ini"
dolphin_config_GFX="$XDG_CONFIG_HOME/dolphin-emu/GFX.ini"
dolphin_config_Hotkeys="$XDG_CONFIG_HOME/dolphin-emu/Hotkeys.ini"
dolphin_config_Logger="$XDG_CONFIG_HOME/dolphin-emu/Logger.ini"
dolphin_config_GCKeyNew="$XDG_CONFIG_HOME/dolphin-emu/GCKeyNew.ini"
dolphin_config_Qt="$XDG_CONFIG_HOME/dolphin-emu/Qt.ini"
dolphin_config_RetroAchievements="$XDG_CONFIG_HOME/dolphin-emu/RetroAchievements.ini"
dolphin_config_WiimoteNew="$XDG_CONFIG_HOME/dolphin-emu/WiimoteNew.ini"
dolphin_dynamic_input_textures_path="$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures"
dolphin_rd_config_dir="$rd_components/dolphin/rd_config"
dolphin_textures_path="$XDG_DATA_HOME/dolphin-emu/Load/Textures"
dolphin_mods_path="$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"

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
