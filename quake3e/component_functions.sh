#!/bin/bash

_prepare_component::quake3e() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Quake3e"
      log i "------------------------"

      create_dir "$XDG_CONFIG_HOME/quake3e"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/quake3e/"

      create_dir "$roms_path/quake3/baseq3"

      # XDG_DATA_HOME must be symlinked to the Quake 3 directory for mods to work.

      dir_prep "$roms_path/quake3" "$XDG_DATA_HOME/quake3e"

    ;;

        postmove)
      log i "------------------------"
      log i "Post-moving Quake3e"
      log i "------------------------"

      # XDG_DATA_HOME must be symlinked to the Quake 3 directory for mods to work.
      
      dir_prep "$roms_path/quake3" "$XDG_DATA_HOME/quake3e"

    ;;

  esac
}

