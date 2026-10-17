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
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Cemu"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/Cemu/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/Cemu/"

      create_dir "$bios_path/Cemu-SA"
      create_dir "$saves_path/wiiu/Cemu-SA/mlc01"

      ln -sfn "$bios_path/Cemu-SA/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt"

      dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
      dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"

      set_setting_value "$cemu_config" "mlc_path" "$saves_path/Cemu-SA/mlc01" "cemu"
      set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"



    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Cemu"
      log i "----------------------"
      
      dir_prep "$texture_packs_path/Cemu/graphicPacks" "$cemu_textures_path"
      dir_prep "$shaders_path/Cemu/transferable" "$cemu_shadercache_transferable_path"

      ln -sfn "$bios_path/Cemu-SA/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt"

      set_setting_value "$cemu_config" "mlc_path" "$saves_path/Cemu-SA/mlc01" "cemu"
      set_setting_value "$cemu_config" "Entry" "$roms_path/wiiu" "cemu" "GamePaths"

    ;;

  esac
}

_post_update::cemu() {
  local previous_version="$1"

}

_post_update_legacy::cemu() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Init Cemu as it is a new emulator

    prepare_component "reset" "cemu"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    log i "0.10.0b Upgrade - Postmove: Cemu"

    prepare_component "reset" "cemu"
  fi

    if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0b Upgrade - Transfer to Cemu-SA"

    set_setting_value "$cemu_config" "mlc_path" "$saves_path/Cemu-SA/mlc01" "cemu"

    create_dir "$bios_path/Cemu-SA"

    cp -rfv "$bios_path/cemu/keys.txt" "$bios_path/Cemu-SA"
    ln -sfn "$bios_path/Cemu-SA/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt"

    create_dir "$backups_path/0.11.0/Cemu-SA/mlc01/usr/save"
    create_dir "$saves_path/wiiu/Cemu-SA/mlc01/usr/save"

    cp -rfv "$bios_path/cemu" "$backups_path/0.11.0/Cemu-SA/mlc01"
    cp -rfv "$saves_path/wiiu/cemu" "$backups_path/0.11.0/Cemu-SA/mlc01"

    cp -rfv "$bios_path/cemu" "$saves_path/wiiu/Cemu-SA/mlc01"
    cp -rfv "$saves_path/wiiu/cemu" "$saves_path/wiiu/Cemu-SA/mlc01/usr/save"

  fi

}
