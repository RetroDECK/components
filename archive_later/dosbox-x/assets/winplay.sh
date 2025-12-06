#!/bin/bash

source /app/libexec/global.sh

# This script launches DOSBox-X with a Windows 98/3.1 image and autostarts games
# It prepares a temporary configuration and BAT file for game installation and launching

# NOTE: logging helper `log()` is provided by the surrounding framework and
# is intentionally not defined here to avoid duplicate definitions. Use the
# framework-provided logger (e.g., log i "message").
# INITIALIZATION FUNCTIONS
# ============================================================================

init_globals() {
    # VHD layer paths - save_path should be provided by RetroDECK framework
    # - OS Layer: $bios_path/$WIN_VERSION.vhd
    # - Game Layer: $roms_path/<ESDE_SYSTEM_NAME>/<game name>.vhd
    # - Saves Layer: $save_path/<ESDE_SYSTEM_NAME>/dosbox-x/<game name>.sav.vhd
    SAVES_PATH="${save_path:-${XDG_DATA_HOME:-$HOME/.local/share}/retrodeck/saves}"
    VHD_SAVEDATA_DIR=""
    ESDE_SYSTEM_NAME=""

    # Initialize mode flags
    INSTALL_MODE=0
    INSTALL_NAME=""
    MAKEFS_MODE=0
    MAKEFS_VERSION=""
    DESKTOP_MODE=0
    DESKTOP_VERSION=""
    FORCE_RECREATE=0
    PACK_MODE=0
    PACK_GAME_NAME=""
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
    # Virtual size (MB) used for per-OS game layers and save overlays. This
    # will be set later (usually in setup_paths) based on WIN_VERSION.
    VHD_OS_SIZE_MB=""
    # Driver-copy behaviour during OS installs: minimal|all|none
    DRIVER_COPY_MODE="minimal"
    # This script runs inside the Flatpak runtime — do not attempt to use
    # host-only tools (qemu-img) here. All VHD creation/fallbacks must rely
    # on the bundled DOSBox-X imgmake invocation.
}

setup_paths() {
    log d "Looking for OS config files in component path first: $component_path/rd_config/os_configs"
    OS_CONFIG_DIR="${component_path:-}/rd_config/os_configs"
    if [[ ! -d "$OS_CONFIG_DIR" ]]; then
        OS_CONFIG_DIR="${dosbox_x_os_configs_dir:-$OS_CONFIG_DIR}"
    fi

    VHD_BASE_PATH="$bios_path/$WIN_VERSION.vhd"
    TMP_CONF="$XDG_CACHE_HOME/dosbox-x/winplay.conf"
    # Choose the default virtual size for layers and per-system path name based on WIN_VERSION.
    case "${WIN_VERSION,,}" in
        win98*) VHD_OS_SIZE_MB=4096 ;;
        win31*) VHD_OS_SIZE_MB=512  ;;
        *)       VHD_OS_SIZE_MB=4096 ;;
    esac

    case "${WIN_VERSION,,}" in
        win98*) ESDE_SYSTEM_NAME="windows9x" ;;
        win31*) ESDE_SYSTEM_NAME="windows3x" ;;
        *)       ESDE_SYSTEM_NAME="windows9x" ;;
    esac

    VHD_SAVEDATA_DIR="$SAVES_PATH/$ESDE_SYSTEM_NAME/dosbox-x"

    # If roms_path is not supplied by the framework, default to a sane location
    # in the user's home to avoid creating files at the root (e.g. /windows9x/...)
    if [[ -z "${roms_path:-}" ]]; then
        roms_path="${XDG_DATA_HOME:-$HOME/.local/share}/retrodeck/roms"
        log w "roms_path not set — defaulting to: $roms_path"
    fi
    mkdir -p "$XDG_CACHE_HOME/dosbox-x"
}

