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

      dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"
      dir_prep "$roms_path/quake/ironwail/mods/bbelief" "$XDG_CONFIG_HOME/ironwail/bbelief"
      dir_prep "$roms_path/quake/ironwail/mods/contract" "$XDG_CONFIG_HOME/ironwail/contract"
      dir_prep "$roms_path/quake/ironwail/mods/darktriad" "$XDG_CONFIG_HOME/ironwail/darktriad"
      dir_prep "$roms_path/quake/ironwail/mods/dmd" "$XDG_CONFIG_HOME/ironwail/dmd"
      dir_prep "$roms_path/quake/ironwail/mods/sm218" "$XDG_CONFIG_HOME/ironwail/sm218"
      dir_prep "$roms_path/quake/ironwail/mods/eod" "$XDG_CONFIG_HOME/ironwail/eod"
      dir_prep "$roms_path/quake/ironwail/mods/eoe" "$XDG_CONFIG_HOME/ironwail/eoe"
      dir_prep "$roms_path/quake/ironwail/mods/euclid" "$XDG_CONFIG_HOME/ironwail/euclid"
      dir_prep "$roms_path/quake/ironwail/mods/honey" "$XDG_CONFIG_HOME/ironwail/honey"
      dir_prep "$roms_path/quake/ironwail/mods/ikspq" "$XDG_CONFIG_HOME/ironwail/ikspq"
      dir_prep "$roms_path/quake/ironwail/mods/insomnia" "$XDG_CONFIG_HOME/ironwail/insomnia"
      dir_prep "$roms_path/quake/ironwail/mods/koohoojam" "$XDG_CONFIG_HOME/ironwail/koohoojam"
      dir_prep "$roms_path/quake/ironwail/mods/mapjamx" "$XDG_CONFIG_HOME/ironwail/mapjamx"
      dir_prep "$roms_path/quake/ironwail/mods/oum" "$XDG_CONFIG_HOME/ironwail/oum"
      dir_prep "$roms_path/quake/ironwail/mods/pun" "$XDG_CONFIG_HOME/ironwail/pun"
      dir_prep "$roms_path/quake/ironwail/mods/qdoom" "$XDG_CONFIG_HOME/ironwail/qdoom"
      dir_prep "$roms_path/quake/ironwail/mods/q64" "$XDG_CONFIG_HOME/ironwail/q64"
      dir_prep "$roms_path/quake/ironwail/mods/tiddles" "$XDG_CONFIG_HOME/ironwail/tiddles"
      dir_prep "$roms_path/quake/ironwail/mods/moon" "$XDG_CONFIG_HOME/ironwail/moon"
      dir_prep "$roms_path/quake/ironwail/mods/rubicon2" "$XDG_CONFIG_HOME/ironwail/rubicon2"
      dir_prep "$roms_path/quake/ironwail/mods/sacrilege" "$XDG_CONFIG_HOME/ironwail/sacrilege"
      dir_prep "$roms_path/quake/ironwail/mods/enyo" "$XDG_CONFIG_HOME/ironwail/enyo"
      dir_prep "$roms_path/quake/ironwail/mods/spiritworld" "$XDG_CONFIG_HOME/ironwail/spiritworld"
      dir_prep "$roms_path/quake/ironwail/mods/squire" "$XDG_CONFIG_HOME/ironwail/squire"
      dir_prep "$roms_path/quake/ironwail/mods/tainted" "$XDG_CONFIG_HOME/ironwail/tainted"
      dir_prep "$roms_path/quake/ironwail/mods/terra" "$XDG_CONFIG_HOME/ironwail/terra"
      dir_prep "$roms_path/quake/ironwail/mods/ttb" "$XDG_CONFIG_HOME/ironwail/ttb"
      dir_prep "$roms_path/quake/ironwail/mods/udob" "$XDG_CONFIG_HOME/ironwail/udob"
      dir_prep "$roms_path/quake/ironwail/mods/vestige" "$XDG_CONFIG_HOME/ironwail/vestige"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Ironwail"
      log i "----------------------"
      
    dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"
    dir_prep "$roms_path/quake/ironwail/mods/bbelief" "$XDG_CONFIG_HOME/ironwail/bbelief"
    dir_prep "$roms_path/quake/ironwail/mods/contract" "$XDG_CONFIG_HOME/ironwail/contract"
    dir_prep "$roms_path/quake/ironwail/mods/darktriad" "$XDG_CONFIG_HOME/ironwail/darktriad"
    dir_prep "$roms_path/quake/ironwail/mods/dmd" "$XDG_CONFIG_HOME/ironwail/dmd"
    dir_prep "$roms_path/quake/ironwail/mods/sm218" "$XDG_CONFIG_HOME/ironwail/sm218"
    dir_prep "$roms_path/quake/ironwail/mods/eod" "$XDG_CONFIG_HOME/ironwail/eod"
    dir_prep "$roms_path/quake/ironwail/mods/eoe" "$XDG_CONFIG_HOME/ironwail/eoe"
    dir_prep "$roms_path/quake/ironwail/mods/euclid" "$XDG_CONFIG_HOME/ironwail/euclid"
    dir_prep "$roms_path/quake/ironwail/mods/honey" "$XDG_CONFIG_HOME/ironwail/honey"
    dir_prep "$roms_path/quake/ironwail/mods/ikspq" "$XDG_CONFIG_HOME/ironwail/ikspq"
    dir_prep "$roms_path/quake/ironwail/mods/insomnia" "$XDG_CONFIG_HOME/ironwail/insomnia"
    dir_prep "$roms_path/quake/ironwail/mods/koohoojam" "$XDG_CONFIG_HOME/ironwail/koohoojam"
    dir_prep "$roms_path/quake/ironwail/mods/mapjamx" "$XDG_CONFIG_HOME/ironwail/mapjamx"
    dir_prep "$roms_path/quake/ironwail/mods/oum" "$XDG_CONFIG_HOME/ironwail/oum"
    dir_prep "$roms_path/quake/ironwail/mods/pun" "$XDG_CONFIG_HOME/ironwail/pun"
    dir_prep "$roms_path/quake/ironwail/mods/qdoom" "$XDG_CONFIG_HOME/ironwail/qdoom"
    dir_prep "$roms_path/quake/ironwail/mods/q64" "$XDG_CONFIG_HOME/ironwail/q64"
    dir_prep "$roms_path/quake/ironwail/mods/tiddles" "$XDG_CONFIG_HOME/ironwail/tiddles"
    dir_prep "$roms_path/quake/ironwail/mods/moon" "$XDG_CONFIG_HOME/ironwail/moon"
    dir_prep "$roms_path/quake/ironwail/mods/rubicon2" "$XDG_CONFIG_HOME/ironwail/rubicon2"
    dir_prep "$roms_path/quake/ironwail/mods/sacrilege" "$XDG_CONFIG_HOME/ironwail/sacrilege"
    dir_prep "$roms_path/quake/ironwail/mods/enyo" "$XDG_CONFIG_HOME/ironwail/enyo"
    dir_prep "$roms_path/quake/ironwail/mods/spiritworld" "$XDG_CONFIG_HOME/ironwail/spiritworld"
    dir_prep "$roms_path/quake/ironwail/mods/squire" "$XDG_CONFIG_HOME/ironwail/squire"
    dir_prep "$roms_path/quake/ironwail/mods/tainted" "$XDG_CONFIG_HOME/ironwail/tainted"
    dir_prep "$roms_path/quake/ironwail/mods/terra" "$XDG_CONFIG_HOME/ironwail/terra"
    dir_prep "$roms_path/quake/ironwail/mods/ttb" "$XDG_CONFIG_HOME/ironwail/ttb"
    dir_prep "$roms_path/quake/ironwail/mods/udob" "$XDG_CONFIG_HOME/ironwail/udob"
    dir_prep "$roms_path/quake/ironwail/mods/vestige" "$XDG_CONFIG_HOME/ironwail/vestige"
    ;;

  esac
}
