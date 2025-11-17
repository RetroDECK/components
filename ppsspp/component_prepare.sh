#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"
component_extras="/app/retrodeck/components/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"

  create_dir -d "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
  cp -fv "$component_config/"* "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
  set_setting_value "$ppsspp_config" "CurrentDirectory" "$roms_path/psp" "ppsspp" "General"
  dir_prep "$saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
  dir_prep "$states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
  dir_prep "$texture_packs_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
  dir_prep "$shaders_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/assets/shaders"

  log i "Preparing PPSSPP cheats"
  create_dir -d "$cheats_path/PPSSPP-SA"
  dir_prep "$cheats_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
  if [[ -d "$cheats_path/PPSSPP-SA" && "$(ls -A "$cheats_path"/PPSSPP-SA)" ]]; then
    backup_file="$backups_path/cheats/PPSSPP-SA-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$cheats_path" PPSSPP
    log i "PPSSPP cheats backed up to $backup_file"
  fi
  create_dir "$cheats_path/PPSSPP/"
  unzip -q -o -j "$component_extras/CWCheat-Database-Plus--master.zip" "*/cheat.db" -d "$cheats_path/PPSSPP/"

  log i "Preparing PPSSPP BIOS"
  create_dir -d "$bios_path/PPSSPP"
  tar -xzf "$component_extras/ppsspp_foss_bios.tar.gz" -C "$bios_path/PPSSPP" --strip-components=1 assets/ && log i "PPSSPP BIOS files extracted to $bios_path/PPSSPP" || log e "Failed to extract PPSSPP BIOS files."
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$ppsspp_config" "CurrentDirectory" "$roms_path/psp" "ppsspp" "General"
  dir_prep "$saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
  dir_prep "$states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
  dir_prep "$texture_packs_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
  dir_prep "$shaders_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/assets/shaders"
  dir_prep "$cheats_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
fi
