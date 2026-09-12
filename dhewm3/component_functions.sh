#!/bin/bash

export dhewm3_config="$XDG_CONFIG_HOME/dhewm3/base/dhewm.cfg"

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

      # Base dirs

      create_dir "$roms_path/doom3/d3xp"
      create_dir "$roms_path/doom3/base"
      cp -fr "$doom3_config" "$roms_path/doom3/base"

      # XDG_DATA_HOME must be symlinked to the DOOM 3 directory for mods to work.

      dir_prep "$roms_path/doom3" "$XDG_DATA_HOME/dhewm3"

    ;;

        postmove)
      log i "------------------------"
      log i "Post-moving dhewm 3"
      log i "------------------------"

      # XDG_DATA_HOME must be symlinked to the DOOM 3 directory for mods to work.
      
      dir_prep "$roms_path/doom3" "$XDG_DATA_HOME/dhewm3"

    ;;

  esac
}
_post_update::dhewm3() {
  local previous_version="$1"

}
