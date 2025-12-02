#!/bin/bash

# This script launches DOSBox-X with a Windows 98 image and autostarts a specified game.
# It prepares a temporary configuration and BAT file to mount the game directory and run the game executable.
# Usage:
#   winplay.sh <windows_version> <path_to_game_executable>
#   winplay.sh --install "<Game Name>" [--cd-rom /path/to/cd1.iso] [--cd-rom /path/to/cd2.iso ...]

# parse args
INSTALL_MODE=0
INSTALL_NAME=""
CDROMS=()
WIN_VERSION=""
GAME_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            INSTALL_MODE=1
            INSTALL_NAME="$2"
            shift 2
            ;;
        --cd-rom|--cdrom)
            CDROMS+=("$2")
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [<windows_version> <path_to_game_executable>] | --install \"<Game Name>\" [--cd-rom /path/to/cd.iso ...]"
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

# default windows version if not provided
WIN_VERSION="${WIN_VERSION:-win98}"

# if no GAME_PATH and not installing, open DOSBox-X directly
if [[ -z "$GAME_PATH" && $INSTALL_MODE -eq 0 ]]; then
    log i "No game path provided and --install not used; opening DOSBox-X directly."
    exec "$component_path/bin/dosbox-x"
fi

# Prefer component-local os-configs directory (per user request)
log d "Looking for OS config files in component path first: $component_path/rd_config/os-configs"
OS_CONFIG_DIR="${component_path:-}/rd_config/os-configs"
if [[ ! -d "$OS_CONFIG_DIR" ]]; then
    # fallback to old variable if present
    OS_CONFIG_DIR="${dosbox_x_os_configs_dir:-$OS_CONFIG_DIR}"
fi

