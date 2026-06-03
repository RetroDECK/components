#!/bin/bash

if [ "$CALL_SOURCE" != "WINPLAY" ]; then
    log e "This script is not meant to be called directly. Please use winplay.sh to run this script."
    exit 1
fi

os_install_help() {
    echo "Usage: winplay --os-install --system <system> --floppy <floppy_image> --cdrom <cdrom_image>"
    echo ""
    echo "This will guide you through the installation of Windows 9x on DosBox-X using WinPlay!"
    echo "You will need a legit Windows 98 CD Key and a Windows 98 ISO image to complete the installation."
    echo ""
    echo "Options:"
    echo "  --os-install --system <system>     Install the specified system on DosBox-X"
    echo ""
    echo "Example usage:" 
    echo "  winplay --os-install --system win98 --cdrom /path/to/windows98.iso --floppy /path/to/floppy.img"
}

os_install() {
    log d "Called os_install with args: $*"

    load_system_config # This already cleans the autoexec

    log d "Calling mkfs to create virtual hard disk for $PRETTY_SYSTEM_NAME installation"
    mkfs

    log d "Calling AUTOEXEC generator for $PRETTY_SYSTEM_NAME installation"
    source "$SCRIPT_DIR/winplay_autoexec_gen.sh"
    generate_autoexec_install_os

    reboot_windows
    os_run

    clear_autoexec

}

mkfs() {

    case "$SYSTEM" in
        "win98")
            local fs_type="FAT32"
            local size_mb=4096
            break
        ;;
        "win95")
            local fs_type="FAT32"
            local size_mb=4096
            break
        ;;
        "win31")
            local fs_type="FAT16"
            local size_mb=512
            break
        ;;
        *)
            log e "Unsupported system for mkfs: $PRETTY_SYSTEM_NAME"
            return 1
        ;;
    esac

    OS_IMAGE="${2:-$storage_path/dosbox-x/${SYSTEM}.vhd}"

    if [[ -f "$OS_IMAGE" ]]; then
        log e "VHD already exists: $OS_IMAGE (skipping)"
        log e "If you want to create a new VHD, please delete the existing one at \"$OS_IMAGE\" and run the installation again."
        exit 1
    fi

    mkdir -p "$(dirname "$OS_IMAGE")"

    log i "Creating $PRETTY_SYSTEM_NAME VHD: $OS_IMAGE (${size_mb}MB, $fs_type)"

    # Use DOSBox-X imgmake to create a dynamic VHD
    # This is native to DOSBox-X and fully compatible
    if ! "$component_path/bin/dosbox-x" -c "imgmake -t hd -size $size_mb \"$OS_IMAGE\"" -c "exit" > /dev/null 2>&1; then
        log e "Failed to create VHD with imgmake"
        rm -f "$OS_IMAGE"
        return 1
    fi

    local disk_blocks=$(stat -c%b "$OS_IMAGE" 2>/dev/null || echo 0)
    local disk_usage_kb=$((disk_blocks * 512 / 1024))
    local size_str=$([[ $disk_usage_kb -lt 1024 ]] && echo "${disk_usage_kb}KB" || echo "$((disk_usage_kb / 1024))MB")

    log i "$PRETTY_SYSTEM_NAME VHD created (sparse: ~${size_str} on disk)"
}

mk_gamehd() {
    log d "Called mk_gamehd with args: $*"

    case "$SYSTEM" in
    "win98")
        local fs_type="FAT32"
        local size_mb=16384   # 16GB
        local ESDE_SYSTEM_NAME="windows9x"
        ;;
    "win95")
        local fs_type="FAT32"
        local size_mb=8192    # 8GB
        local ESDE_SYSTEM_NAME="windows9x"
        ;;
    "win31")
        local fs_type="FAT16"
        local size_mb=2048    # 2GB (FAT16 limitation)
        local ESDE_SYSTEM_NAME="windows3x"
        ;;
    esac

    GAME_IMAGE="$roms_path/$ESDE_SYSTEM_NAME/$GAME_NAME.vhd}"

    # TODO: continue from here, need to create the VHD then move on woth the autoexec generation for game installation
}

game_install() {
    log d "Called game_install"
    
    load_system_config # This already cleans the autoexec

    generate_autoexec_game_install
}