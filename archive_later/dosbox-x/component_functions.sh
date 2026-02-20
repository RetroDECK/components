#!/bin/bash

dosbox_x_config="$XDG_CONFIG_HOME/dosbox-x/dosbox-x.conf"
dosbox_x_mapper="$XDG_CONFIG_HOME/dosbox-x/mapper-dosbox-x.map"
dosbox_x_os_configs_dir="$component_config/os_configs"
winplay="open_component dosbox-x"

dosbox_x_install_win98() {
    log i "DosBox-X Windows 98 Installer started"
    if [ -f "$storage_path/dosbox-x/win98.vhd" ]; then
        log i "Existing Windows 98 installation found."
        rd_zenity --question --text="An existing Windows 98 installation was found at \"$storage_path/dosbox-x/win98.vhd\".\n\nDo you want to run this existing installation instead of creating a new one?" --ok-label="Use Existing" --cancel-label="Create New"
        if [ $? -eq 0 ]; then
            log i "User chose to use the existing Windows 98 installation for DOSBox-X"
            dosbox_x_run_win98
            return
        else
            log i "User chose to create a new Windows 98 installation for DOSBox-X, existing installation will be overwritten"
            rd_zenity --question --text="Are you sure you want to create a new Windows 98 installation? This will overwrite the existing installation and all its data at \"$storage_path/dosbox-x/win98.vhd\"." --ok-label="Yes, Create New" --cancel-label="No, Keep Existing"
            if [ $? -ne 0 ]; then
                log i "User aborted creating a new Windows 98 installation for DOSBox-X, existing installation will be kept"
                return
            else
                log i "User confirmed creating a new Windows 98 installation for DOSBox-X"
                rm -f "$storage_path/dosbox-x/win98.vhd"
            fi
        fi
    fi
    rd_zenity --info --text="This will create a disk layer in DOSBox-X on which you can install Windows 98.\nPlease select the CD-ROM image file for Windows 98 installation.\n\nNOTE: you will need a legit Windows 98 CD Key to complete the installation." --ok-label="Proceed" --cancel-label="Abort"
    win98_cdrom=$(file_browse "This will install Windows 98 in DOSBox-X.\nSelect the CD-ROM image file for Windows 98 installation") || exit 0
    $winplay --makefs win98
    if ( $winplay --install win98 --cd-rom "$win98_cdrom" ); then
        log i "Windows 98 installation completed successfully"
        rd_zenity --info --text="First step of Windows 98 installation completed successfully.\n\nNow Windows 98 will boot.\nPlease prepare the environment like setting your desired resolution and colors.\nWhen finished please turn off Windows 98 from the Start menu to end the installation and save the changes to the disk layer."
        dosbox_x_run_win98
        rd_zenity --info --text="Windows 98 installation completed successfully.\nYou can now run install games in this Windows 98 environment using the 'DOSBox-X: Install Windows 98 Game' option in the Configurator."
    else
        log i "Windows 98 installation aborted"
    fi
}

dosbox_x_run_win98() {
    log i "DosBox-X starting Windows 98 layer"
    rd_zenity --info --text="WARNING: editing Windows 98 Installation might cause to break already installed games.\nMake sure to backup your Windows 98 installation layer before making any changes."
    $winplay --desktop win98
}
dosbox_x_install_win98_game() {
    log i "DosBox-X Windows 98 Game Installer started"
    rd_zenity --question --text="This will install the selected game for Windows 98 in DOSBox-X.\nMake sure your Windows 98 installation is ready.\n\nAre you installing your game from a CD-ROM or a Floppy disk image?" --switch --extra-button="CD-ROM" --extra-button="Floppy Disk" --extra-button="Abort"
    case $? in
        0)
            local media_type="cd-rom"
            local pretty_media_type="CD-ROM"
            log i "User selected CD-ROM installation for Windows 98 game"
            ;;
        1)  
            local media_type="floppy"
            local pretty_media_type="Floppy Disk"
            log i "User selected Floppy Disk installation for Windows 98 game"
            ;;  
        2)  log i "Windows 98 game installation aborted by user"
            exit 0
    esac
    game_image_path="$(file_browse "Select the $pretty_media_type image file for $game installation")"
    local game="$(basename "$game_image_path" | sed 's/\.[^.]*$//')"
    game="$(rd_zenity --entry --text="Enter the name of the game you want to install" --entry-text="$game" --title="Game Name Input")"
    if ( ! $(rd_zenity --info --text="The game folder will be located in \"$roms_path/win98/$game\".\n\nProceed with the installation?" --ok-label="Proceed" --cancel-label="Abort") ); then
        log i "User confirmed game installation for Windows 98 game: \"$game\" in \"$roms_path/win98/$game\" folder"
    else
        log i "Windows 98 game \"$game\" installation aborted by user"
        return
    fi
    log d running command: $winplay --install win98 --$media_type "$game_image_path"
    if ( $winplay --install win98 --$media_type "$game_image_path" ); then
        log i "Windows 98 game \"$game\" installation completed"
        rd_zenity --info --text="Windows 98 game \"$game\" installation completed.\nYou can now run install games in this Windows 98 environment using the 'DOSBox-X: Install Windows 98 Game' option in the Configurator."
    else
        log i "Windows 98 game \"$game\" installation aborted by user"
    fi
}