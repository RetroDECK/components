#!/bin/bash

# WinPlay! is used to setup and run Windows 9x through DosBox-X.

CALL_SOURCE="WINPLAY"
DOSBOX_X_ARGS=""
MOUNT_MAP=""
SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE:-$0}")" &> /dev/null && pwd)"
DOSBOX_X_EXEC="$SCRIPT_DIR/../bin/dosbox-x"

# TODO: only for local testing, remove me later
log(){
        if [ "$1" == "i" ]; then
            level="INFO"
        elif [ "$1" == "d" ]; then
            level="DEBUG"
        elif [ "$1" == "e" ]; then
            level="ERROR"
        elif [ "$1" == "w" ]; then
            level="WARNING"
        else
            level="LOG"
        fi
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}]: $2"
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

    case "$type" in
        FLOPPY)
            for candidate in A B; do
                [[ -n "${IMGMOUNT_USED[$candidate]}" ]] && continue
                letter="$candidate"
                break
            done
        ;;

        CDROM | CD-ROM)
            for candidate in E F G H I J K L M N O P Q R S T U V W X Y Z; do
                [[ -n "${IMGMOUNT_USED[$candidate]}" ]] && continue
                letter="$candidate"
                break
            done
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

    printf 'IMGMOUNT %s "%s"\n' "$letter" "$image"
}

show_help(){
    echo "Usage: winplay [OPTIONS]"
    echo ""
    echo "Drive Options:"
    echo "  --floppy <floppy_image>   Path to the floppy image to use for installation (optional)"
    echo "  --cdrom <cdrom_image>     Path to the CD-ROM image"
    echo ""
    echo "Options:"
    echo "  --os-install       Install Windows 9x on DosBox-X"
    echo "  --os-run           Run the installed Windows 9x on DosBox-X"
    echo "  --game-install     Install a game on the installed Windows 9x"
    echo "  --game-run         Run a game on the installed Windows 9x"
    echo "  -h, --help         Show this help message and exit"
}

parse_arguments() {

    if [ $# -eq 0 ]; then
        log w "No arguments provided for winplay"
        show_help
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
        "--floppy")
                if [ -n "$2" ]; then
                    if [ ! -f "$2" ]; then
                        log e "Floppy image file not found: $2"
                        exit 1
                    fi
                    FLOPPY_IMAGE="$2"
                    DOSBOX_X_ARGS+=" --floppy \"$FLOPPY_IMAGE\""
                    MOUNT_MAP+="$(imgmount_map "FLOPPY" "$FLOPPY_IMAGE")"
                    log i "Loaded floppy image: $FLOPPY_IMAGE"
                    shift
                else
                    log e "Missing value for --floppy option"
                    exit 1
                fi
            ;;
            "--cdrom" | "--cd-rom")
                if [ -n "$2" ]; then
                    if [ ! -f "$2" ]; then
                        log e "CD-ROM image file not found: $2"
                        exit 1
                    fi
                    CDROM_IMAGE="$2"
                    DOSBOX_X_ARGS+=" --cdrom \"$CDROM_IMAGE\""
                    MOUNT_MAP+="$(imgmount_map "CD-ROM" "$CDROM_IMAGE")"
                    log i "Loaded CD-ROM image: $CDROM_IMAGE"
                    shift
                else
                    log e "Missing value for --cdrom option"
                    exit 1
                fi
            ;;
            "--os-install")
                source "$SCRIPT_DIR/winplay_os_install.sh"
                shift
                os_install "$@"
                log d "DOSBOX_X_ARGS=$DOSBOX_X_ARGS"
                break
            ;;
            "--os-run")
                source "$SCRIPT_DIR/winplay_run.sh"
                shift
                os_run "$@"
                break
            ;;
            "--game-install")
                source "$SCRIPT_DIR/winplay_game_install.sh"
                shift
                game_install "$@"
                break
            ;;
            "--game-run")
                source "$SCRIPT_DIR/winplay_run.sh"
                shift
                game_run "$@"
                break
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

parse_arguments "$@"

log d "Calling DosBox-X"
log d "Command: $DOSBOX_X_EXEC -conf $dosbox_x_config $DOSBOX_X_ARGS"

exec "$DOSBOX_X_EXEC" -conf "$dosbox_x_config" $DOSBOX_X_ARGS
