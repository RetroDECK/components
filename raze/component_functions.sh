#!/bin/bash

export raze_config="$XDG_CONFIG_HOME/raze/.config/raze/raze.ini"

_prepare_component::raze() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Raze"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/raze/.config/raze"
      cp -fv "$component_config/"* "$XDG_CONFIG_HOME/raze/.config/raze"

      create_dir -d "$saves_path/raze"      
      create_dir -d "$logs_path/raze"   
      create_dir -d "$storage_path/raze/soundfonts"
      create_dir -d "$screenhots_path/raze"           

      sed -i "s|^Path=RETRODECKROMSDIR*|Path=$roms_path/raze|" $raze_config
      sed -i "s|^Path=RETRODECKSTORAGEDIR/raze/soundfonts*|Path=$storage_path/raze/soundfonts|" $raze_config
      sed -i "s|^save_dir=RETRODECKSAVEDIR*|save_dir=$saves_path/raze|" $raze_config
      sed -i "s|^screenshot_dir=RETRODECKSAVEDIR*|screenshot_dir=$screenshots_path/raze|" $raze_config

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Raze"
      log i "------------------------"

      sed -i "s|^Path=RETRODECKROMSDIR*|Path=$roms_path/raze|" $raze_config
      sed -i "s|^Path=RETRODECKSTORAGEDIR/raze/soundfonts*|Path=$storage_path/raze/soundfonts|" $raze_config
      sed -i "s|^save_dir=RETRODECKSAVEDIR*|save_dir=$saves_path/raze|" $raze_config
      sed -i "s|^screenshot_dir=RETRODECKSAVEDIR*|screenshot_dir=$screenshots_path/raze|" $raze_config
      
    ;;

  esac
}


