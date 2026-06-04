#!/bin/bash

# WinPlay! is used to setup and run Windows 9x through DosBox-X.
# The ecosystem of scripts in WinPlay! is designed to set variables and prepare the environment to feed it to DosBox-X.
# The main entry point is winplay.sh, which parses the arguments and calls the appropriate functions for installation or running.
# Everything is called trough arguments and WinPlay! will prepare the config file and the actual agruments. Once prepared the actual DosBox-X executable is called with the generated config and arguments.
# Everything here is dynamic and generated on the fly, there are no hardcoded config files or arguments for DosBox-X.
# Everything is generated based on the provided arguments and the templates in the os_configs directory.

# Call examples:
# Install Windows 98 with CD-ROM and Floppy images:
# winplay --os-install win98 --cdrom /path/to/windows98.iso --floppy /path/to/floppy.img
# Run the installed Windows 98:
# winplay --os-run win98

SYSTEM="UNKNOWN"               # The system to install or run, e.g. win98
GAME_NAME="UNKNOWN"            # Serves as a game ID
GAME_PATH="UNKNOWN"            # Path to the game VHD file
CALL_SOURCE="WINPLAY"          # The scripts will know that they are called from winplay.sh and not directly, so they can check this variable to prevent direct execution.
DOSBOX_X_ARGS=""               # This variable will be built up with the arguments to pass to DosBox-X, such as --cdrom and --floppy, based on the provided arguments.
MOUNT_MAP=""                   # Defines which CD-ROMs and Floppy disks are mounted.

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE:-$0}")" &> /dev/null && pwd)"
DOSBOX_X_EXEC="$SCRIPT_DIR/../bin/dosbox-x"

# TODO: only for local testing, remove me later
# log(){
#         if [ "$1" == "i" ]; then
#             level="INFO"
#         elif [ "$1" == "d" ]; then
#             level="DEBUG"
#         elif [ "$1" == "e" ]; then
#             level="ERROR"
#         elif [ "$1" == "w" ]; then
#             level="WARNING"
#         else
#             level="LOG"
#         fi
#         echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}]: $2"
# }

log d "Starting WinPlay! with arguments: $*"

reboot_windows() {
    log i "Windows reboot was requested."
    REBOOT_WINDOWS="true"
}

imgmount_map() {

    # This function generates an IMGMOUNT command for the given media type and image, and keeps track of used drive letters to avoid conflicts.
    # It returns the IMGMOUNT command string, which can be appended to the DosBox

    # Example usage:
    # MOUNT_MAP+="$(imgmount_map "FLOPPY" "$FLOPPY_IMAGE")"
    # MOUNT_MAP+="$(imgmount_map "CD-ROM" "$CDROM_IMAGE")"
    # Example output:
    # IMGMOUNT A "path/to/floppy.img" -t floppy
    # IMGMOUNT E "path/to/cdrom.iso" -t cdrom

    declare -A IMGMOUNT_USED

    local type="${1^^}"
    local image="$2"
    local letter=""
    local candidate

    log d "Generating IMGMOUNT command for type: $type, image: $image"

    case "$type" in
        FLOPPY)
            for candidate in A B; do
                [[ -n "${IMGMOUNT_USED[$candidate]}" ]] && continue
                letter="$candidate"
                break
            done
            local mount_type="-t floppy"
        ;;

        CDROM | CD-ROM)
            for candidate in E F G H I J K L M N O P Q R S T U V W X Y Z; do
                [[ -n "${IMGMOUNT_USED[$candidate]}" ]] && continue
                letter="$candidate"
                break
            done
            local mount_type="-t cdrom"
        ;;

        *)
            log e "Unknown media type: $type"
            return 1
            ;;
    esac

    if [[ -z "$letter" ]]; then
        log e "No free drive letters available for $type"
        return 1
    fi

    IMGMOUNT_USED["$letter"]=1

    log d "Assigned drive letter $letter for $type image: $image"

    printf 'IMGMOUNT %s "%s" %s\n' "$letter" "$image" "$mount_type"
}

