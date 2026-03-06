#!/bin/bash

export cemu_config="$XDG_CONFIG_HOME/Cemu/settings.xml"
export cemu_config_controller0="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller0.xml"
export cemu_config_controller1="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller1.xml"
export cemu_config_controller2="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller2.xml"
export cemu_config_controller3="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller3.xml"
export cemu_textures_path="$XDG_DATA_HOME/Cemu/graphicPacks"
export cemu_shadercache_path="$XDG_CACHE_HOME/Cemu/shaderCache"
export cemu_shadercache_transferable_path="$XDG_CACHE_HOME/Cemu/shaderCache/transferable"

_set_setting_value::cemu() {
  local file="$1" name="$2" value="$3" section="${4:-}"

  local xpath
  if [[ -n "$section" ]]; then
    xpath="/content/${section}/${name}"
  else
    xpath="/content/${name}"
  fi

  xml ed -L -u "$xpath" -v "$value" "$file"
}

_get_setting_value::cemu() {
  local file="$1" name="$2" section="${3:-}"

  local xpath
  if [[ -n "$section" ]]; then
    xpath="/content/${section}/${name}"
  else
    xpath="/content/${name}"
  fi

  xml sel -t -v "$xpath" "$file"
}

_prepare_component::cemu() {
  local action="$1"

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Cemu"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/Cemu/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/Cemu/"
      set_setting_value "$cemu_config" "mlc_path" "$bios_path/cemu" "cemu"
      set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"
      if [[ -e "$bios_path/cemu/keys.txt" ]]; then
        rm -rf "$XDG_DATA_HOME/Cemu/keys.txt" && ln -s "$bios_path/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt" && log d "Linked $bios_path/cemu/keys.txt to $XDG_DATA_HOME/Cemu/keys.txt"
      fi
      dir_prep "$saves_path/wiiu/cemu" "$bios_path/cemu/usr/save"
      dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
      dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Cemu"
      log i "----------------------"
      
      set_setting_value "$cemu_config" "mlc_path" "$bios_path/cemu" "cemu"
      set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"
      dir_prep "$saves_path/wiiu/cemu" "$bios_path/cemu/usr/save"
      dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
      dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"
    ;;

  esac
}
