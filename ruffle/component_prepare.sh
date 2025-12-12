#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/ruffle/"
  cp -fv "$component_config/"* "$XDG_CONFIG_HOME/ruffle/"
  dir_prep "$saves_path/flash/ruffle" "$ruffle_saves_path"
  dir_prep "$logs_path/ruffle" "$ruffle_logs_path"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_path/flash/ruffle" "$ruffle_saves_path"
  dir_prep "$logs_path/ruffle" "$ruffle_logs_path"
fi