show_help(){
    echo "Usage: winplay [OPTIONS]"
    echo ""
    echo "Drive Options:"
    echo "  --floppy <floppy_image>   Path to the floppy image to use for installation (optional)"
    echo "  --cdrom <cdrom_image>     Path to the CD-ROM. CD-ROM disc image or directory can be used. Also --cd-rom"
    echo "WinPlay! Supports two Floppy disks 22 CD-ROMs at the same time. If you need more than two Floppy disks, consider to group them into a CD-ROM."
    echo ""
    echo "Options:"
    echo "  --system <system>           Specify the system to install or run (win95, win98, win31)"
    echo "  --os-install                Install Windows 9x on DosBox-X"
    echo "  --os-run                    Run the installed Windows 9x on DosBox-X"
    echo "  --game-install <game_name>  Install a game on an installed Windows 9x. Game name serves as game identifier."
    echo "                              Game is installed in $roms_path/windows*/game_name directory."
    echo "                              Game name should match the wished executable target,for example OMF to launch OMF.EXE."
    echo "  --game-run <vhd_path>       Run a game from a specified VHD file."
    echo "                              the VHD base name (without extension) should match the wished executable target, for example OMF.vhd will search and launch OMF.EXE."
    echo "  -h, --help                  Show this help message and exit"
    echo ""
    echo "Supported systems:"
    echo "  win95                     Install Windows 95 on DosBox-X (not implemented yet)"
    echo "  win98                     Install Windows 98 on DosBox-X"
    echo "  win31                     Install Windows 3.1 on DosBox-X (not implemented yet)"
    echo ""
    echo "Example usages:"
    echo "  winplay --os-install --system win98 --cdrom /path/to/windows98.iso --floppy /path/to/floppy.img"
    echo "  winplay --os-run --system win98"
    echo "  winplay --game-install --system win98 --game OMF --cdrom /path/to/OMF2097.iso"
    echo "  winplay --game-run --system win98 --game /home/deck/retrodeck/roms/windows9x/OMF.vhd"
}

# TODO: not yet used
dos_name_sanitizer(){
    # Replace path separators with underscores and collapse any sequence of
    # characters that are not a-zA-Z0-9, dot, underscore or hyphen into a single '_'

    # Usage: sanitized=$(sanitize_name "Some Name/With*Invalid|Chars")
    # Output: Some_Name_With_Invalid_Chars

    local name="$1"

    [[ -z "$name" ]] && {
        printf 'GAME'
        return
    }

    local safe
    safe=$(printf '%s' "$name" \
        | sed -E 's|/|_|g' \
        | sed -E 's/[^A-Za-z0-9_-]+/_/g' \
        | sed -E 's/^_+|_+$//g')

    printf '%s' "${safe^^}"
}

load_system_config(){

    # Simple function to load the winXX.conf from the os_configs directory.
    # NOTE: this clenas the Autoexec

    log d "Generating temporary config for $PRETTY_SYSTEM_NAME installation"

    if [ ! -f "$dosbox_x_os_configs_dir/${SYSTEM}.conf" ]; then
        log e "Missing template config for $PRETTY_SYSTEM_NAME installation: $dosbox_x_os_configs_dir/${SYSTEM}.conf"
        exit 1
    fi

    cp -fv "$dosbox_x_os_configs_dir/${SYSTEM}.conf" "$dosbox_x_generated_conf"
    DOSBOX_X_CONF_ARGS="-conf $dosbox_x_generated_conf"

}

os_run() {
    # Simple function to run DosBox-X with the set SYSTEM
    log i "Running $PRETTY_SYSTEM_NAME in DosBox-X"
    source "$SCRIPT_DIR/winplay_autoexec_gen.sh"
    load_system_config  # this cleans the autoexec
    generate_autoexec_os_run
}

game_run(){
    # Run the game on defined system and game name
    log i "Running game $GAME_PATH on $PRETTY_SYSTEM_NAME in DosBox-X"

    if [[ -z "$GAME_PATH" ]]; then
        log e "Game path is not specified for game_run"
        exit 1
    fi

    source "$SCRIPT_DIR/winplay_autoexec_gen.sh"
    load_system_config  # this cleans the autoexec
    generate_autoexec_game_run

    # TODO
}

