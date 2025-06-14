#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
config="$component_path/rd_config"
extras="$component_path/rd_extras"

log i "--------------------------------"
log i "Prepearing RetroArch"
log i "--------------------------------"

log d "RetroArch config path: $config/retroarch.cfg"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/retroarch"
        cp -fv "$config/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
        cp -fv "$config/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
    else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/retroarch"
        dir_prep "$bios_folder" "$XDG_CONFIG_HOME/retroarch/system"
        dir_prep "$rdhome/logs/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
        create_dir -d "$XDG_CONFIG_HOME/retroarch/shaders/"
        if [[ -d "$cheats_folder/retroarch" && "$(ls -A "$cheats_folder/retroarch")" ]]; then
            backup_file="$backups_folder/cheats/retroarch-$(date +%y%m%d).tar.gz"
            create_dir "$(dirname "$backup_file")"
            tar -czf "$backup_file" -C "$cheats_folder" retroarch
            log i "RetroArch cheats backed up to $backup_file"
        fi
        create_dir -d "$cheats_folder/retroarch"
        log d "Linking shaders folder to ensure retroarch can find it $XDG_CONFIG_HOME/retroarch/shaders to $shaders_folder/retroarch"
        dir_prep "$shaders_folder/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"
        cp -fv "$config/retroarch.cfg" "$XDG_CONFIG_HOME/retroarch/"
        cp -fv "$config/retroarch-core-options.cfg" "$XDG_CONFIG_HOME/retroarch/"
        rsync -rlD --mkpath "$config/core-overrides/" "$XDG_CONFIG_HOME/retroarch/config/"
        rsync -rlD --mkpath "$config/remaps/" "$XDG_CONFIG_HOME/retroarch/config/remaps/"
        dir_prep "$borders_folder" "$XDG_CONFIG_HOME/retroarch/overlays/borders"
        set_setting_value "$config/retroarch.cfg" "savefile_directory" "$saves_folder" "retroarch"
        set_setting_value "$config/retroarch.cfg" "savestate_directory" "$states_folder" "retroarch"
        set_setting_value "$config/retroarch.cfg" "screenshot_directory" "$screenshots_folder" "retroarch"
        set_setting_value "$config/retroarch.cfg" "log_dir" "$rd_internal_logs_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "rgui_browser_directory" "$roms_folder" "retroarch"
        set_setting_value "$config/retroarch.cfg" "cheat_database_path" "$cheats_folder/retroarch" "retroarch"
        set_setting_value "$config/retroarch.cfg" "assets_directory" "$component_path/assets" "retroarch"
        set_setting_value "$config/retroarch.cfg" "joypad_autoconfig_dir" "$component_path/autoconfig" "retroarch"
        set_setting_value "$config/retroarch.cfg" "cursor_directory" "$component_path/database/cursors" "retroarch"
        set_setting_value "$config/retroarch.cfg" "content_database_path" "$component_path/database/rdb" "retroarch"
    fi

    # Shared actions
    create_dir "$bios_folder/np2kai"
    create_dir "$bios_folder/dc"
    create_dir "$bios_folder/Mupen64plus"
    create_dir "$bios_folder/quasi88"

    retroarch_updater

    # FBNEO
    log i "--------------------------------"
    log i "Prepearing FBNEO_LIBRETRO"
    log i "--------------------------------"
    create_dir "$bios_folder/fbneo/samples"
    # TODO: cheats support
    create_dir "$bios_folder/fbneo/cheats"
    create_dir "$bios_folder/fbneo/blend"
    dir_prep "$mods_folder/FBNeo" "$bios_folder/fbneo/patched"

    # PPSSPP
    log i "--------------------------------"
    log i "Prepearing PPSSPP_LIBRETRO"
    log i "--------------------------------"
    if [ -d "$bios_folder/PPSSPP/flash0/font" ]
    then
        mv -fv "$bios_folder/PPSSPP/flash0/font" "$bios_folder/PPSSPP/flash0/font.bak"
    fi
        cp -rf "$extras/PPSSPP" "$bios_folder/PPSSPP"
    if [ -d "$bios_folder/PPSSPP/flash0/font.bak" ]
    then
        mv -f "$bios_folder/PPSSPP/flash0/font.bak" "$bios_folder/PPSSPP/flash0/font"
    fi

    # MSX / SVI / ColecoVision / SG-1000
    log i "-----------------------------------------------------------"
    log i "Prepearing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
    log i "-----------------------------------------------------------"
    log i "Copying \"$extras/MSX/Databases\" in \"$bios_folder/Databases\""
    cp -rf "$extras/MSX/Databases" "$bios_folder/Databases"
    log i "Copying \"$extras/MSX/Machines\" in \"$bios_folder/Machines\""
    cp -rf "$extras/MSX/Machines" "$bios_folder/Machines"

    # AMIGA
    log i "-----------------------------------------------------------"
    log i "Prepearing AMIGA LIBRETRO"
    log i "-----------------------------------------------------------"
    log i "Copying \"$extras/Amiga/capsimg.so\" in \"$bios_folder/capsimg.so\""
    cp -f "$extras/Amiga/capsimg.so" "$bios_folder/capsimg.so"

    # ScummVM
    log i "-----------------------------------------------------------"
    log i "Prepearing ScummVM LIBRETRO"
    log i "-----------------------------------------------------------"
    cp -fv "$config/scummvm.ini" "$ra_scummvm_conf"
    create_dir "$mods_folder/RetroArch/ScummVM/icons"
    log i "Installing ScummVM assets"
    unzip -o "$config/ScummVM.zip" 'scummvm/extra/*' -d /tmp
    unzip -o "$config/ScummVM.zip" 'scummvm/theme/*' -d /tmp
    mv -f /tmp/scummvm/extra "$mods_folder/RetroArch/ScummVM"
    mv -f /tmp/scummvm/theme "$mods_folder/RetroArch/ScummVM"
    rm -rf /tmp/extra /tmp/theme
    set_setting_value "$ra_scummvm_conf" "iconspath" "$mods_folder/RetroArch/ScummVM/icons" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "extrapath" "$mods_folder/RetroArch/ScummVM/extra" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "themepath" "$mods_folder/RetroArch/ScummVM/theme" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "savepath" "$saves_folder/scummvm" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "browser_lastpath" "$roms_folder/scummvm" "libretro_scummvm" "scummvm"

    dir_prep "$texture_packs_folder/RetroArch-Mesen" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"

    # Reset default preset settings
    set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "cheevos")" "retrodeck" "cheevos"
    set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
    set_setting_value "$rd_conf" "gb" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "gba" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "gbc" "$(get_setting_value "$rd_defaults" "gbc" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "genesis" "$(get_setting_value "$rd_defaults" "genesis" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "gg" "$(get_setting_value "$rd_defaults" "gg" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "n64" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "psx_ra" "$(get_setting_value "$rd_defaults" "psx_ra" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "snes" "retrodeck" "borders")" "retrodeck" "borders"
    set_setting_value "$rd_conf" "genesis" "$(get_setting_value "$rd_defaults" "genesis" "retrodeck" "widescreen")" "retrodeck" "widescreen"
    set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "n64" "retrodeck" "widescreen")" "retrodeck" "widescreen"
    set_setting_value "$rd_conf" "psx_ra" "$(get_setting_value "$rd_defaults" "psx_ra" "retrodeck" "widescreen")" "retrodeck" "widescreen"
    set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "snes" "retrodeck" "widescreen")" "retrodeck" "widescreen"
    set_setting_value "$rd_conf" "gb" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
    set_setting_value "$rd_conf" "gba" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
    set_setting_value "$rd_conf" "gbc" "$(get_setting_value "$rd_defaults" "gbc" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
    set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
    set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
    set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "savestate_auto_load")" "retrodeck" "savestate_auto_load"
    set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$bios_folder" "$XDG_CONFIG_HOME/retroarch/system"
    dir_prep "$rd_internal_logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
    dir_prep "$shaders_folder/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"
    dir_prep "$texture_packs_folder/RetroArch-Mesen" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"
    set_setting_value "$config/retroarch.cfg" "savefile_directory" "$saves_folder" "retroarch"
    set_setting_value "$config/retroarch.cfg" "savestate_directory" "$states_folder" "retroarch"
    set_setting_value "$config/retroarch.cfg" "screenshot_directory" "$screenshots_folder" "retroarch"
    set_setting_value "$config/retroarch.cfg" "log_dir" "$rd_internal_logs_path" "retroarch"
fi
