#!/bin/bash

export mudlet_config="$XDG_CONFIG_HOME/mudlet/Mudlet.ini"

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
        dir_prep "$roms_path/muds" "$XDG_DATA_HOME/mudlet/profiles"
        dir_prep "$mods_path/mudlet/plugins" "$XDG_DATA_HOME/mudlet/plugins/"
    ;;

        postmove)
      log i "------------------------"
      log i "Post-moving Mudlet"
      log i "------------------------"

        dir_prep "$roms_path/muds" "$XDG_DATA_HOME/mudlet/profiles"
        dir_prep "$mods_path/mudlet/plugins" "$XDG_DATA_HOME/mudlet/plugins/"
    ;;

  esac
}

