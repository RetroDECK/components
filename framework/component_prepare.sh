#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/components/$component_name/rd_config"

log i "--------------------------------"
log i "Prepearing RetroDECK Framework"
log i "--------------------------------"

if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
    while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
        local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
        log d "Red setting: $current_setting_name=$current_setting_value"
        # Extract the part of the setting value after "retrodeck/"
        local relative_path="${current_setting_value#*retrodeck/}"
        # Construct the new setting value
        local new_setting_value="$rdhome/$relative_path"
        log d "New setting: $current_setting_name=$new_setting_value"
        # Declare the global variable with the new setting value
        declare -g "$current_setting_name=$new_setting_value"
        log d "Setting: $current_setting_name=$current_setting_value"
        if [[ ! $current_setting_name == "logs_folder" ]]; then # Don't create a logs folder normally, we want to maintain the current files exactly to not lose early-install logs.
            create_dir "$new_setting_value"
        else # Log folder-specific actions
            mv "$rd_logs_folder" "$logs_folder" # Move existing logs folder from internal to userland
            ln -sf "$logs_folder" "$rd_logs_folder" # Link userland logs folder back to statically-written location
            log d "Logs folder moved to $logs_folder and linked back to $rd_logs_folder"
        fi
        fi
    done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    create_dir "$XDG_CONFIG_HOME/retrodeck/godot" # TODO: what is this for? Can we delete it or add it to the retrodeck.cfg so the folder will be created by the above script?
fi

if [[ "$action" == "postmove" ]]; then # Update the paths of any folders that came with the retrodeck folder during a move
    while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
        local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
        if [[ -d "$rdhome/${current_setting_value#*retrodeck/}" ]]; then # If the folder exists at the new ~/retrodeck location
            declare -g "$current_setting_name=$rdhome/${current_setting_value#*retrodeck/}"
        fi
        fi
    done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    dir_prep "$logs_folder" "$rd_logs_folder"
fi