setup_launcher_dir() {
    local launcher_base_dir="$XDG_CACHE_HOME/dosbox-x"
    local launcher_tmp_dir=$(mktemp -d "${launcher_base_dir}/tmp.XXXX")
    LAUNCHER_DIR="$launcher_tmp_dir/launcher"

    # Cleanup on exit
    trap "rm -rf '$launcher_tmp_dir' 2>/dev/null || true" EXIT
}

# Sanitize a game/whatever name so it is safe to use as a filename for VHDs
# Replaces path separators and runs of non-alphanumeric/.-_ with a single '_'
# Keeps the basename readable but removes spaces and other problematic characters
sanitize_vhd_basename() {
    local name="$1"
    # Ensure there is a value
    if [[ -z "$name" ]]; then
        echo "unnamed"
        return 0
    fi

    # Replace path separators with underscores and collapse any sequence of
    # characters that are not a-zA-Z0-9, dot, underscore or hyphen into a single '_'
    local safe
    safe=$(printf '%s' "$name" | sed -E 's|/|_|g' | sed -E 's/[^A-Za-z0-9._-]+/_/g' | sed -E 's/^_+|_+$//g')

    # Fallback when sanitization strips everything
    if [[ -z "$safe" ]]; then
        safe="unnamed"
    fi

    echo "$safe"
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
            --package-game)
                PACK_MODE=1
                if [[ -z "$2" || "$2" == --* ]]; then
                    log e "--package-game requires a game name argument"
                    exit 1
                fi
                PACK_GAME_NAME="$2"
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
  winplay.sh --makefs win98                                         (Create Windows 98 VHD)
  winplay.sh --makefs win31                                         (Create Windows 3.1 VHD)
  winplay.sh --desktop win98                                        (Launch Windows 98 desktop)
  winplay.sh --desktop win31                                        (Launch Windows 3.1 desktop)
  winplay.sh --install win98 --cd-rom /path/to/WIN98SE.iso         (Install Windows 98)
  winplay.sh --install GameName --cd-rom /path/to/game.iso         (Install game to base OS)
  winplay.sh --game GameName --os win98 --cd-rom /path/to/game.iso (Play/install game)
  winplay.sh --game GameName --cd-rom /path/to/game.iso             (Play/install game with default win98)
  winplay.sh --help                                                  (Show this help)

UNIFIED GAME MODE:
  --game <name>            Launch or install a game (creates per-game VHD layer)
                          First run: installs the game; subsequent runs: plays the game
  --os <version>          Windows version for the game (default: win98)
  --cd-rom <path>         Mount ISO/CD-ROM image (multiple allowed)
  --cdrom <path>          Alias for --cd-rom

CREATE FILESYSTEM IMAGES / LAYER NAMING:
    OS Layer:  --makefs win98          Create 4GB FAT32 sparse VHD for Windows 98 at $bios_path/win98.vhd
                         --makefs win31          Create 512MB FAT16 sparse VHD for Windows 3.1 at $bios_path/win31.vhd

    Naming conventions:
        - OS Layer:   $bios_path/$WIN_VERSION.vhd
        - Game Layer: $roms_path/<ESDE_SYSTEM_NAME>/<game name>.vhd
        - Saves Layer: $save_path/<ESDE_SYSTEM_NAME>/dosbox-x/<game name>.sav.vhd

DESKTOP MODE (WARNING):
  --desktop win98         Launch Windows 98 base OS desktop (NO GAME)
  --desktop win31         Launch Windows 3.1 base OS desktop (NO GAME)

      ALL CHANGES MADE IN DESKTOP MODE ARE PERMANENT AND AFFECT THE BASE IMAGE!
      Any modifications, installations, or configurations will persist across all games.
      Use only for system setup or troubleshooting.
      NOT recommended for normal use - use --game for games instead.

PARAMETERS:
  --makefs <win98|win31>         Create pre-formatted VHD images
  --desktop <win98|win31>        Launch OS desktop (changes are permanent!)
  --game <name>                  Launch/install game (unified mode)
    --os <version>                 Windows version (default: win98)
    --cd-rom <path>                Mount ISO/CD-ROM image (multiple allowed)
    --cdrom <path>                 Alias for --cd-rom
  --install <name>               Install Windows version or game (legacy)
    --package-game <name>          Packaging-mode: create differencing VHD for <name> (host only)
    --drivers <minimal|all|none>   Control driver-copy during OS install (default: minimal)
  --help, -h                      Show this help

