#!/bin/bash

# This script launches DOSBox-X with a Windows 98/3.1 image and autostarts games
# It prepares a temporary configuration and BAT file for game installation and launching

# NOTE: logging helper `log()` is provided by the surrounding framework and
# is intentionally not defined here to avoid duplicate definitions. Use the
# framework-provided logger (e.g., log i "message").
# INITIALIZATION FUNCTIONS
# ============================================================================

init_globals() {
    # VHD layer paths - save_path should be provided by RetroDECK framework
    SAVES_PATH="${save_path:-${XDG_DATA_HOME:-$HOME/.local/share}/retrodeck/saves}"
    VHD_SAVEDATA_DIR="$SAVES_PATH/windows9x/dosbox-x"
    
    # Initialize mode flags
    INSTALL_MODE=0
    INSTALL_NAME=""
    MAKEFS_MODE=0
    MAKEFS_VERSION=""
    DESKTOP_MODE=0
    DESKTOP_VERSION=""
    FORCE_RECREATE=0
    FLOPPIES=()
    CDROMS=()
    HDISKS=()
    WIN_VERSION=""
    GAME_PATH=""
    
    # Initialize runtime variables
    IS_OS_INSTALL=0
    GAME_NAME_FOR_DIR=""
    VHD_GAME_LAYER=""
    VHD_SAVEDATA=""
    OS_CONFIG_DIR=""
    VHD_BASE_PATH=""
    TMP_CONF=""
    LAUNCHER_DIR=""
}

setup_paths() {
    log d "Looking for OS config files in component path first: $component_path/rd_config/os_configs"
    OS_CONFIG_DIR="${component_path:-}/rd_config/os_configs"
    if [[ ! -d "$OS_CONFIG_DIR" ]]; then
        OS_CONFIG_DIR="${dosbox_x_os_configs_dir:-$OS_CONFIG_DIR}"
    fi
    
    VHD_BASE_PATH="$bios_path/$WIN_VERSION.vhd"
    TMP_CONF="$XDG_CACHE_HOME/dosbox-x/winplay.conf"
    mkdir -p "$XDG_CACHE_HOME/dosbox-x"
}

setup_launcher_dir() {
    local launcher_base_dir="$XDG_CACHE_HOME/dosbox-x"
    local launcher_tmp_dir=$(mktemp -d "${launcher_base_dir}/tmp.XXXX")
    LAUNCHER_DIR="$launcher_tmp_dir/launcher"
    
    # Cleanup on exit
    trap "rm -rf '$launcher_tmp_dir' 2>/dev/null || true" EXIT
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --desktop)
                DESKTOP_MODE=1
                if [[ -z "$2" || "$2" == --* ]]; then
                    log e "--desktop requires an argument (win98 or win31)"
                    exit 1
                fi
                DESKTOP_VERSION="$2"
                shift 2
                ;;
            --makefs)
                MAKEFS_MODE=1
                if [[ -z "$2" || "$2" == --* ]]; then
                    log e "--makefs requires an argument (win98 or win31)"
                    exit 1
                fi
                MAKEFS_VERSION="$2"
                shift 2
                ;;
            --install)
                INSTALL_MODE=1
                if [[ -z "$2" || "$2" == --* ]]; then
                    log e "--install requires an argument (Windows version or game name)"
                    echo "Usage: $0 --install <windows_version|game_name> [--cd-rom /path/to/cd.iso ...]"
                    exit 1
                fi
                INSTALL_NAME="$2"
                shift 2
                ;;
            --cd-rom)
                if [[ -z "$2" ]]; then
                    log e "--cd-rom requires an argument (path to ISO)"
                    exit 1
                fi
                CDROMS+=("$2")
                shift 2
                ;;
            --cdrom)
                if [[ -z "$2" ]]; then
                    log e "--cdrom requires an argument (path to ISO)"
                    exit 1
                fi
                CDROMS+=("$2")
                shift 2
                ;;
            --floppy)
                if [[ -z "$2" ]]; then
                    log e "--floppy requires an argument (path to floppy image)"
                    exit 1
                fi
                FLOPPIES+=("$2")
                shift 2
                ;;
            --hd)
                if [[ -z "$2" ]]; then
                    log e "--hd requires an argument (path to hard disk image)"
                    exit 1
                fi
                HDISKS+=("$2")
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --*)
                log e "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$WIN_VERSION" ]]; then
                    WIN_VERSION="$1"
                elif [[ -z "$GAME_PATH" ]]; then
                    GAME_PATH="$1"
                fi
                shift
                ;;
        esac
    done
}

