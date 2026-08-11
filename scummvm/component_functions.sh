#!/bin/bash

scummvm_config="$XDG_CONFIG_HOME/scummvm/scummvm.ini"

_prepare_component::scummvm() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting ScummVM"
      log i "----------------------"

        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/scummvm/"

        create_dir -d "$screenshots_path/scummvm"
        create_dir -d "$saves_path/scummvm/scummvm-sa"
        create_dir -d "$storage_path/scummvm/extra"
        create_dir -d "$storage_path/scummvm/themes"

        sed -i "s|^screenshotpath= .*|screenshotpath=$screenshots_path/scummvm|" $scummvm_config
        sed -i "s|^savepath= .*|savepath=$saves_path/scummvm/scummvm-sa|" $scummvm_config

        sed -i "s|^extrapath= .*|extrapath=$storage_path/scummvm/extra|" $scummvm_config
        sed -i "s|^themepath= .*|themepath=$storage_path/scummvm/themes|" $scummvm_config
      
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving ScummVM"
      log i "----------------------"

        sed -i "s|^screenshotpath= .*|screenshotpath=$screenshots_path/scummvm|" $scummvm_config
        sed -i "s|^savepath= .*|savepath=$saves_path/scummvm/scummvm-sa|" $scummvm_config

        sed -i "s|^extrapath= .*|extrapath=$storage_path/scummvm/extra|" $scummvm_config
        sed -i "s|^themepath= .*|themepath=$storage_path/scummvm/themes|" $scummvm_config

    ;;
    
  esac
}