EXAMPLES:
  ./winplay.sh --makefs win98
  ./winplay.sh --install win98 --cd-rom ~/images/WIN98SE.iso
  ./winplay.sh --game "Doom" --cd-rom ~/images/doom-cd.iso
  ./winplay.sh --game "Doom"                    (replay, CD-ROM not needed)
  ./winplay.sh --game "SimCity" --os win95 --cd-rom ~/images/simcity.iso
  ./winplay.sh --desktop win98

HELP
}

# Self-test mode (disabled by default). Set WINPLAY_SELFTEST=1 to run a few
# quick checks for sanitize_vhd_basename without launching DOSBox-X.
if [[ "${WINPLAY_SELFTEST:-0}" == "1" ]]; then
    echo "Running winplay.sh self-tests (sanitize_vhd_basename)"
    test_inputs=("Rages of Mages II" "a/../weird*name" "   " "game.name.vhd")
    for t in "${test_inputs[@]}"; do
        printf '%-30s -> %s\n' "$t" "$(sanitize_vhd_basename "$t")"
    done
    exit 0
fi

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
    # Prepare the path for the per-game VHD layer (game + saves unified).
    # This file is created as a differencing VHD backed by base.vhd.
    # All game files and saves go into this single layer.
    # Build both the raw filename and a sanitized filename. If a file already
    # exists using the original (possibly spaced) name, prefer it to remain
    # backwards-compatible. Otherwise use the sanitized version to avoid
    # problematic characters causing downstream issues (vhdmake/creation).
    local sanitized_name
    sanitized_name=$(sanitize_vhd_basename "$game_name")
    local game_layer_orig="$roms_path/$ESDE_SYSTEM_NAME/${game_name}.vhd"
    local game_layer_safe="$roms_path/$ESDE_SYSTEM_NAME/${sanitized_name}.vhd"

    local game_layer
    if [[ -f "$game_layer_orig" ]]; then
        game_layer="$game_layer_orig"
    else
        game_layer="$game_layer_safe"
    fi
    mkdir -p "$(dirname "$game_layer")"

    # VHD creation happens inside autoexec via vhdmake (vhdmake is DOSBox-X internal command, not external)
    # Just return the path; vhdmake in autoexec will create it on first launch
    if [[ ! -f "$game_layer" ]]; then
        log i "Game-layer VHD path prepared (will be created by vhdmake in autoexec): $game_layer"
    else
        log i "Game-layer VHD already exists: $game_layer"
    fi

    echo "$game_layer"
}