validate_arguments() {
    # Set default Windows version
    WIN_VERSION="${WIN_VERSION:-win98}"
    
    # Validate required arguments
    if [[ $INSTALL_MODE -eq 0 && $DESKTOP_MODE -eq 0 && -z "$GAME_PATH" ]]; then
        log e "No game path provided, --install, or --desktop specified!"
        log i "Usage:"
        log i "  $0 win98 GameName              (launch game)"
        log i "  $0 --install GameName          (install game)"
        log i "  $0 --desktop win98             (desktop mode)"
        log i "Use '$0 --help' for more information."
        exit 1
    fi
}

show_help() {
    cat <<'HELP'
winplay.sh - Windows 98/3.1 game launcher with VHD layering for DOSBox-X

USAGE:
  winplay.sh --makefs win98                                    (Create Windows 98 VHD)
  winplay.sh --makefs win31                                    (Create Windows 3.1 VHD)
  winplay.sh --desktop win98                                   (Launch Windows 98 desktop)
  winplay.sh --desktop win31                                   (Launch Windows 3.1 desktop)
  winplay.sh --install win98 --cd-rom /path/to/WIN98SE.iso    (Install Windows 98)
  winplay.sh --install GameName --cd-rom /path/to/game.iso    (Install game)
  winplay.sh win98 GameName                                    (Launch game)
  winplay.sh --help                                            (Show this help)

CREATE FILESYSTEM IMAGES:
  --makefs win98          Create 4GB FAT32 sparse VHD for Windows 98 at $bios_path/win98.vhd
  --makefs win31          Create 512MB FAT16 sparse VHD for Windows 3.1 at $bios_path/win31.vhd

DESKTOP MODE (WARNING):
  --desktop win98         Launch Windows 98 base OS desktop (NO GAME)
  --desktop win31         Launch Windows 3.1 base OS desktop (NO GAME)
  
      ALL CHANGES MADE IN DESKTOP MODE ARE PERMANENT AND AFFECT THE BASE IMAGE!
      Any modifications, installations, or configurations will persist across all games.
      Use only for system setup or troubleshooting.
      NOT recommended for normal use - use --install for games instead.

PARAMETERS:
  --makefs <win98|win31>   Create pre-formatted VHD images
  --desktop <win98|win31>  Launch OS desktop (changes are permanent!)
  --install <name>         Install Windows version or game
  --cd-rom <path>          Mount ISO/CD-ROM image (multiple allowed)
  --cdrom <path>           Alias for --cd-rom
  --help, -h               Show this help

EXAMPLES:
  ./winplay.sh --makefs win98
  ./winplay.sh --install win98 --cd-rom ~/images/WIN98SE.iso
  ./winplay.sh --install "Doom" --cd-rom ~/images/doom-cd.iso
  ./winplay.sh win98 Doom
  ./winplay.sh --desktop win98

HELP
}

# ============================================================================
# ENVIRONMENT VARIABLE PROCESSING (for framework integration)
# ============================================================================

