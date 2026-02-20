#!/bin/bash

dosbox_x_config="$XDG_CONFIG_HOME/dosbox-x/dosbox-x.conf"
dosbox_x_mapper="$XDG_CONFIG_HOME/dosbox-x/mapper-dosbox-x.map"
dosbox_x_os_configs_dir="$component_config/os_configs"
dosbox_x_winplay_path="$component_path/winplay.sh"

dosbox_x_install_win98() {
    log i "DosBox-X Windows 98 Installer started"
    if ( $dosbox_x_winplay_path --install win98 --cd-rom "$(directory_browse "This will install Windows 98 in DOSBox-X./nSelect the CD-ROM image file for Windows 98 installation")" ); then
        log i "Windows 98 installation completed successfully"
        rd_zenity --info --text="Windows 98 installation completed successfully/nYou can now run install games in this Windows 98 environment using the 'DOSBox-X: Install Windows 98 Game' option in the Configurator."
    else
        log i "Windows 98 installation aborted"
    fi
}
dosbox_x_run_win98() {
    log i "DosBox-X starting Windows 98 layer"
    rd_zenity --info --text="WARNING: editing Windows 98 Installation might cause to break already installed games./nMake sure to backup your Windows 98 installation layer before making any changes."
    $dosbox_x_winplay_path --desktop win98
}
dosbox_x_install_win98_game() {
    log i "DosBox-X Windows 98 Game Installer started"
    rd_zenity --info --text="This will install the selected game for Windows 98 in DOSBox-X./nMake sure your Windows 98 installation is ready./n/nAre you installing your game from a CD-ROM or a Floppy disk image?" --ok-label="CD-ROM" --extra-button="Floppy Disk" --cancel-label="Abort"
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
            return
    esac
    rd_zenity --entry --text="Enter the name of the game you want to install" --entry-text="Game Name" --title="Game Name Input"
    local game="$(rd_zenity --entry --text="Enter the name of the game you want to install" --entry-text="Game Name" --title="Game Name Input")"
    game="${game//[!a-zA-Z0-9._-]/}"
    if ( $(rd_zenity --info --text="The game folder will be located in \"$roms_path/win98/$game\"./n/nProceed with the installation?" --ok-label="Proceed" --cancel-label="Abort") ); then
        log i "User confirmed game installation for Windows 98 game: \"$game\" in \"$roms_path/win98/$game\" folder"
    else
        log i "Windows 98 game \"$game\" installation aborted by user"
        return
    fi
    if ( $dosbox_x_winplay_path --install win98 --$media_type "$(directory_browse "Select the $pretty_media_type image file for $game installation")" ); then
        log i "Windows 98 game \"$game\" installation completed"
        rd_zenity --info --text="Windows 98 game \"$game\" installation completed./nYou can now run install games in this Windows 98 environment using the 'DOSBox-X: Install Windows 98 Game' option in the Configurator."
    else
        log i "Windows 98 game \"$game\" installation aborted by user"
    fi
}