# Packaging-time helper: create a differencing VHD for game_name using qemu-img
# This is intended to run during build/packaging on the host (not in Flatpak runtime)
create_packaged_game_layer_vhd() {
    local game_name="$1"
    # Prefer sanitized filenames but preserve existing files with the original
    # name (backwards compatibility). This avoids packaging/creation issues with
    # strange characters or spaces in filenames.
    local sanitized_name
    sanitized_name=$(sanitize_vhd_basename "$game_name")
    local game_layer_orig="$roms_path/$ESDE_SYSTEM_NAME/${game_name}.vhd"
    local game_layer_safe="$roms_path/$ESDE_SYSTEM_NAME/${sanitized_name}.vhd"

    local game_layer
    if [[ -f "$game_layer_orig" ]]; then
        game_layer="$game_layer_orig"
    else
        game_layer="$game_layer_safe"
    fi

    if [[ -z "$VHD_BASE_PATH" || ! -f "$VHD_BASE_PATH" ]]; then
        log e "Base VHD not found at: $VHD_BASE_PATH — cannot package game layer"
        return 1
    fi

    mkdir -p "$(dirname "$game_layer")"

    if [[ -f "$game_layer" && $FORCE_RECREATE -ne 1 ]]; then
        log w "Game-layer already exists: $game_layer (use -f/--force to recreate)"
        echo "$game_layer"
        return 0
    fi

    # Prefer the DOSBox-X vhdmake / imgmake tooling to create linked images
    # as that's the native implementation known to produce chains compatible
    # with DOSBox-X. Try component_path/bin/dosbox-x first, then PATH dosbox-x,
    # then fall back to qemu-img (some formats don't support backing-file).
    local dosbox_exec=""
    if [[ -x "${component_path:-}/bin/dosbox-x" ]]; then
        dosbox_exec="${component_path}/bin/dosbox-x"
    elif command -v dosbox-x >/dev/null 2>&1; then
        dosbox_exec="dosbox-x"
    fi

    if [[ -n "$dosbox_exec" ]]; then
        log i "Packaging: creating differencing VHD via DOSBox-X vhdmake: $game_layer -> backing $VHD_BASE_PATH"
        rm -f "$game_layer" 2>/dev/null || true
        local outtmp
        outtmp=$(mktemp)
        # Use vhdmake with '-l base child' to create a linked VHD
        "$dosbox_exec" -c "vhdmake -l \"$VHD_BASE_PATH\" \"$game_layer\"" -c "exit" >"$outtmp" 2>&1
        local vhdmake_ec=$?
        if [[ $vhdmake_ec -eq 0 && -s "$game_layer" ]]; then
            log i "Packaged game-layer created via DOSBox-X: $game_layer"
            rm -f "$outtmp" 2>/dev/null || true
            echo "$game_layer"
            return 0
        else
            log w "DOSBox-X vhdmake failed (exit=$vhdmake_ec) — output (first 4k):"
            head -c 4096 "$outtmp" | sed 's/^/    /'
            rm -f "$outtmp" 2>/dev/null || true
            # fallthrough to try qemu-img if available
        fi
    fi

    if command -v qemu-img >/dev/null 2>&1; then
        log i "Packaging: attempting fallback via qemu-img: $game_layer -> backing $VHD_BASE_PATH"
        rm -f "$game_layer" 2>/dev/null || true
        # Some formats don't allow backing_file on create (vpc), so try a qcow2
        # child (good for packing) and, if necessary, convert to vpc.
        local tmp_child_qcow="$game_layer.qcow2"
        if qemu-img create -f qcow2 -o backing_file="$VHD_BASE_PATH" "$tmp_child_qcow" >/dev/null 2>&1; then
            # Convert to vpc format if DOSBox-X requires vhd/vpc
            if qemu-img convert -O vpc "$tmp_child_qcow" "$game_layer" >/dev/null 2>&1; then
                rm -f "$tmp_child_qcow" 2>/dev/null || true
                log i "Packaged game-layer created via qemu-img (qcow2->vpc): $game_layer"
                echo "$game_layer"
                return 0
            else
                log w "qemu-img convert -> vpc failed; leaving qcow2 child at: $tmp_child_qcow"
                echo "$tmp_child_qcow"
                return 0
            fi
        else
            log e "qemu-img create (qcow2 backing) failed — cannot create differencing child for: $game_layer"
            return 1
        fi
    fi

    log e "No supported host tool found to create reliable differencing VHD (tried DOSBox-X vhdmake and qemu-img)"
    return 1
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

    # Optionally copy drivers from the CD to the Windows system directory to
    # reduce prompts during installation. Controlled by --drivers {minimal|all|none}
    if [[ "${DRIVER_COPY_MODE}" != "none" ]]; then
        if [[ "${DRIVER_COPY_MODE}" == "all" ]]; then
            cat <<'EOF' >> "$conf_file"
REM Copy as many files as possible from the CD to C:\WINDOWS\SYSTEM
IF NOT EXIST C:\WINDOWS\SYSTEM MD C:\WINDOWS\SYSTEM
REM Copy full WIN98 and DRIVERS directories (recursive copy where available)
IF EXIST D:\WIN98 XCOPY D:\WIN98 C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
IF EXIST D:\DRIVERS XCOPY D:\DRIVERS C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
REM Also copy any root-level device files that might be directly requested
IF EXIST D:\*.VXD COPY /Y D:\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\*.DRV COPY /Y D:\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
EOF
        else
            # 'minimal' behaviour (copy specific likely-needed files only)
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
        fi
    fi

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
EOF
    log i "Setup: VHD mounted, ready for installation"
}

