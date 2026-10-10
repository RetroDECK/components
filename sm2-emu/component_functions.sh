#!/bin/bash

export sm2_emu_config="$XDG_CONFIG_HOME/sm2-emu/sm2-emu.ini"

_prepare_component::sm2-emu() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting sm2-emu"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/sm2-emu"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/sm2-emu"

      create_dir -d "$saves_path/model2/sm2-emu"
      create_dir -d "$screenshots_path/sm2-emu"

      dir_prep "$texture_packs_path/sm2-emu/textures" "$saves_path/model2/sm2-emu/textures"

      sed -i "s|^rom_dir =.*|rom_dir = $roms_path/model2|" $sm2_emu_config
      sed -i "s|^nvram_dir =.*|nvram_dir = $saves_path/model2/sm2-emu|" $sm2_emu_config
      sed -i "s|^screenshot_dir =.*|screenshot_dir = $screenshots_path/sm2-emu|" $sm2_emu_config

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving sm2-emu"
          log i "----------------------"

      dir_prep "$texture_packs_path/sm2-emu/textures" "$saves_path/model2/sm2-emu/textures"

      sed -i "s|^rom_dir =.*|rom_dir = $roms_path/model2|" $sm2_emu_config
      sed -i "s|^nvram_dir =.*|nvram_dir = $saves_path/model2/sm2-emu|" $sm2_emu_config
      sed -i "s|^screenshot_dir =.*|screenshot_dir = $screenshots_path/sm2-emu|" $sm2_emu_config


    ;;

  esac
}