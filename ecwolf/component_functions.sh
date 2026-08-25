#!/bin/bash

export ecwolf_config="$XDG_CONFIG_HOME/ecwolf_rd.cfg"
export ecwolf_config_path="$XDG_CONFIG_HOME/ecwolf"
export ecwolf_data_saves_path="$XDG_DATA_HOME/ecwolf/saves"
export ecwolf_data_screenshots_path="$XDG_DATA_HOME/ecwolf/screenshots"
export ecwolf_roms_path="$roms_path/wolfenstein"


_prepare_component::ecwolf() {
    # Setting component name and path based on the directory name
    component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    component_config="/app/retrodeck/components/$component_name/rd_config"
    ecwolf_rd_cfg="$XDG_CONFIG_HOME/$component_name/ecwolf_rd.cfg"

    if [[ "$action" == "reset" ]]; then # Run reset-only commands
    log i "----------------------"
    log i "Preparing $component_name"
    log i "----------------------"

    dir_prep "$saves_path/wolfenstein" "$ecwolf_data_saves_path"
    dir_prep "$screenshots_path/ecwolf" "$ecwolf_data_screenshots_path"
    rm -vrf "$ecwolf_rd_cfg"
    create_dir "$ecwolf_config_path"
    cp -v "$component_config/ecwolf_rd.cfg" "$ecwolf_rd_cfg"

    fi

    if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
    log i "----------------------"
    log i "Post-moving $component_name"
    log i "----------------------"

    dir_prep "$saves_path/wolfenstein" "$ecwolf_data_saves_path"
    dir_prep "$screenshots_path/ecwolf" "$ecwolf_data_screenshots_path"
    
    fi    
}

