#!/bin/bash

export dhewm3_config="$XDG_CONFIG_HOME/dhewm3/uzdoom.ini"
export doom3_controller_config="$XDG_CONFIG_HOME/dhewm3/gamepad.cfg"
export doom3xp_controller_config="$XDG_CONFIG_HOME/dhewm3/gamepad-d3xp.cfg"

_prepare_component::dhewm3() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting dhewm 3"
      log i "------------------------"

      create_dir "$XDG_CONFIG_HOME/dhewm3"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/dhewm3/"

      create_dir "$roms_path/doom3/d3xp"

      # The entire DATA_HOME needs to be to Doom 3 for the mods to work

      dir_prep "$roms_path/doom3" "$XDG_DATA_HOME/dhewm3"

    ;;

        postmove)
      log i "------------------------"
      log i "Post-moving dhewm 3"
      log i "------------------------"

      # The entire DATA_HOME needs to be to Doom 3 for the mods to work
      
      dir_prep "$roms_path/doom3" "$XDG_DATA_HOME/dhewm3"

    ;;

  esac
}
_post_update::uzdoom() {
  local previous_version="$1"

}
