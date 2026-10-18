#!/bin/bash

export ruffle_config="$XDG_CONFIG_HOME/ruffle/preferences.toml"
export ruffle_logs_path="$XDG_CACHE_HOME/ruffle/log"
export ruffle_saves_path="$XDG_DATA_HOME/ruffle/SharedObjects"

_set_setting_value::ruffle() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  sed -i 's^\^'"$name"' = ".*"^'"$name"' = "'"$value"'"^' "$file"
}

_get_setting_value::ruffle() {
  local file="$1" name="$2"

  sed -n 's^'"$(sed_escape_pattern "$name")"' = "\(.*\)"^\1^p' "$file"
}

_prepare_component::ruffle() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Ruffle"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/ruffle/"
      cp -fv "$component_config/"* "$XDG_CONFIG_HOME/ruffle/"

      dir_prep "$saves_path/Ruffle-SA/SharedObjects" "$ruffle_saves_path"
      dir_prep "$logs_path/Ruffle" "$ruffle_logs_path"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Ruffle"
      log i "------------------------"

      dir_prep "$saves_path/Ruffle-SA/SharedObjects" "$ruffle_saves_path"
      dir_prep "$logs_path/Ruffle" "$ruffle_logs_path"
      
    ;;

  esac
}

_post_update::ruffle() {
  local previous_version="$1"

 if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Upgrade - Ruffle RA Conflict Migration"

    dir_prep "$saves_path/Ruffle-SA/SharedObjects" "$ruffle_saves_path"

    cp -rfv "$saves_path/flash/ruffle" "$saves_path/Ruffle-SA/SharedObjects"

    create_dir "$backups_path/0.11.0/Ruffle-SA/SharedObjects"

    cp -rfv "$saves_path/flash/ruffle" "$backups_path/0.11.0/Ruffle-SA/SharedObjects"
 fi

}

_post_update_legacy::ruffle() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.9.0b"; then
    log i "New components were added in this version, initializing them"
    prepare_component "reset" "ruffle"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # Fixes issue with save folder not being set, a full reset is needed.

    log i "0.10.0b Upgrade - Reset: Ruffle"
    prepare_component "reset" "ruffle"    
  fi
}
