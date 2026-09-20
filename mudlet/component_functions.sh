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

        create_dir "$XDG_DATA_HOME/mudlet"
        dir_prep "$roms_path/muds" "$XDG_DATA_HOME/mudlet/profiles"
        cp -fr "$component_config/"* "$XDG_DATA_HOME/mudlet/"
    ;;

        postmove)
      log i "------------------------"
      log i "Post-moving Mudlet"
      log i "------------------------"

        dir_prep "$roms_path/muds" "$XDG_DATA_HOME/mudlet/profiles"
    ;;

  esac
}