parse_arguments() {

    if [ $# -eq 0 ]; then
        log w "No arguments provided for winplay"
        show_help
        exit 1
    fi

    while [[ $# -gt 0 ]]; do

        log d "Evaluating argument: $1"

        case "$1" in

        "--system")
            if [ -n "$1" ]; then

                log d "Found \"$2\" as system name for installation or running"

                SYSTEM="$2"

                case "$SYSTEM" in
                    "win95")
                        log w "Windows 95 installation is not implemented yet"
                        exit 1
                    ;;

                    "win98")
                        log d "Selected system: Windows 98"
                        log d "Setting SYSTEM variable to \"win98\" for internal use"
                        log d "Setting PRETTY_SYSTEM_NAME variable to \"Windows 98\" for user-friendly display"
                        SYSTEM="win98"
                        PRETTY_SYSTEM_NAME="Windows 98"
                    ;;
                    "win31")
                        log w "Windows 3.1 installation is not implemented yet"
                        exit 1
                    ;;
                    *)
                        log e "Unsupported system for os_install: $1"
                        os_install_help
                        exit 1
                    ;;
                esac
                shift
            else
                log e "Missing value for --system option. Aborting."
                show_help
                exit 1
            fi

        ;;
        "--floppy")
            log d "Processing floppy argument"
            if [ -n "$2" ]; then
                if [ ! -f "$2" ]; then
                    log e "Floppy image file not found: $2"
                    exit 1
                fi
                FLOPPY_IMAGE="$2"
                # DOSBOX_X_ARGS+=" --floppy \"$FLOPPY_IMAGE\"" # Not needed, we just set it in the config
                MOUNT_MAP+="$(imgmount_map "FLOPPY" "$FLOPPY_IMAGE")"
                log i "Loaded floppy image: $FLOPPY_IMAGE"
                shift
            else
                log e "Missing value for --floppy option. Aborting."
                show_help
                exit 1
            fi
        ;;
        "--cdrom" | "--cd-rom")
            log d "Processing CD-ROM argument"
            if [ -n "$2" ]; then
                # For CD-ROM images, we allow both files and directories, so we check if the path exists.
                if [ ! -f "$2" ] && [ ! -d "$2" ]; then
                    log e "CD-ROM image file not found: $2"
                    exit 1
                fi
                CDROM_IMAGE="$2"
                # DOSBOX_X_ARGS+=" --cdrom \"$CDROM_IMAGE\"" # Not needed, we just set it in the config
                MOUNT_MAP+="$(imgmount_map "CD-ROM" "$CDROM_IMAGE")"
                log i "Loaded CD-ROM image: $CDROM_IMAGE"
                shift
            else
                log e "Missing value for --cdrom option"
                exit 1
            fi
        ;;
        "--os-install")
            log d "Selected action: OS install"
            ACTION="os_install"
        ;;
        "--os-run")
            log d "Selected action: OS run"
            ACTION="os_run"
        ;;
        "--game-install")
            log d "Selected action: Game install"
            log d "Found \"$2\" as game name for installation"
            if [[ -z "$2" || "$2" == --* ]]; then
                log e "Missing game name after --game-install"
                exit 1
            else
                GAME_NAME="$2"
            fi
            source "$SCRIPT_DIR/winplay_install.sh"
            ACTION="game_install"
        ;;
        "--game-run")
            log d "Found \"$2\" as game path"
            if [[ -z "$2" || "$2" == --* ]]; then
                log e "Missing game path after --game-run"
                exit 1
            else
                GAME_PATH="$2"
                GAME_NAME="$(basename "${GAME_PATH%.*}")"
            fi
            ACTION="game_run"
        ;;
        "--help" | "-h")
            show_help
            exit 0
        ;;
        *)
            log e "Invalid action for winplay: $1"
            show_help
            exit 1
        ;;
    esac
    shift
done
}

if [ "$REBOOT_WINDOWS" == "true" ]; then
    log d "Reboot flag is set, discarding arguments as environment is already build."
else
    log d "Parsing arguments..."
    parse_arguments "$@"
fi

case "$ACTION" in
    os_install)
        source "$SCRIPT_DIR/winplay_install.sh"
        os_install
        ;;
    os_run)
        os_run
        ;;
    game_install)
        source "$SCRIPT_DIR/winplay_install.sh"
        game_install
        ;;
    game_run)
        game_run
        ;;
    *)
        log e "No action specified"
        exit 1
        ;;
esac

log d "Finished setting environment for DosBox-X execution."
log d "SYSTEM=$SYSTEM"
log d "PRETTY_SYSTEM_NAME=$PRETTY_SYSTEM_NAME"
log d "GAME_NAME=$GAME_NAME"
log d "GAME_PATH=$GAME_PATH"
log d "action=$ACTION"

log d "Calling DosBox-X"
log d "Command: $DOSBOX_X_EXEC $DOSBOX_X_CONF_ARGS $DOSBOX_X_ARGS"

log d "Config file content:"
log d "$(<$dosbox_x_generated_conf)"

# At this point, all the arguments have been parsed, the config file is built and the environment is prepared.
# We can now call DosBox-X with the generated config and arguments.
# By default the dosbox-x.conf will be passed as the system .conf files are just overrides and don't include the full config stack.

"$DOSBOX_X_EXEC" $DOSBOX_X_CONF_ARGS $DOSBOX_X_ARGS

# Sometimes we need to reboot Windows during the installation process.
# Since we are running DosBox-X with exec, we can not just call exec again to reboot, so we set a flag and check it after DosBox-X exits.
# If the flag is set, we call exec again to restart DosBox-X, even with updated environment.

if [ "$REBOOT_WINDOWS" == "true" ]; then
    log i "Rebooting Windows as requested..."
    REBOOT_WINDOWS="false"
    "$DOSBOX_X_EXEC" $DOSBOX_X_CONF_ARGS $DOSBOX_X_ARGS
fi