extract_args_from_environment() {
    # If no CLI arguments provided, check for framework-provided environment variables
    if [[ $# -eq 0 ]]; then
        local env_args=()
        
        # Check for action environment variables
        if [[ -n "${DOSBOX_ACTION:-}" ]]; then
            env_args+=("--${DOSBOX_ACTION}")
            [[ -n "${DOSBOX_ACTION_VALUE:-}" ]] && env_args+=("${DOSBOX_ACTION_VALUE}")
        fi
        
        # Check for CD-ROM environment variables
        if [[ -n "${DOSBOX_CDROM:-}" ]]; then
            env_args+=("--cdrom" "${DOSBOX_CDROM}")
        fi
        
        if [[ ${#env_args[@]} -gt 0 ]]; then
            log d "Extracted arguments from environment: ${env_args[@]}"
            printf '%s\n' "${env_args[@]}"
            return 0
        fi
    fi
    
    # Return CLI arguments as-is
    printf '%s\n' "$@"
    return 0
}


# ============================================================================
# MODE HANDLERS: --makefs
# ============================================================================

mkfs_win98() {
    local target_path="${1:-$bios_path/win98.vhd}"
    local size_mb=4096
    
    mkdir -p "$(dirname "$target_path")"
    
    if [[ -f "$target_path" ]]; then
        log w "VHD already exists: $target_path (skipping)"
        return 0
    fi
    
    log i "Creating Windows 98 VHD: $target_path (${size_mb}MB, FAT32)"
    
    # Use DOSBox-X imgmake to create a dynamic VHD
    # This is native to DOSBox-X and fully compatible
    if ! "$component_path/bin/dosbox-x" -c "imgmake -t hd -size $size_mb \"$target_path\"" -c "exit" > /dev/null 2>&1; then
        log e "Failed to create VHD with imgmake"
        rm -f "$target_path"
        return 1
    fi
    
    local disk_blocks=$(stat -c%b "$target_path" 2>/dev/null || echo 0)
    local disk_usage_kb=$((disk_blocks * 512 / 1024))
    local size_str=$([[ $disk_usage_kb -lt 1024 ]] && echo "${disk_usage_kb}KB" || echo "$((disk_usage_kb / 1024))MB")
    
    log i "✓ Windows 98 VHD created (sparse: ~${size_str} on disk)"
    return 0
}

mkfs_win31() {
    local target_path="${1:-$bios_path/win31.vhd}"
    local size_mb=512
    
    mkdir -p "$(dirname "$target_path")"
    
    if [[ -f "$target_path" ]]; then
        log w "VHD already exists: $target_path (skipping)"
        return 0
    fi
    
    log i "Creating Windows 3.1 VHD: $target_path (${size_mb}MB, FAT16)"
    
    # Use DOSBox-X imgmake to create a dynamic VHD
    # This is native to DOSBox-X and fully compatible
    if ! "$component_path/bin/dosbox-x" -c "imgmake -t hd -size $size_mb \"$target_path\"" -c "exit" > /dev/null 2>&1; then
        log e "Failed to create VHD with imgmake"
        rm -f "$target_path"
        return 1
    fi
    
    local disk_blocks=$(stat -c%b "$target_path" 2>/dev/null || echo 0)
    local disk_usage_kb=$((disk_blocks * 512 / 1024))
    local size_str=$([[ $disk_usage_kb -lt 1024 ]] && echo "${disk_usage_kb}KB" || echo "$((disk_usage_kb / 1024))MB")
    
    log i "✓ Windows 3.1 VHD created (sparse: ~${size_str} on disk)"
    return 0
}

handle_makefs_mode() {
    case "$MAKEFS_VERSION" in
        win98)
            mkfs_win98 "$bios_path/win98.vhd"
            exit $?
            ;;
        win31)
            mkfs_win31 "$bios_path/win31.vhd"
            exit $?
            ;;
        *)
            log e "Unknown version for --makefs: $MAKEFS_VERSION (must be win98 or win31)"
            exit 1
            ;;
    esac
}

# ============================================================================
# VHD MANAGEMENT
# ============================================================================

verify_os_config() {
    local config_file="$OS_CONFIG_DIR/$WIN_VERSION.conf"
    if [[ ! -f "$config_file" ]]; then
        log e "Windows version '$WIN_VERSION' not recognized (missing config: $config_file)"
        log i "Supported versions are (from: $OS_CONFIG_DIR):"
        if [[ -d "$OS_CONFIG_DIR" ]]; then
            for cfg in "$OS_CONFIG_DIR"/*.conf; do
                echo " - $(basename "$cfg" .conf)"
            done
        else
            echo " (no os_configs directory found at $OS_CONFIG_DIR)"
        fi
        exit 1
    fi
}

copy_base_vhd_from_template() {
    local os_version="$1"
    local target_path="$2"
    
    # Force recreate if -f flag was used
    if [[ $FORCE_RECREATE -eq 1 && -f "$target_path" ]]; then
        log i "Force recreating VHD (removing existing file)..."
        rm -f "$target_path" || { log e "Failed to remove old VHD"; exit 1; }
    fi
    
    if [[ ! -f "$target_path" ]]; then
        log i "Windows $os_version VHD not found at: $target_path"
        log i "Creating VHD automatically..."
        
        case "$os_version" in
            win98)
                mkfs_win98 "$target_path" || exit 1
                ;;
            win31)
                mkfs_win31 "$target_path" || exit 1
                ;;
            *)
                log e "Unknown Windows version: $os_version"
                exit 1
                ;;
        esac
    else
        log i "VHD base already exists: $target_path"
    fi
}

create_game_layer_vhd() {
    local game_name="$1"
    local game_dir="$roms_path/windows9x/$game_name"
    local game_layer="$game_dir/game-layer.vhd"
    
    mkdir -p "$game_dir"
    
    if [[ ! -f "$game_layer" ]]; then
        log i "Creating game layer VHD: $game_layer"
        if ! "$component_path/bin/qemu-img/qemu-img" create -f vpc -b "$VHD_BASE_PATH" "$game_layer" -o subformat=fixed 2>/dev/null; then
            log e "Failed to create game layer VHD at: $game_layer"
            exit 1
        fi
    fi
    
    echo "$game_layer"
}

create_savedata_vhd() {
    local game_name="$1"
    local savedata="$VHD_SAVEDATA_DIR/$game_name.sav.vhd"
    
    mkdir -p "$VHD_SAVEDATA_DIR"
    
    if [[ ! -f "$savedata" ]]; then
        log i "Creating savedata VHD: $savedata"
        if ! "$component_path/bin/qemu-img/qemu-img" create -f vpc "$savedata" 512M -o subformat=fixed 2>/dev/null; then
            log e "Failed to create savedata VHD at: $savedata"
            exit 1
        fi
    fi
    
    echo "$savedata"
}

# ============================================================================
# AUTOEXEC GENERATION
# ============================================================================

generate_autoexec_install_os() {
    local conf_file="$1"
    
    log i "Windows OS Installation Mode"
    log i "VHD is pre-formatted and ready for Setup"
    
    if [[ ${#CDROMS[@]} -eq 0 ]]; then
        log e "Installation requires a CD-ROM image!"
        log e "Usage: $0 --install $WIN_VERSION --cd-rom /path/to/setup.iso"
        exit 1
    fi
    
    cat <<EOF >> "$conf_file"
REM Mount the pre-formatted VHD as C:
IMGMOUNT C "$VHD_BASE_PATH" -t hdd
EOF

    # Ensure disks (CD/HD/floppy) are mounted before running Setup so they're
    # present across reboots during installation — start from D: because C: is taken
    mount_disks "$conf_file" "D"

    # Append commands to copy only likely-needed driver files from the CD to the
    # Windows system directory so Windows setup or subsequent reboots don't prompt
    # for them. These are written into the autoexec (do NOT run locally).
    cat <<'EOF' >> "$conf_file"
REM Copy driver files (if present) from CD to C:\WINDOWS\SYSTEM
IF NOT EXIST C:\WINDOWS\SYSTEM MD C:\WINDOWS\SYSTEM
REM Copy specific driver/file types commonly requested by installers
IF EXIST D:\*CSPMAN*.DLL COPY /Y D:\*CSPMAN*.DLL C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*CSPMAN*.DLL COPY /Y D:\WIN98\*CSPMAN*.DLL C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*.VXD COPY /Y D:\WIN98\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*.DRV COPY /Y D:\WIN98\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*.DLL COPY /Y D:\WIN98\*.DLL C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*.ACV COPY /Y D:\WIN98\*.ACV C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\WIN98\*.CSP COPY /Y D:\WIN98\*.CSP C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\DRIVERS\*.VXD COPY /Y D:\DRIVERS\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\DRIVERS\*.DRV COPY /Y D:\DRIVERS\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
REM Attempt also from common root locations
IF EXIST D:\*.VXD COPY /Y D:\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\*.DRV COPY /Y D:\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
EOF

    cat <<EOF >> "$conf_file"
REM Check if Windows is already installed
IF EXIST C:\\WINDOWS\\WIN.COM GOTO WINDOWS_FOUND
REM Boot from C: and run Setup from CD
ECHO C: drive mounted successfully
ECHO D: drive contains Setup
D:
SETUP.EXE
GOTO END_INSTALL
:WINDOWS_FOUND
ECHO Windows installation detected, booting it
BOOT C:
:END_INSTALL
C:
RUNDLL32.EXE USER.EXE,ExitWindows
EXIT
EOF
    log i "Setup: VHD mounted, ready for installation"
}

generate_autoexec_install_game() {
    local conf_file="$1"
    local game_layer="$2"
    
    log i "Mounting base OS and game layer VHD for installation"
    
    cat <<EOF >> "$conf_file"
IMGMOUNT C "$VHD_BASE_PATH" -b "$game_layer" -t hdd
DEL "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
EOF

    # Mount disks (if any) before the boot so the guest sees them on startup
    mount_disks "$conf_file" "D"

    cat <<EOF >> "$conf_file"
BOOT C:
EOF
    
    log i "Mounted base OS + game layer as C: (layered VHD)"
}

generate_autoexec_launch() {
    local conf_file="$1"
    local game_layer="$2"
    local savedata="$3"
    local launcher_dir="$4"
    
    log i "Mounting all VHD layers for game launch"
    
    cat <<EOF >> "$conf_file"
IMGMOUNT C "$VHD_BASE_PATH" -b "$game_layer" -b "$savedata" -t hdd
MOUNT A "$launcher_dir"
DEL "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\*"
COPY A:\\run_game.bat "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
MOUNT -u A
EOF

    # Make sure CD/HD/floppy are mounted before boot
    mount_disks "$conf_file" "D"

    cat <<EOF >> "$conf_file"
BOOT C:
EOF
    
    log i "Mounted OS base + game layer + savedata as C: (layered VHD)"
}

generate_autoexec_desktop() {
    local conf_file="$1"
    local vhd_base_path="$2"
    
    log i "Mounting base OS for desktop mode"
    
    cat <<EOF >> "$conf_file"
IMGMOUNT C "$vhd_base_path" -t hdd
EOF

    # Mount disks starting from D: (C: is already used by VHD)
    mount_disks "$conf_file" "D"

    cat <<EOF >> "$conf_file"
BOOT C:
EOF
    
    log i "Mounted base OS as C: (desktop mode)"
}

mount_disks() {
    local conf_file="$1"
    local next_drive="${2:-C}"
    
    # Mount floppy disks on A: and B:
    if [[ ${#FLOPPIES[@]} -gt 0 ]]; then
        if [[ ${#FLOPPIES[@]} -eq 1 ]]; then
            local floppy_cmd="IMGMOUNT A \"${FLOPPIES[0]}\" -t floppy"
            cat <<EOF >> "$conf_file"
REM Mount floppy disk
$floppy_cmd
EOF
            log i "Added floppy mount: A: (${FLOPPIES[0]})"
        else
            local floppy_cmd="IMGMOUNT A \"${FLOPPIES[0]}\" \"${FLOPPIES[1]}\" -t floppy"
            cat <<EOF >> "$conf_file"
REM Mount floppy disks
$floppy_cmd
EOF
            log i "Added floppy mounts: A: (${FLOPPIES[0]}), B: (${FLOPPIES[1]})"
            if [[ ${#FLOPPIES[@]} -gt 2 ]]; then
                log w "Warning: Only first 2 floppy disks supported (A: and B:). Ignoring remaining ${#FLOPPIES[@]}-2 floppy(ies)"
            fi
        fi
    fi
    
    # Mount hard disks starting from current next_drive
    for hd_path in "${HDISKS[@]}"; do
        local hd_drive="$next_drive"
        local hd_cmd="IMGMOUNT $hd_drive \"$hd_path\" -t hdd"
        cat <<EOF >> "$conf_file"
REM Mount hard disk
$hd_cmd
EOF
        log i "Added hard disk mount: $hd_drive: ($hd_path)"
        # Increment drive letter
        next_drive=$(printf "\\$(printf '%03o' $(($(printf '%d' "'$next_drive") + 1)))")
    done
    
    # Mount CD-ROMs on the remaining drive letters
    if [[ ${#CDROMS[@]} -gt 0 ]]; then
        local imgmount_cmd="IMGMOUNT $next_drive"
        for iso_path in "${CDROMS[@]}"; do
            imgmount_cmd="$imgmount_cmd \"$iso_path\""
        done
        imgmount_cmd="$imgmount_cmd -t cdrom"
        
        cat <<EOF >> "$conf_file"
REM Mount CD-ROMs
$imgmount_cmd
EOF
        
        log i "Added CD-ROM mount: $next_drive: (${#CDROMS[@]} image(s))"
    fi
}

# ============================================================================
# CONFIG GENERATION
# ============================================================================

create_launcher_bat() {
    local launcher_dir="$1"
    local launcher_bat="$launcher_dir/run_game.bat"
    
    mkdir -p "$launcher_dir"
    
    local game_filename=$(basename "$GAME_PATH")
    local game_filename_dos=$(echo "$game_filename" | tr '[:lower:]' '[:upper:]')
    
    {
        echo -e "REM Launcher for game\r"
        echo -e "@ECHO OFF\r"
        echo -e "CLS\r"
        echo -e "D:\r"
        echo -e "DIR\r"
        echo -e "REM Starting game...\r"
        echo -e "START /WAIT $game_filename_dos\r"
        echo -e "REM Game finished\r"
        echo -e "RUNDLL32.EXE USER.EXE,ExitWindows\r"
    } > "$launcher_bat"
    
    log d "Created launcher BAT at: $launcher_bat"
}

prepare_config() {
    rm -f "$TMP_CONF"
    cp "$dosbox_x_config" "$TMP_CONF"
    sed -i '/^\[autoexec\]/q' "$TMP_CONF"
    
    cat <<EOF >> "$TMP_CONF"

[autoexec]
EOF
}

generate_autoexec() {
    if [[ $DESKTOP_MODE -eq 1 ]]; then
        generate_autoexec_desktop "$TMP_CONF" "$VHD_BASE_PATH"
    elif [[ $INSTALL_MODE -eq 1 ]]; then
        if [[ $IS_OS_INSTALL -eq 1 ]]; then
            generate_autoexec_install_os "$TMP_CONF"
        else
            generate_autoexec_install_game "$TMP_CONF" "$VHD_GAME_LAYER"
        fi
    else
        create_launcher_bat "$LAUNCHER_DIR"
        generate_autoexec_launch "$TMP_CONF" "$VHD_GAME_LAYER" "$VHD_SAVEDATA" "$LAUNCHER_DIR"
    fi
}

log_config() {
    log d "Launching DOSBox-X with the following config:"
    log d "-----------------------------------"
    awk '/^\[autoexec\]/ {print_flag=1; print; next} /^\[/ {print_flag=0} print_flag' "$TMP_CONF"
    log d "-----------------------------------"
    echo ""
}

# ============================================================================
# MODE HANDLERS: --install
# ============================================================================

handle_install_os() {
    local os_config_dir="$1"
    local vhd_base_path="$2"
    
    IS_OS_INSTALL=1
    WIN_VERSION="$INSTALL_NAME"
    log i "OS install mode: Installing $WIN_VERSION"
    copy_base_vhd_from_template "$WIN_VERSION" "$vhd_base_path"
    
    # Update VHD_BASE_PATH after WIN_VERSION change
    VHD_BASE_PATH="$bios_path/$WIN_VERSION.vhd"
}

handle_install_game() {
    local vhd_base_path="$1"
    
    GAME_NAME_FOR_DIR="$INSTALL_NAME"
    log i "Game install mode: Installing $GAME_NAME_FOR_DIR"
    
    if [[ ! -f "$vhd_base_path" ]]; then
        log e "Windows VHD not found at: $vhd_base_path"
        log e "Please install the Windows image first using: $0 --install $WIN_VERSION"
        exit 1
    fi
    
    VHD_GAME_LAYER=$(create_game_layer_vhd "$GAME_NAME_FOR_DIR")
    VHD_SAVEDATA=$(create_savedata_vhd "$GAME_NAME_FOR_DIR")
}

handle_install_mode() {
    local os_config_dir="$1"
    local vhd_base_path="$2"
    
    if [[ -f "$os_config_dir/$INSTALL_NAME.conf" ]]; then
        handle_install_os "$os_config_dir" "$vhd_base_path"
    else
        handle_install_game "$vhd_base_path"
    fi
}

# ============================================================================
# MODE HANDLERS: --desktop
# ============================================================================

handle_desktop_mode() {
    log w "DESKTOP MODE - ALL CHANGES ARE PERMANENT TO BASE IMAGE!"
    log w "Any modifications will persist across all games."
    log w "Use only for troubleshooting/configuration."
    
    WIN_VERSION="$DESKTOP_VERSION"
    log i "Desktop mode: Launching base OS"
}

# ============================================================================
# MODE HANDLERS: normal launch
# ============================================================================

handle_launch_mode() {
    local game_path="$1"
    local roms_path_base="$2"
    
    GAME_NAME_FOR_DIR="$game_path"
    log i "Launch mode: Launching $GAME_NAME_FOR_DIR"
    
    local game_layer_path="$roms_path_base/windows9x/$GAME_NAME_FOR_DIR/game-layer.vhd"
    if [[ ! -f "$game_layer_path" ]]; then
        log e "Game layer VHD not found at: $game_layer_path"
        log e "Please install the game first using: $0 --install $GAME_NAME_FOR_DIR"
        exit 1
    fi
    
    VHD_GAME_LAYER="$game_layer_path"
    VHD_SAVEDATA=$(create_savedata_vhd "$GAME_NAME_FOR_DIR")
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    init_globals
    
    # Extract arguments from either CLI or environment
    local final_args
    mapfile -t final_args < <(extract_args_from_environment "$@")
    
    # Route based on first argument
    case "${final_args[0]}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --desktop)
            DESKTOP_MODE=1
            DESKTOP_VERSION="${final_args[1]}"
            if [[ -z "$DESKTOP_VERSION" || "$DESKTOP_VERSION" == --* ]]; then
                log e "--desktop requires an argument (win98 or win31)"
                exit 1
            fi
            WIN_VERSION="$DESKTOP_VERSION"
            ;;
        --makefs)
            MAKEFS_MODE=1
            MAKEFS_VERSION="${final_args[1]}"
            if [[ -z "$MAKEFS_VERSION" || "$MAKEFS_VERSION" == --* ]]; then
                log e "--makefs requires an argument (win98 or win31)"
                exit 1
            fi
            handle_makefs_mode
            ;;
        --install)
            INSTALL_MODE=1
            INSTALL_NAME="${final_args[1]}"
            if [[ -z "$INSTALL_NAME" || "$INSTALL_NAME" == --* ]]; then
                log e "--install requires an argument"
                exit 1
            fi
            # Check if it's a Windows version or a game
            if [[ -f "$OS_CONFIG_DIR/$INSTALL_NAME.conf" ]]; then
                WIN_VERSION="$INSTALL_NAME"
            else
                WIN_VERSION="${WIN_VERSION:-win98}"
            fi
            # Parse remaining args for --cdrom/--cd-rom, --floppy, --hd and -f flag
            for ((i=2; i<${#final_args[@]}; i++)); do
                if [[ "${final_args[$i]}" == "--cd-rom" || "${final_args[$i]}" == "--cdrom" ]]; then
                    ((i++))
                    CDROMS+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "--floppy" ]]; then
                    ((i++))
                    FLOPPIES+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "--hd" ]]; then
                    ((i++))
                    HDISKS+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "-f" ]]; then
                    FORCE_RECREATE=1
                fi
            done
            ;;
        *)
            # Game launch mode
            if [[ -z "${final_args[0]}" ]]; then
                log e "No game path provided, --install, or --desktop specified!"
                log i "Usage:"
                log i "  $0 win98 GameName              (launch game)"
                log i "  $0 --install GameName          (install game)"
                log i "  $0 --desktop win98             (desktop mode)"
                log i "Use '$0 --help' for more information."
                exit 1
            fi
            WIN_VERSION="${final_args[0]}"
            GAME_PATH="${final_args[1]}"
            ;;
    esac
    
    # Common setup
    setup_paths
    setup_launcher_dir
    verify_os_config
    
    # Execute mode
    case 1 in
        $DESKTOP_MODE)
            handle_desktop_mode
            ;;
        $MAKEFS_MODE)
            exit 0
            ;;
        $INSTALL_MODE)
            handle_install_mode "$OS_CONFIG_DIR" "$VHD_BASE_PATH"
            ;;
        *)
            handle_launch_mode "$GAME_PATH" "$roms_path"
            ;;
    esac
    
    # Prepare and launch
    prepare_config
    generate_autoexec
    log_config
    
    # Build DOSBox-X command with optional overrides
    local dosbox_cmd=("$component_path/bin/dosbox-x" "-conf" "$TMP_CONF")
    
    # Disable dynamic CPU during OS installation for stability and enable TURBO.
    # Prefer to write these values to the temporary config (TMP_CONF) using
    # set_setting_value when available; fall back to CLI -set overrides otherwise.
    if [[ $INSTALL_MODE -eq 1 && $IS_OS_INSTALL -eq 1 ]]; then
        # Persist the stabilization and performance settings into the temporary
        # configuration file so DOSBox-X reads them from config during startup.
        # We assume set_setting_value is available in the environment.
        log i "Applying cpu settings to temporary config ($TMP_CONF) via set_setting_value"
        set_setting_value "$TMP_CONF" "dynamic" "false" "dosbox-x" "cpu" || \
            log w "Failed to set TMP_CONF dynamic=false via set_setting_value"
        set_setting_value "$TMP_CONF" "turbo" "true" "dosbox-x" "cpu" || \
            log w "Failed to set TMP_CONF turbo=true via set_setting_value"
    fi
    
    # Final messages
    if [[ $INSTALL_MODE -eq 1 && $IS_OS_INSTALL -eq 1 ]]; then
        log i "Windows installation environment ready!"
        log i "Once complete, install games with: $0 --install <game_name>"
    fi
    
    echo ""

    # Run DOSBox-X directly (dynamic=false is enabled earlier during OS install)
    "${dosbox_cmd[@]}"
}

main "$@"
