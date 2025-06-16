#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
config="$component_path/rd_config"
extras="$component_path/rd_extras"

log i "--------------------------------"
log i "Preparing $component_name"
log i "--------------------------------"

log d "RetroArch config path: $config/retroarch.cfg"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/retroarch"
        cp -fv "$config/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
        cp -fv "$config/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
    else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/retroarch"
        dir_prep "$rd_home_bios_path" "$XDG_CONFIG_HOME/retroarch/system"
        dir_prep "$rd_home_path/logs/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
        create_dir -d "$XDG_CONFIG_HOME/retroarch/shaders/"
        if [[ -d "$rd_home_cheats_path/retroarch" && "$(ls -A "$rd_home_cheats_path/retroarch")" ]]; then
            backup_file="$rd_home_backups_path/cheats/retroarch-$(date +%y%m%d).tar.gz"
            create_dir "$(dirname "$backup_file")"
            tar -czf "$backup_file" -C "$rd_home_cheats_path" retroarch
            log i "RetroArch cheats backed up to $backup_file"
        fi
        create_dir -d "$rd_home_cheats_path/retroarch"
        log d "Linking shaders folder to ensure retroarch can find it $XDG_CONFIG_HOME/retroarch/shaders to $rd_home_shaders_path/retroarch"
        dir_prep "$rd_home_shaders_path/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"
        cp -fv "$config/retroarch.cfg" "$XDG_CONFIG_HOME/retroarch/"
        cp -fv "$config/retroarch-core-options.cfg" "$XDG_CONFIG_HOME/retroarch/"
        rsync -rlD --mkpath "$config/core-overrides/" "$XDG_CONFIG_HOME/retroarch/config/"
        rsync -rlD --mkpath "$config/remaps/" "$XDG_CONFIG_HOME/retroarch/config/remaps/"
        dir_prep "$rd_home_borders_path" "$XDG_CONFIG_HOME/retroarch/overlays/borders"
        set_setting_value "$config/retroarch.cfg" "savefile_directory" "$rd_home_saves_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "savestate_directory" "$rd_home_states_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "screenshot_directory" "$rd_home_screenshots_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "log_dir" "$rd_internal_logs_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "rgui_browser_directory" "$rd_home_roms_path" "retroarch"
        set_setting_value "$config/retroarch.cfg" "cheat_database_path" "$rd_home_cheats_path/retroarch" "retroarch"
        set_setting_value "$config/retroarch.cfg" "assets_directory" "$component_path/assets" "retroarch"
        set_setting_value "$config/retroarch.cfg" "joypad_autoconfig_dir" "$component_path/autoconfig" "retroarch"
        set_setting_value "$config/retroarch.cfg" "cursor_directory" "$component_path/database/cursors" "retroarch"
        set_setting_value "$config/retroarch.cfg" "content_database_path" "$component_path/database/rdb" "retroarch"
    fi

    # Shared actions
    create_dir "$rd_home_bios_path/np2kai"
    create_dir "$rd_home_bios_path/dc"
    create_dir "$rd_home_bios_path/Mupen64plus"
    create_dir "$rd_home_bios_path/quasi88"

    retroarch_updater

    # FBNEO
    log i "--------------------------------"
    log i "Prepearing FBNEO_LIBRETRO"
    log i "--------------------------------"
    create_dir "$rd_home_bios_path/fbneo/samples"
    # TODO: cheats support
    create_dir "$rd_home_bios_path/fbneo/cheats"
    create_dir "$rd_home_bios_path/fbneo/blend"
    dir_prep "$rd_home_mods_path/FBNeo" "$rd_home_bios_path/fbneo/patched"

    # PPSSPP
    log i "--------------------------------"
    log i "Prepearing PPSSPP_LIBRETRO"
    log i "--------------------------------"
    if [ -d "$rd_home_bios_path/PPSSPP/flash0/font" ]
    then
        mv -fv "$rd_home_bios_path/PPSSPP/flash0/font" "$rd_home_bios_path/PPSSPP/flash0/font.bak"
    fi
        cp -rf "$extras/PPSSPP" "$rd_home_bios_path/PPSSPP"
    if [ -d "$rd_home_bios_path/PPSSPP/flash0/font.bak" ]
    then
        mv -f "$rd_home_bios_path/PPSSPP/flash0/font.bak" "$rd_home_bios_path/PPSSPP/flash0/font"
    fi

    # MSX / SVI / ColecoVision / SG-1000
    log i "-----------------------------------------------------------"
    log i "Prepearing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
    log i "-----------------------------------------------------------"
    log i "Copying \"$extras/MSX/Databases\" in \"$rd_home_bios_path/Databases\""
    cp -rf "$extras/MSX/Databases" "$rd_home_bios_path/Databases"
    log i "Copying \"$extras/MSX/Machines\" in \"$rd_home_bios_path/Machines\""
    cp -rf "$extras/MSX/Machines" "$rd_home_bios_path/Machines"

    # AMIGA
    log i "-----------------------------------------------------------"
    log i "Prepearing AMIGA LIBRETRO"
    log i "-----------------------------------------------------------"
    log i "Copying \"$extras/Amiga/capsimg.so\" in \"$rd_home_bios_path/capsimg.so\""
    cp -f "$extras/Amiga/capsimg.so" "$rd_home_bios_path/capsimg.so"

    # ScummVM
    log i "-----------------------------------------------------------"
    log i "Prepearing ScummVM LIBRETRO"
    log i "-----------------------------------------------------------"
    cp -fv "$config/scummvm.ini" "$ra_scummvm_conf"
    create_dir "$rd_home_mods_path/RetroArch/ScummVM/icons"
    log i "Installing ScummVM assets"
    unzip -o "$config/ScummVM.zip" 'scummvm/extra/*' -d /tmp
    unzip -o "$config/ScummVM.zip" 'scummvm/theme/*' -d /tmp
    mv -f /tmp/scummvm/extra "$rd_home_storage_path/retroarch/ScummVM"
    mv -f /tmp/scummvm/theme "$rd_home_storage_path/retroarch/ScummVM"
    rm -rf /tmp/extra /tmp/theme
    set_setting_value "$ra_scummvm_conf" "iconspath" "$rd_home_storage_path/retroarch/ScummVM/icons" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "extrapath" "$rd_home_storage_path/retroarch/ScummVM/extra" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "themepath" "$rd_home_storage_path/retroarch/ScummVM/theme" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "savepath" "$rd_home_saves_path/scummvm" "libretro_scummvm" "scummvm"
    set_setting_value "$ra_scummvm_conf" "browser_lastpath" "$rd_home_roms_path/scummvm" "libretro_scummvm" "scummvm"

    dir_prep "$rd_home_texture_packs_path/retroarch/Mesen" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
    dir_prep "$rd_home_texture_packs_path/retroarch/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
    dir_prep "$rd_home_texture_packs_path/retroarch/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"

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
    dir_prep "$rd_home_bios_path" "$XDG_CONFIG_HOME/retroarch/system"
    dir_prep "$rd_internal_logs_path/retroarch" "$XDG_CONFIG_HOME/retroarch/logs"
    dir_prep "$rd_home_shaders_path/retroarch" "$XDG_CONFIG_HOME/retroarch/shaders"
    dir_prep "$rd_home_texture_packs_path/retroarch/Mesen" "$XDG_CONFIG_HOME/retroarch/system/HdPacks"
    dir_prep "$rd_home_texture_packs_path/retroarch/Mupen64Plus/cache" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/cache"
    dir_prep "$rd_home_texture_packs_path/retroarch/Mupen64Plus/hires_texture" "$XDG_CONFIG_HOME/retroarch/system/Mupen64plus/hires_texture"
    set_setting_value "$config/retroarch.cfg" "savefile_directory" "$rd_home_saves_path" "retroarch"
    set_setting_value "$config/retroarch.cfg" "savestate_directory" "$rd_home_states_path" "retroarch"
    set_setting_value "$config/retroarch.cfg" "screenshot_directory" "$rd_home_screenshots_path" "retroarch"
    set_setting_value "$config/retroarch.cfg" "log_dir" "$rd_internal_logs_path" "retroarch"
fi
