#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "------------------------"
    log i "Prepearing RPCS3"
    log i "------------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        cp -fr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/rpcs3" "$XDG_CONFIG_HOME/rpcs3"

    else # Single-user actions

        create_dir -d "$XDG_CONFIG_HOME/rpcs3/"
        cp -fr "$config/"* "$XDG_CONFIG_HOME/rpcs3/"
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$rpcs3vfsconf"
        set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$saves_folder/ps3/rpcs3" "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata"
        dir_prep "$states_folder/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
    fi

    # Shared actions
    create_dir "$bios_folder/rpcs3/dev_hdd0"
    create_dir "$bios_folder/rpcs3/dev_hdd1"
    create_dir "$bios_folder/rpcs3/dev_flash"
    create_dir "$bios_folder/rpcs3/dev_flash2"
    create_dir "$bios_folder/rpcs3/dev_flash3"
    create_dir "$bios_folder/rpcs3/dev_bdvd"
    create_dir "$bios_folder/rpcs3/dev_usb000"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
    sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3"'^' "$rpcs3vfsconf"
    set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3" "rpcs3"
fi