generate_autoexec_launch() {
    local conf_file="$1"
    local game_layer="$2"
    local savedata="$3"
    local launcher_dir="$4"

    log i "Creating autoexec for game launch (eXoWin9x-style: C=write-layer, D=game)"

    # Prefer explicit parameters from the caller, but fall back to global
    # variables for compatibility with older flows.
    local game_layer="${game_layer:-$GAME_VHD_PATH}"
    local savedata="${savedata:-$VHD_WRITE_LAYER}"

    # C: = differencing VHD for Windows/saves (write layer, backed by base.vhd)
    # D: = game VHD or directory
    # New sequence (safer): mount base read-only, create differencing child with
    # vhdmake -diff, then mount the child. This avoids race/lock issues on
    # certain DOSBox-X builds when creating/writing difference images directly.
    # Use IMGMAKE -link to create a differencing child backed by the base
    # image and mount it as C:. This avoids vhdmake differencing issues on
    # some DOSBox-X builds.
    cat >> "$conf_file" <<EOF
IMGMAKE "$savedata" -link "$VHD_BASE_PATH"
IMGMOUNT C "$savedata" -t hdd
IMGMOUNT D "$game_layer" -t hdd
MOUNT A "$launcher_dir"
DEL "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\*"
COPY A:\\run_game.bat "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
MOUNT -u A
EOF

    # Mount CD-ROMs (starting from E: since C: and D: are taken)
    mount_disks "$conf_file" "E"

    cat <<EOF >> "$conf_file"
BOOT -l C:
EOF

    log i "Autoexec ready: C=write-layer, D=game, E+=CD/HD/floppy"
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

    # Create launcher BAT with proper Windows CRLF line endings using printf.
    # Use printf instead of echo -e to avoid shell-dependent escapes and ensure \r\n.
    {
        printf '%s\r\n' "REM Launcher for game"
        printf '%s\r\n' "@ECHO OFF"
        printf '%s\r\n' "CLS"
        printf '%s\r\n' "D:"
        printf '%s\r\n' "DIR"
        printf '%s\r\n' "REM Starting game..."
        printf '%s\r\n' "START /WAIT $game_filename_dos"
        printf '%s\r\n' "REM Game finished"
        printf '%s\r\n' "RUNDLL32.EXE USER.EXE,ExitWindows"
    } > "$launcher_bat"

    log d "Created launcher BAT at: $launcher_bat"
}