DOXBOX_CONF="$OS_CONFIG_DIR/$WIN_VERSION.conf"
if [[ ! -f "$DOXBOX_CONF" ]]; then
    log e "Windows version '$WIN_VERSION' not recognized (missing config: $DOXBOX_CONF)"
    log i "Supported versions are (from: $OS_CONFIG_DIR):"
    if [[ -d "$OS_CONFIG_DIR" ]]; then
        for cfg in "$OS_CONFIG_DIR"/*.conf; do
            base_cfg="$(basename "$cfg")"
            echo " - ${base_cfg%.conf}"
        done
    else
        echo " (no os-configs directory found at $OS_CONFIG_DIR)"
    fi
    exit 1
fi

if [[ ! -f "$bios_path/$WIN_VERSION.img" ]]; then
    log e "Windows image for version '$WIN_VERSION' not found at: $bios_path/$WIN_VERSION.img"
    log e "Please ensure the image is present to proceed, check the wiki to learn how to create a Windows image for DOSBox-X."
    exit 1
fi

TMP_CONF="$XDG_CACHE_HOME/dosbox-x/winplay.conf"
# Create a temporary working dir for the launcher inside the cache folder
# Prefer XDG_CACHE_HOME to place temporary files where the flatpak sandbox can access
LAUNCHER_BASE_DIR="$XDG_CACHE_HOME/dosbox-x"
mkdir -p "$LAUNCHER_BASE_DIR"

# Create a temp directory under $XDG_CACHE_HOME/dosbox-x so DOSBox launched inside
# flatpak can mount it and see the files.
LAUNCHER_TMP_DIR=$(mktemp -d "${LAUNCHER_BASE_DIR}/tmp.XXXX")
LAUNCHER_BAT="$LAUNCHER_TMP_DIR/launcher/run_game.bat"

# Ensure temporary launcher dir is removed when the script exits
cleanup_tmpdir() {
    rm -rf "$LAUNCHER_TMP_DIR" || true
}
trap cleanup_tmpdir EXIT

rm -f "$TMP_CONF" "$LAUNCHER_BAT"

# Copy base config
cp "$dosbox_x_config" "$TMP_CONF"

# Strip old autoexec content
sed -i '/^\[autoexec\]/q' "$TMP_CONF"

if [[ $INSTALL_MODE -eq 1 ]]; then
    if [[ -z "$INSTALL_NAME" ]]; then
        log e "--install mode requires a game name."
        exit 1
    fi
    # create install dir under roms_path/windows9x/<game name>
    INSTALL_DIR="$roms_path/windows9x/$INSTALL_NAME"
    mkdir -p "$INSTALL_DIR"
    GAME_DIR="$INSTALL_DIR"
    # In install mode we don't create a launcher BAT — we expect the user to run installer inside Windows
    ORIG_GAME_EXE=""
else
    GAME_DIR="$(dirname "$GAME_PATH")"
    ORIG_GAME_EXE="$(basename "$GAME_PATH")"
fi

# Best-effort conversion to DOS 8.3 filename (uppercase, allowed chars, truncated to 8.3)
# Note: this is a best-effort translation — if the real shortname on the filesystem
# differs (e.g. Windows adds a ~1 suffix), this script does not query filesystem
# shortnames. This keeps the launcher within DOS filename limits for legacy apps.
GAME_NAME="${ORIG_GAME_EXE%.*}"
GAME_EXT="${ORIG_GAME_EXE##*.}"
if [[ "${GAME_NAME}" == "${ORIG_GAME_EXE}" ]]; then
    # no extension found
    GAME_EXT=""
fi

# sanitize: uppercase, allow only A-Z0-9, replace other chars with _
GAME_NAME_CLEAN=$(echo "${GAME_NAME}" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9]/_/g')
GAME_EXT_CLEAN=$(echo "${GAME_EXT}" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9]//g')

# truncate to 8.3
GAME_NAME_TRUNC=${GAME_NAME_CLEAN:0:8}
GAME_EXT_TRUNC=${GAME_EXT_CLEAN:0:3}

if [[ -n "$GAME_EXT_TRUNC" ]]; then
    GAME_EXE="${GAME_NAME_TRUNC}.${GAME_EXT_TRUNC}"
else
    GAME_EXE="${GAME_NAME_TRUNC}"
fi
LAUNCHER_DIR="$(dirname "$LAUNCHER_BAT")"

log i "Launching game: \"$GAME_EXE\" from directory: \"$GAME_DIR\""
log d "Using temporary config: $TMP_CONF"
log d "Launcher BAT: $LAUNCHER_BAT"
log d "D drive will mount game directory: $GAME_DIR"
log d "Sanitized game path: $GAME_EXE"

# Create launcher BAT on host → mounted as D:
if [[ $INSTALL_MODE -eq 0 ]]; then
    mkdir -p "$LAUNCHER_DIR"
    # Write BAT file with Windows CRLF line endings
    {
        echo -e "E:\r"
        echo -e "START /wait $GAME_EXE\r"
        echo -e "RUNDLL32.EXE USER.EXE,ExitWindows\r"
    } > "$LAUNCHER_BAT"
else
    log i "Install mode active — not creating launcher BAT."
fi

# C: - the Windows 98 image
# D: - the game direcotry mounted as CD-ROM (useful for games that check for CD)
# E: - the game directory
# F: - the launcher directory containing the run_game.bat

cat <<EOF >> "$TMP_CONF"

[autoexec]
IMGMOUNT C "$bios_path/$WIN_VERSION.img" -t hdd

EOF

if [[ $INSTALL_MODE -eq 1 ]]; then
    # In install mode, just clean up old launcher; placeholder cleanup will be done by host after DOSBox-X exits
    cat <<EOF >> "$TMP_CONF"
# If an old launcher is present, remove it so it doesn't auto-run
DEL "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
EOF
else
    # Temporary mounting launcher dir as A:, just to copy the BAT to startup
    cat <<EOF >> "$TMP_CONF"
MOUNT A "$LAUNCHER_DIR"
REM remove any existing files from Startup so we don't leave stale launchers
DEL "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\*"
COPY A:\\run_game.bat "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
MOUNT -u A
EOF
fi

# Mounting the game directory as D: (Hard Disk)
# In install mode we create temporary sparse placeholder files (DELETE_ME_BEFORE_INSTALL_*.img)
# inside the installation directory so that when DOSBox-X mounts the directory,
# it sees large files and reports the available space as much larger.
if [[ $INSTALL_MODE -eq 1 ]]; then
    # create placeholder sparse files under INSTALL_DIR so when mounted, Windows sees more space
    IMG_PREFIX="$INSTALL_DIR/DELETE_ME_BEFORE_INSTALL"
    CHUNK_MB=512   # per-image chunk
    MAX_TOTAL_MB=4096
    total_mb=0
    created_images=()

    while [[ $total_mb -lt $MAX_TOTAL_MB ]]; do
        idx=$(( total_mb / CHUNK_MB + 1 ))
        size_mb=$CHUNK_MB
        img_file="${IMG_PREFIX}_${idx}.img"

        # quick available space check (KB) — stop if host doesn't have at least 1MB free
        avail_kb=$(df --output=avail -k "$INSTALL_DIR" 2>/dev/null | tail -n1 || echo 0)
        if [[ -z "$avail_kb" || $avail_kb -lt 1024 ]]; then
            log d "Not enough disk space available, stopping placeholder creation at ${total_mb}MB"
            break
        fi

        # try to create sparse image; if that fails stop
        if ! truncate -s "${size_mb}M" "$img_file" 2>/dev/null; then
            log d "Failed to create sparse file, stopping at ${total_mb}MB"
            break
        fi

        # verify image exists
        if [[ -f "$img_file" ]]; then
            created_images+=("$img_file")
            total_mb=$(( total_mb + size_mb ))
            log d "Created placeholder file $idx: ${size_mb}MB"
        else
            break
        fi
    done

    # Mount the directory containing the placeholder files
    cat <<EOF >> "$TMP_CONF"
MOUNT D "$GAME_DIR" -freesize 4096
EOF
    
    if [[ ${#created_images[@]} -gt 0 ]]; then
        log i "Created ${#created_images[@]} placeholder files (total ${total_mb}MB) in $GAME_DIR"
    else
        log w "No placeholder files created, mounting directory as-is"
    fi
else
    cat <<EOF >> "$TMP_CONF"
MOUNT D "$GAME_DIR" -freesize 4096
EOF
fi

# Mount any provided CD-ROMs from E onward
if [[ ${#CDROMS[@]} -gt 0 ]]; then
    # ASCII 'E' == 69
    for i in "${!CDROMS[@]}"; do
        iso_path="${CDROMS[$i]}"
        drive_letter=$(printf "\\$(printf '%03o' $((69 + i)) )")
        cat <<EOF >> "$TMP_CONF"
IMGMOUNT $drive_letter "$iso_path" -t iso
EOF
        log d "Added CD-ROM mount: $drive_letter -> $iso_path"
    done
fi

# Booting Windows
cat <<EOF >> "$TMP_CONF"
BOOT C:
EOF

if [[ $INSTALL_MODE -eq 1 ]]; then
    log i "Launching $WIN_VERSION (install mode) — created/using: $GAME_DIR"
else
    log i "Launching $WIN_VERSION and autostarting game..."
    # Sanity check: ensure the launcher exists and is readable before launching.
    if [[ ! -f "$LAUNCHER_BAT" ]]; then
        log e "launcher not found at '$LAUNCHER_BAT' — aborting"
        exit 2
    fi
fi

if [[ $INSTALL_MODE -eq 0 ]]; then
    log d "Launcher BAT content:"
    log d "-----------------------------------"
    cat "$LAUNCHER_BAT"
    log d "-----------------------------------"
fi
log d "Launching DOSBox-X with the following config:"
log d "-----------------------------------"
awk '/^\[autoexec\]/ {print_flag=1; print; next} /^\[/ {print_flag=0} print_flag' "$TMP_CONF"
log d "-----------------------------------"

echo ""
echo ""
echo ""

# Launch DOSBox-X using the generated config
"$component_path/bin/dosbox-x" -conf "$TMP_CONF"
