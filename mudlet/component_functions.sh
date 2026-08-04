#!/bin/bash

export mudlet_config="$XDG_CONFIG_HOME/mudlet/Mudlet.ini"
export mudlet_roms_folder_path="$roms_path/muds"

_prepare_component::mudlet() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Mudlet"
      log i "----------------------"

        create_dir "$XDG_CONFIG_HOME/mudlet"
        create_dir "$XDG_DATA_HOME/mudlet"
        dir_prep "$mudlet_roms_folder_path" "$XDG_DATA_HOME/mudlet/portable/profiles"
        dir_prep "$mods_path/mudlet/plugins" "$XDG_DATA_HOME/mudlet/plugins/"
    ;;

      esac
}