prepare_config() {
    rm -f "$TMP_CONF"
    # Create TMP_CONF from the OS-specific config (if available). The launch
    # order will be: -conf $dosbox_x_config -conf $TMP_CONF so that entries in
    # the OS-specific config override the base. If no OS config is available,
    # fall back to copying the base config so runtime writers (eg set_setting_value)
    # can operate on TMP_CONF.
    if [[ -n "$OS_CONFIG_DIR" && -n "$WIN_VERSION" && -f "$OS_CONFIG_DIR/$WIN_VERSION.conf" ]]; then
        log d "Preparing TMP_CONF from OS config: $OS_CONFIG_DIR/$WIN_VERSION.conf"
        cp "$OS_CONFIG_DIR/$WIN_VERSION.conf" "$TMP_CONF"
    elif [[ -f "$dosbox_x_config" ]]; then
        log d "No OS config found; using base dosbox config as TMP_CONF: $dosbox_x_config"
        cp "$dosbox_x_config" "$TMP_CONF"
    else
        > "$TMP_CONF"
    fi

    # Strip all comments (full-line and inline '#' comments) from the temporary
    # config so the runtime-only TMP_CONF is clean and doesn't contain commented
    # configuration values. This removes the '#' and everything after it on a
    # line then drops blank lines.
    if [[ -f "$TMP_CONF" ]]; then
        awk '{ sub(/#.*/, ""); if (match($0,/[^[:space:]]/)) print }' "$TMP_CONF" > "${TMP_CONF}.no_comments" && mv "${TMP_CONF}.no_comments" "$TMP_CONF"
        log d "Stripped comments from temporary config: $TMP_CONF"
    fi
    # Remove [autoexec] section and everything after it, then add fresh [autoexec]
    sed -i '/^\[autoexec\]/,$d' "$TMP_CONF"

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
        fi
    else
        create_launcher_bat "$LAUNCHER_DIR"
        # Pass the prepared game-layer and write-layer into the autoexec generator.
        # The generator will fall back to globals if either is empty.
        generate_autoexec_launch "$TMP_CONF" "$VHD_GAME_LAYER" "$VHD_WRITE_LAYER" "$LAUNCHER_DIR"
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
    configurator_generic_dialog "RetroDECK - Installing $WIN_VERSION" "Please follow the Windows Setup prompts to install the operating system and set it up for your needings.\nYou might want to change the desktop resolution and the colors.\n\nThe installation will start in TURBO mode, but any key input will disable it, please re-enable it during the loading bars to speed them up."
    copy_base_vhd_from_template "$WIN_VERSION" "$vhd_base_path"

    # Update VHD_BASE_PATH after WIN_VERSION change
    VHD_BASE_PATH="$bios_path/$WIN_VERSION.vhd"
}

