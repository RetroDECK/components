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

    log d "Called os_install for system \"$PRETTY_SYSTEM_NAME\""

    load_system_config # This already cleans the autoexec

    log d "Calling mkfs to create virtual hard disk for $PRETTY_SYSTEM_NAME installation"
    OS_IMAGE="$storage_path/dosbox-x/${SYSTEM}.vhd"
    mkfs

    log d "Calling AUTOEXEC generator for $PRETTY_SYSTEM_NAME installation"
    source "$SCRIPT_DIR/winplay_autoexec_gen.sh"
    generate_autoexec_install_os

    log i "Starting DosBox-X to run the Phase 1 installation of $PRETTY_SYSTEM_NAME"
    run_dosbox_x --force-turbo

    log i "Rebooting $PRETTY_SYSTEM_NAME to complete installation (Phase 2)"
    log d "Setting action variable to \"os_run\" before rebooting the system."
    action="os_run"
    os_run

    clear_autoexec

}

create_vhd() {

    # Create a VHD (Virtual Hard Disk) file to be used as the virtual hard drive for the Windows installation or GAME HD.
    # Usage: create_vhd <vhd_path> <size_mb> <fs_type>

    local IMAGE_PATH="$1"
    local size_mb="$2"
    local fs_type="$3"

    log d "Creating VHD at \"$IMAGE_PATH\" with size ${size_mb}MB and filesystem $fs_type"


    if [[ -f "$IMAGE_PATH" ]]; then
        log e "VHD already exists: $IMAGE_PATH (skipping)"
        log e "If you want to create a new VHD, please delete the existing one at \"$IMAGE_PATH\" and run the installation again."
        log w "Skipping VHD creation for \"$IMAGE_PATH\" and proceeding with existing file. This may cause issues if the existing VHD is not properly set up."
    fi

    mkdir -p "$(dirname "$IMAGE_PATH")"

    log i "Creating VHD: \"$IMAGE_PATH\" (${size_mb}MB, $fs_type)"

    # Use DOSBox-X imgmake to create a dynamic VHD
    # This is native to DOSBox-X and fully compatible
    if ! "$component_path/bin/dosbox-x" -silent -c "imgmake -t hd -size $size_mb \"$IMAGE_PATH\"" -c "exit" > /dev/null 2>&1; then
        log e "Failed to create VHD with imgmake"
        rm -f "$IMAGE_PATH"
        return 1
    fi

    local disk_blocks=$(stat -c%b "$OS_IMAGE" 2>/dev/null || echo 0)
    local disk_usage_kb=$((disk_blocks * 512 / 1024))
    local size_str=$([[ $disk_usage_kb -lt 1024 ]] && echo "${disk_usage_kb}KB" || echo "$((disk_usage_kb / 1024))MB")

    log i "VHD created (sparse: ~${size_str} on disk)"
}

mkfs() {

    case "$SYSTEM" in
        "win98")
            local fs_type="FAT32"
            local size_mb=4096
        ;;
        "win95")
            local fs_type="FAT32"
            local size_mb=4096
        ;;
        "win31")
            local fs_type="FAT16"
            local size_mb=512
        ;;
        *)
            log e "Unsupported system for mkfs: $PRETTY_SYSTEM_NAME"
            return 1
        ;;
    esac

    create_vhd "$OS_IMAGE" "$size_mb" "$fs_type"
}

mk_gamehd() {
    log d "Called mk_gamehd for game name: \"$GAME_NAME\""
    log d "using system \"$PRETTY_SYSTEM_NAME\" to determine game HD parameters"

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

    log d "Determined game HD parameters: size ${size_mb}MB, filesystem $fs_type, ESDE system name \"$ESDE_SYSTEM_NAME\""

    GAME_IMAGE="$roms_path/$ESDE_SYSTEM_NAME/$(dos_name_sanitizer "$GAME_NAME.vhd")"

    create_vhd "$GAME_IMAGE" "$size_mb" "$fs_type"

}

game_install() {
    log d "Called game_install for game name: \"$GAME_NAME\""
    
    load_system_config # This already cleans the autoexec

    source "$SCRIPT_DIR/winplay_autoexec_gen.sh"
    generate_autoexec_game_install

    mk_gamehd

    # At this point we got the game HD created and the autoexec ready to run the game installer.
    # The flow with proceed calling DosBox-X with this environment set.
}