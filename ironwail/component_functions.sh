#!/bin/bash

_prepare_component::ironwail() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Ironwail"
      log i "----------------------"

      create_dir "$XDG_CONFIG_HOME/ironwail"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/ironwail"

      # XDG_DATA_HOME must be symlinked to the Ironwail directory for mods to work.

      dir_prep "$roms_path/quake/ironwail" "$XDG_DATA_HOME/ironwail"

      # Quake base id1

      create_dir "$roms_path/quake/ironwail/id1"

      # Quake Expansion Packs

      create_dir "$roms_path/quake/ironwail/ctf"
      create_dir "$roms_path/quake/ironwail/dopa"
      create_dir "$roms_path/quake/ironwail/hipnotic"
      create_dir "$roms_path/quake/ironwail/mg1"
      create_dir "$roms_path/quake/ironwail/mg3"
      create_dir "$roms_path/quake/ironwail/rogue"
      
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Ironwail"
      log i "----------------------"
      
      dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"

    ;;

  esac
}
