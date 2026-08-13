#!/bin/bash

export sdl2trs_config="$XDG_CONFIG_HOME/sdl2trs/.sdltrs.t8c"

_prepare_component::sdl2trs() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting SDL2TRS"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/sdl2trs/"
      cp -f "$component_config/sdltrs.t8c" "$XDG_CONFIG_HOME/sdl2trs/.sdltrs.t8c"
      
      create_dir -d "$states_path/trs-80"
      create_dir -d "$storage_path/SDL2TRS/printer"

      sed -i "s|^statedir=.*|statedir=$states_path/trs-80|" $sdl2trs_config

      sed -i "s|^romfile1=.*|romfile1=$bios_path/level2.rom|" $sdl2trs_config
      sed -i "s|^romfile3=.*|romfile3=$bios_path/model3.rom|" $sdl2trs_config
      sed -i "s|^romfile4p=.*|romfile4p=$bios_path/model4p.rom|" $sdl2trs_config

      sed -i "s|^cassdir=.*|cassdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^diskdir=.*|diskdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^disksetdir=.*|disksetdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^harddir=.*|harddir=$roms_path/trs-80|" $sdl2trs_config

      sed -i "s|^printerdir=.*|printerdir=$storage_path/SDL2TRS/printer|" $sdl2trs_config

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving SDL2TRS"
      log i "----------------------"

      sed -i "s|^statedir=.*|statedir=$states_path/trs-80|" $sdl2trs_config

      sed -i "s|^romfile1=.*|romfile1=$bios_path/level2.rom|" $sdl2trs_config
      sed -i "s|^romfile3=.*|romfile3=$bios_path/model3.rom|" $sdl2trs_config
      sed -i "s|^romfile4p=.*|romfile4p=$bios_path/model4p.rom|" $sdl2trs_config

      sed -i "s|^cassdir=.*|cassdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^diskdir=.*|diskdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^disksetdir=.*|disksetdir=$roms_path/trs-80|" $sdl2trs_config
      sed -i "s|^harddir=.*|harddir=$roms_path/trs-80|" $sdl2trs_config

      sed -i "s|^printerdir=.*|printerdir=$storage_path/SDL2TRS|" $sdl2trs_config

    ;;
    
  esac
}