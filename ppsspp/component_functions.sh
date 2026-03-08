#!/bin/bash

export ppsspp_config="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp.ini"
export ppsspp_config_controls="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/controls.ini"
export ppsspp_retroachievements_dat="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat"
export ppsspp_cheats_db="$rd_components/ppsspp/cheats/cheat.db"
export ppsspp_rd_config_dir="$rd_components/ppsspp/rd_config"
export ppsspp_rd_extras_dir="$rd_components/ppsspp/rd_extras"
export ppsspp_textures_path="$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
export ppsspp_shaders_path="$XDG_CONFIG_HOME/ppsspp/PSP/shaders"
export ppsspp_cheats_path="$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
export ppsspp_mods_path="$XDG_CONFIG_HOME/ppsspp/PSP/PLUGINS"
export ppsspp_logs_path="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/DUMP"

_set_setting_value::ppsspp() {
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

_get_setting_value::ppsspp() {
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

_prepare_component::ppsspp() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"
  local component_extras="$(get_own_component_path)/rd_extras"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting PPSSPP-SA"
      log i "------------------------"
      
      create_dir -d "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
      cp -fv "$component_config/"* "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
      set_setting_value "$ppsspp_config" "CurrentDirectory" "$roms_path/psp" "ppsspp" "General"
      dir_prep "$saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
      dir_prep "$texture_packs_path/PPSSPP/TEXTURES" "$ppsspp_textures_path"
      dir_prep "$shaders_path/PPSSPP" "$ppsspp_shaders_path"
      dir_prep "$mods_path/PPSSPP/PLUGINS" "$ppsspp_mods_path"
      dir_prep "$logs_path/PPSSPP" "$ppsspp_logs_path"

      log i "Preparing PPSSPP cheats"
      create_dir -d "$cheats_path/PPSSPP"
      dir_prep "$cheats_path/PPSSPP" "$ppsspp_cheats_path"
      if [[ -d "$cheats_path/PPSSPP" && "$(ls -A "$cheats_path"/PPSSPP)" ]]; then
        backup_file="$backups_path/cheats/PPSSPP-$(date +%y%m%d).tar.gz"
        create_dir "$(dirname "$backup_file")"
        tar -czf "$backup_file" -C "$cheats_path" PPSSPP
        log i "PPSSPP cheats backed up to $backup_file"
      fi

      unzip -q -o -j "$component_extras/CWCheat-Database-Plus--master.zip" "*/cheat.db" -d "$cheats_path/PPSSPP"

      log i "Preparing PPSSPP BIOS"
      create_dir -d "$bios_path/PPSSPP"
      tar -xzf "$component_extras/ppsspp_foss_bios.tar.gz" -C "$bios_path/PPSSPP" --strip-components=1 assets/ && log i "PPSSPP BIOS files extracted to $bios_path/PPSSPP" || log e "Failed to extract PPSSPP BIOS files."  
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving PPSSPP-SA"
      log i "------------------------"

      set_setting_value "$ppsspp_config" "CurrentDirectory" "$roms_path/psp" "ppsspp" "General"
      dir_prep "$saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
      dir_prep "$texture_packs_path/PPSSPP/TEXTURES" "$ppsspp_textures_path"
      dir_prep "$shaders_path/PPSSPP" "$ppsspp_shaders_path"
      dir_prep "$cheats_path/PPSSPP" "$ppsspp_cheats_path"
      dir_prep "$mods_path/PPSSPP/PLUGINS" "$ppsspp_mods_path"
      dir_prep "$logs_path/PPSSPP" "$ppsspp_logs_path"
    ;;

  esac
}
