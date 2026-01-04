#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
  log i "--------------------------------"
  log i "Resetting RetroDECK Framework"
  log i "--------------------------------"

  while read -r config_line; do
    local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
    if [[ ! $current_setting_name =~ (rd_home_path|sdcard) ]]; then # Ignore these locations
      local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
      log d "Read setting: $current_setting_name=$current_setting_value"
      # Extract the part of the setting value after "retrodeck/"
      local relative_path="${current_setting_value#*retrodeck/}"
      # Construct the new setting value
      local new_setting_value="$rd_home_path/$relative_path"
      log d "New setting: $current_setting_name=$new_setting_value"
      # Declare the global variable with the new setting value
      declare -g "$current_setting_name=$new_setting_value"
      export "$current_setting_name"
      log d "Setting: $current_setting_name=$new_setting_value"
      if [[ ! $current_setting_name == "logs_path" ]]; then # Don't create a logs folder normally, this will be a symlink to the internal logs folder in /var/config/retrodeck/logs
        create_dir "$new_setting_value"
      else # Log folder-specific actions
        rm -rf "$logs_path" # Remove the userland logs folder if it exists
        dir_prep "$rd_xdg_config_logs_path" "$logs_path" # Link userland logs folder back to statically-written location
        log d "Logs folder moved to $rd_xdg_config_logs_path and linked back to $logs_path"
      fi
    fi
  done < <(jq -r '.paths | to_entries[] | "\(.key)=\(.value)"' "$rd_conf")

  create_dir -d "$XDG_CONFIG_HOME/retrodeck/graphics"
  cp -rf "/app/retrodeck/graphics/folder-iconsets" "$XDG_CONFIG_HOME/retrodeck/graphics/"
fi

if [[ "$action" == "postmove" ]]; then # Update the paths of any folders that came with the retrodeck folder during a move
  log i "--------------------------------"
  log i "Post-moving RetroDECK Framework"
  log i "--------------------------------"
  
  while read -r config_line; do
    local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
    if [[ ! $current_setting_name =~ (rd_home_path|sdcard) ]]; then # Ignore these locations
      local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
      if [[ -d "$rd_home_path/${current_setting_value#*retrodeck/}" ]]; then # If the folder exists at the new ~/retrodeck location
        declare -g "$current_setting_name=$rd_home_path/${current_setting_value#*retrodeck/}"
        export "$current_setting_name"
      fi
    fi
  done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
  dir_prep "$rd_xdg_config_logs_path" "$logs_path"
fi
