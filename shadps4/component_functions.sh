#!/bin/bash

export shadps4_config="$XDG_DATA_HOME/shadPS4/config.json"
export shadps4_input_config_dir="$XDG_DATA_HOME/shadPS4/input_config/"
export shadps4_input_config="$XDG_DATA_HOME/shadPS4/input_config/default.ini"
export shadps4_qt_ui_config="$XDG_DATA_HOME/shadPS4QtLauncher/qt_ui.ini"

_prepare_component::shadps4() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
        log i "--------------------"
        log i "Preparing shadPS4"
        log i "--------------------"

        create_dir -d "$XDG_DATA_HOME/shadPS4/"
        create_dir -d "$XDG_CONFIG_HOME/shadPS4/"
        cp -f "$component_config/shadPS4" "$XDG_DATA_HOME/shadPS4" 
        cp -f "$component_config/shadPS4QtLauncher" "$XDG_DATA_HOME/shadPS4QtLauncher" 
        cp -f "$component_config/lsfg-vk" "$XDG_CONFIG_HOME/lsfg-vk"

        # Storage Installed Game Path

        create_dir -d "$storage_path/shadPS4/installed"
        jq --arg path "$storage_path/shadPS4/installed" '.install_dirs |= map(.path = $path)' "$shadps4_config" 

        # Storage
        dir_prep "$storage_path/shadPS4/addcont" "$XDG_DATA_HOME/shadPS4/addcont"
        dir_prep "$storage_path/shadPS4/captures" "$XDG_DATA_HOME/shadPS4/captures"
        dir_prep "$storage_path/shadPS4/custom_configs" "$XDG_DATA_HOME/shadPS4/custom_configs"
        dir_prep "$storage_path/shadPS4/custom_trophy" "$XDG_DATA_HOME/shadPS4/custom_trophy"
        dir_prep "$storage_path/shadPS4/data" "$XDG_DATA_HOME/shadPS4/data" 
        dir_prep "$storage_path/shadPS4/game_data" "$XDG_DATA_HOME/shadPS4/game_data" 
        dir_prep "$storage_path/shadPS4/download" "$XDG_DATA_HOME/shadPS4/download" 
        dir_prep "$storage_path/shadPS4/fonts" "$XDG_DATA_HOME/shadPS4/fonts" 

        dir_prep "$storage_path/shadPS4/sys_modules" "$XDG_DATA_HOME/shadPS4/sys_modules" 

        # Cheats
        dir_prep "$cheats_path/shadPS4/cheats" "$XDG_DATA_HOME/shadPS4/cheats"

        # Mods
        dir_prep "$mods_path/shadPS4/patches" "$XDG_DATA_HOME/shadPS4/patches" 

        # Saves
        dir_prep "$saves_path/shadPS4-SA/home" "$XDG_DATA_HOME/shadPS4/home"
        dir_prep "$saves_path/shadPS4-SA/trophy" "$XDG_DATA_HOME/shadPS4/trophy"

        # Log
        dir_prep "$logs_path/shadPS4/" "$XDG_DATA_HOME/shadPS4/log"

        # Screenshots
        dir_prep "$screenshots_path/shadPS4/screenshots" "$XDG_DATA_HOME/shadPS4/screenshots"

        # shader
        dir_prep "$shaders_path/shadPS4/shader" "$XDG_DATA_HOME/shadPS4/shader"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving shadPS4"
      log i "------------------------"

        # Storage Installed Game Path
        jq --arg path "$storage_path/shadPS4/installed" '.install_dirs |= map(.path = $path)' "$shadps4_config" 

        # Storage
        dir_prep "$storage_path/shadPS4/addcont" "$XDG_DATA_HOME/shadPS4/addcont"
        dir_prep "$storage_path/shadPS4/captures" "$XDG_DATA_HOME/shadPS4/captures"
        dir_prep "$storage_path/shadPS4/custom_configs" "$XDG_DATA_HOME/shadPS4/custom_configs"
        dir_prep "$storage_path/shadPS4/custom_trophy" "$XDG_DATA_HOME/shadPS4/custom_trophy"
        dir_prep "$storage_path/shadPS4/data" "$XDG_DATA_HOME/shadPS4/data" 
        dir_prep "$storage_path/shadPS4/game_data" "$XDG_DATA_HOME/shadPS4/game_data" 
        dir_prep "$storage_path/shadPS4/download" "$XDG_DATA_HOME/shadPS4/download" 
        dir_prep "$storage_path/shadPS4/fonts" "$XDG_DATA_HOME/shadPS4/fonts" 

        dir_prep "$storage_path/shadPS4/sys_modules" "$XDG_DATA_HOME/shadPS4/sys_modules" 

        # Cheats
        dir_prep "$cheats_path/shadPS4/cheats" "$XDG_DATA_HOME/shadPS4/cheats"

        # Mods
        dir_prep "$mods_path/shadPS4/patches" "$XDG_DATA_HOME/shadPS4/patches" 

        # Saves
        dir_prep "$saves_path/shadPS4-SA/home" "$XDG_DATA_HOME/shadPS4/home"
        dir_prep "$saves_path/shadPS4-SA/trophy" "$XDG_DATA_HOME/shadPS4/trophy"

        # Log
        dir_prep "$logs_path/shadPS4/" "$XDG_DATA_HOME/shadPS4/log"

        # Screenshots
        dir_prep "$screenshots_path/shadPS4/screenshots" "$XDG_DATA_HOME/shadPS4/screenshots"

        # shader
        dir_prep "$shaders_path/shadPS4/shader" "$XDG_DATA_HOME/shadPS4/shader"

    ;;

    startup)

    ;;

  esac
}

_post_update::shadps4() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 shadPS4 Setup"

    prepare_component "reset" "shadps4"
  fi
}