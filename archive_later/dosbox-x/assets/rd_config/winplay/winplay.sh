#!/bin/bash

# This script launches DOSBox-X with a Windows 98 image and autostarts a specified game.
# It prepares a temporary configuration and BAT file to mount the game directory and run the game executable.
# Usage: winplay.sh <windows_version> <path_to_game_executable>

WIN_VERSION="${1:-win98}"
GAME_PATH="$2"
if [[ -z "$GAME_PATH" ]]; then
    log i "No game path provided, opening DOSBox-X directly."
    exec "$component_path/bin/dosbox-x"
fi

DOXBOX_CONF="$dosbox_x_os_configs_dir/$WIN_VERSION.conf"
if [[ ! -f "$DOXBOX_CONF" ]]; then
    log e "Windows version '$WIN_VERSION' not recognized (missing config: $DOXBOX_CONF)"
    log i "Supported versions are:"
    for cfg in "$dosbox_x_os_configs_dir"/*.conf; do
        base_cfg="$(basename "$cfg")"
        echo " - ${base_cfg%.conf}"
    done
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

GAME_DIR="$(dirname "$GAME_PATH")"
ORIG_GAME_EXE="$(basename "$GAME_PATH")"
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
log d "Using launcher BAT: $LAUNCHER_BAT" 
log d "D drive will mount game directory: $GAME_DIR"
log d "E drive will mount launcher directory: $LAUNCHER_DIR"
log d "Sanitized game path: $GAME_EXE"

# Create launcher BAT on host → mounted as D:
mkdir -p "$LAUNCHER_DIR"
cat <<EOF > "$LAUNCHER_BAT"
#@echo off
D:
"$GAME_EXE"
exit
EOF

cat <<EOF >> "$TMP_CONF"

[autoexec]
IMGMOUNT C "$bios_path/$WIN_VERSION.img" -t hdd
MOUNT D "$GAME_DIR"
MOUNT E "$LAUNCHER_DIR"
C:
D:
COPY E:\run_game.bat "C:\WINDOWS\STARTM~1\PROGRAMS\STARTUP\run_game.bat"
BOOT C:
EOF

log i "Launching Windows 98 and autostarting game..."
# Sanity check: ensure the launcher exists and is readable before launching.
if [[ ! -f "$LAUNCHER_BAT" ]]; then
    log e "launcher not found at '$LAUNCHER_BAT' — aborting"
    exit 2
fi

log d "Launcher BAT content:"
log d "-----------------------------------"
cat "$LAUNCHER_BAT"
log d "-----------------------------------"
log d "Launching DOSBox-X with the following config:"
log d "-----------------------------------"
cat "$TMP_CONF"
log d "-----------------------------------"

echo ""
echo ""
echo ""

# Launch DOSBox-X using the generated config
flatpak run com.dosbox_x.DOSBox-X -conf "$TMP_CONF"