handle_install_game() {
    local vhd_base_path="$1"

    # Treat the install name exactly as provided by the user. The only
    # special-case: if the name ends with .vhd (any case) strip that suffix
    # because we will append ".vhd" ourselves when creating the game layer
    # file. This keeps behaviour simple and predictable for callers.
    GAME_NAME_FOR_DIR="$INSTALL_NAME"
    # If the user passed a path, use only the basename so we always create the
    # layer VHD under roms_path/<ESDE_SYSTEM_NAME>/<basename>.vhd rather than creating
    # nested directories under the roms path.
    if [[ "$GAME_NAME_FOR_DIR" == */* ]]; then
        GAME_NAME_FOR_DIR="$(basename "$GAME_NAME_FOR_DIR")"
    fi

    # Strip trailing .vhd if present so callers can pass either "name" or
    # "name.vhd" — we still always create <name>.vhd later.
    if [[ "${GAME_NAME_FOR_DIR,,}" == *.vhd ]]; then
        GAME_NAME_FOR_DIR="${GAME_NAME_FOR_DIR%.[vV][hH][dD]}"
    fi
    log i "Game install mode: Installing $GAME_NAME_FOR_DIR"

    if [[ ! -f "$vhd_base_path" ]]; then
        log e "Windows VHD not found at: $vhd_base_path"
        log e "Please install the Windows image first using: $0 --install $WIN_VERSION"
        exit 1
    fi

    # Try to create a game-layer using the explicit install name
    log d "Attempting game-layer creation with requested install name: '$GAME_NAME_FOR_DIR'"

    # If VHD wasn't created and a CD-ROM was provided, fall back to deriving the
    # game name from the first CD-ROM image's basename (strip extension). This is
    # convenient when callers pass an install name that differs from the CD's
    # filename — e.g. user typed 'Rages of Mages II' but ISO is 'Rage of Mages II...'.
    if [[ -z "$VHD_GAME_LAYER" || ! -f "$VHD_GAME_LAYER" ]]; then
        if [[ ${#CDROMS[@]} -gt 0 ]]; then
            local iso_basename
            iso_basename="$(basename "${CDROMS[0]}")"
            iso_basename="${iso_basename%.*}"
            # Strip trailing .vhd if someone used weird filenames like name.vhd.iso
            if [[ "${iso_basename,,}" == *.vhd ]]; then
                iso_basename="${iso_basename%.[vV][hH][dD]}"
            fi

            # Only try fallback if the name differs from the supplied name
            if [[ "$iso_basename" != "$GAME_NAME_FOR_DIR" ]]; then
                log i "Primary game-layer creation did not succeed; falling back to ISO-derived name: '$iso_basename'"
                GAME_NAME_FOR_DIR="$iso_basename"
                VHD_GAME_LAYER=$(create_game_layer_vhd "$GAME_NAME_FOR_DIR")
            else
                log w "Game-layer not created by either requested name or ISO basename; no VHD prepared."
            fi
        else
            log w "Game-layer creation failed and no CD-ROM provided to derive a name from."
        fi
    fi
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



    # Following eXoWin9x architecture:
    # C: = write-layer VHD (differencing VHD for Windows/saves, stored in savedata_dir with .sav.vhd suffix)
    # D: = game VHD (the actual game, stored in roms_path)

    # C: write-layer (differencing VHD backed by base.vhd)
    local sanitized_game_name
    sanitized_game_name=$(sanitize_vhd_basename "$GAME_NAME_FOR_DIR")

    local write_layer_orig="$VHD_SAVEDATA_DIR/$GAME_NAME_FOR_DIR.sav.vhd"
    local write_layer_safe="$VHD_SAVEDATA_DIR/$sanitized_game_name.sav.vhd"

    if [[ -f "$write_layer_orig" ]]; then
        VHD_WRITE_LAYER="$write_layer_orig"
    else
        VHD_WRITE_LAYER="$write_layer_safe"
    fi

    mkdir -p "$(dirname "$VHD_WRITE_LAYER")"
    log i "Write-layer VHD (C:): $VHD_WRITE_LAYER"

    # D: game layer - check both new and old layouts for compatibility
    local alt_game_vhd="$roms_path_base/$ESDE_SYSTEM_NAME/$GAME_NAME_FOR_DIR.vhd"
    local alt_game_vhd_safe="$roms_path_base/$ESDE_SYSTEM_NAME/$sanitized_game_name.vhd"
    local old_game_vhd="$roms_path_base/$ESDE_SYSTEM_NAME/$GAME_NAME_FOR_DIR/game-layer.vhd"

    if [[ -f "$old_game_vhd" ]]; then
        GAME_VHD_PATH="$old_game_vhd"
        log i "Using existing game VHD (old layout): $old_game_vhd"
    elif [[ -f "$alt_game_vhd" ]]; then
        GAME_VHD_PATH="$alt_game_vhd"
        log i "Using existing game VHD (D: - original name): $alt_game_vhd"
    else
        GAME_VHD_PATH="$alt_game_vhd_safe"
        log i "Game VHD path (D:): $GAME_VHD_PATH"
        mkdir -p "$(dirname "$GAME_VHD_PATH")"
    fi

    if [ ! -f "$GAME_VHD_PATH" ]; then
        log i "Game VHD not found, showing dialog"
        configurator_generic_dialog "RetroDECK - Game Install" "The game drive $(basename "$GAME_VHD_PATH") should be now created.\n\nPlease install your game to D:\\ inside Windows environmnet to make sure that OS and Game will be separated.\n\n\NOTE: diffrentely on how usually RetroDECK works, with this emulator the saves are split both inside the game vhd file\nand in the saves file that will be created.\nUnfortunately this is a limitation of $WIN_VERSION.\n\nSo be aware that you will need to backup both the game and the saves files."
        log i "First-time game launch: user instructed to install game on D:\\"
    fi
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
        --package-game)
            PACK_MODE=1
            PACK_GAME_NAME="${final_args[1]}"
            if [[ -z "$PACK_GAME_NAME" || "$PACK_GAME_NAME" == --* ]]; then
                log e "--package-game requires a game name"
                exit 1
            fi
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
            # Parse remaining args for --cdrom/--cd-rom, --floppy, --hd, -f flag and --drivers
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
                elif [[ "${final_args[$i]}" == "--drivers" ]]; then
                    ((i++))
                    DRIVER_COPY_MODE="${final_args[$i]}"
                    if [[ ! "${DRIVER_COPY_MODE}" =~ ^(minimal|all|none)$ ]]; then
                        log e "Invalid --drivers option: ${DRIVER_COPY_MODE} (must be minimal|all|none)"
                        exit 1
                    fi
                fi
            done
            ;;
        --game)
            # Game launch/install mode (unified)
            GAME_PATH="${final_args[1]}"
            if [[ -z "$GAME_PATH" || "$GAME_PATH" == --* ]]; then
                log e "--game requires a game name argument"
                exit 1
            fi
            WIN_VERSION="${WIN_VERSION:-win98}"
            # Parse remaining args for --os, --cdrom, --floppy, --hd, etc.
            for ((i=2; i<${#final_args[@]}; i++)); do
                if [[ "${final_args[$i]}" == "--os" ]]; then
                    ((i++))
                    WIN_VERSION="${final_args[$i]}"
                elif [[ "${final_args[$i]}" == "--cd-rom" || "${final_args[$i]}" == "--cdrom" ]]; then
                    ((i++))
                    CDROMS+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "--floppy" ]]; then
                    ((i++))
                    FLOPPIES+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "--hd" ]]; then
                    ((i++))
                    HDISKS+=("${final_args[$i]}")
                elif [[ "${final_args[$i]}" == "--drivers" ]]; then
                    ((i++))
                    DRIVER_COPY_MODE="${final_args[$i]}"
                    if [[ ! "${DRIVER_COPY_MODE}" =~ ^(minimal|all|none)$ ]]; then
                        log e "Invalid --drivers option: ${DRIVER_COPY_MODE} (must be minimal|all|none)"
                        exit 1
                    fi
                fi
            done
            ;;
        *)
            # Game launch mode (legacy: first arg is game name, default win98)
            if [[ -z "${final_args[0]}" ]]; then
                log e "No game path provided, --install, --game, or --desktop specified!"
                log i "Usage:"
                log i "  $0 --game GameName --cdrom '...iso'  (launch/install game)"
                log i "  $0 --install GameName                (install OS or game)"
                log i "  $0 --desktop win98                   (desktop mode)"
                log i "Use '$0 --help' for more information."
                exit 1
            fi
            WIN_VERSION="${WIN_VERSION:-win98}"
            GAME_PATH="${final_args[0]}"
            ;;
    esac

    # Ensure a default WIN_VERSION when not supplied
    WIN_VERSION="${WIN_VERSION:-win98}"

    # Common setup
    setup_paths
    setup_launcher_dir
    # If packaging-only mode was requested, skip runtime verification and run the
    # host packaging helper (must be executed during develop/packaging).
    if [[ $PACK_MODE -eq 1 ]]; then
        if [[ -z "$PACK_GAME_NAME" ]]; then
            log e "--package-game requires a game name"
            exit 1
        fi
        create_packaged_game_layer_vhd "$PACK_GAME_NAME"
        exit $?
    fi

    verify_os_config

    # Packaging-only flow (run on host during packaging).
    if [[ $PACK_MODE -eq 1 ]]; then
        if [[ -z "$PACK_GAME_NAME" ]]; then
            log e "--package-game requires a game name"
            exit 1
        fi
        create_packaged_game_layer_vhd "$PACK_GAME_NAME"
        exit $?
    fi

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

    # Build DOSBox-X command with optional overrides; pass base config first
    # then the OS-specific TMP_CONF so the last file wins for duplicate settings.
    local dosbox_cmd=("$component_path/bin/dosbox-x")
    if [[ -f "$dosbox_x_config" ]]; then
        dosbox_cmd+=("-conf" "$dosbox_x_config")
    fi
    # TMP_CONF is created from OS config (or from base when OS config missing)
    dosbox_cmd+=("-conf" "$TMP_CONF")

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

log d "Config file used:\n$(cat "$TMP_CONF")"
