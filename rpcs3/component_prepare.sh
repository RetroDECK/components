#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"

  create_dir -d "$XDG_CONFIG_HOME/rpcs3/"
  cp -fr "$component_config/"* "$XDG_CONFIG_HOME/rpcs3/"
  # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
  sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$storage_path/rpcs3/"'^' "$rpcs3_config_vfs"
  set_setting_value "$rpcs3_config_vfs" "/games/" "$roms_path/ps3/" "rpcs3"
  dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
  dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
  create_dir "$storage_path/rpcs3/dev_hdd0"
  create_dir "$storage_path/rpcs3/dev_hdd1"
  create_dir "$storage_path/rpcs3/dev_flash"
  create_dir "$storage_path/rpcs3/dev_flash2"
  create_dir "$storage_path/rpcs3/dev_flash3"
  create_dir "$storage_path/rpcs3/dev_bdvd"
  create_dir "$storage_path/rpcs3/dev_usb000"
  dir_prep "$storage_path/rpcs3/captures" "$XDG_CONFIG_HOME/rpcs3/captures"
  dir_prep "$storage_path/rpcs3/patches" "$XDG_CONFIG_HOME/rpcs3/patches"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
  sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$storage_path/rpcs3/"'^' "$rpcs3_config_vfs"
  set_setting_value "$rpcs3_config_vfs" "/games/" "$roms_path/ps3" "rpcs3"
  dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
  dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
  dir_prep "$storage_path/rpcs3/captures" "$XDG_CONFIG_HOME/rpcs3/captures"
fi
