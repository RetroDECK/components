#!/bin/bash

log d "RetroDECK Doom Parser booting..."

# Source the global.sh script if not already sourced
if [ -z "${GLOBAL_SOURCED+x}" ]; then
    source /app/libexec/global.sh
fi

# Define the IWAD files list
IWAD_FILES=("DOOM1.WAD" "DOOM.WAD" "DOOM2.WAD" "DOOM2F.WAD" "DOOM64.WAD" "TNT.WAD"
            "PLUTONIA.WAD" "HERETIC1.WAD" "HERETIC.WAD" "HEXEN.WAD" "HEXDD.WAD"
            "STRIFE0.WAD" "STRIFE1.WAD" "VOICES.WAD" "CHEX.WAD"
            "CHEX3.WAD" "HACX.WAD" "freedoom1.wad" "freedoom2.wad" "freedm.wad"
            "doom_complete.pk3"
)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log d "Running from script dir: $SCRIPT_DIR"

gzdoom="$SCRIPT_DIR/gzdoom"

# Function to check if a file is an IWAD
is_iwad() {
    local file="$1"
    local lowercase_file="$(basename "${file,,}")"

    # Loop through the list of IWAD files
    for iwad in "${IWAD_FILES[@]}"; do
        # Check if the lowercase version of the IWAD file matches the input file
        if [[ "${iwad,,}" == "$lowercase_file" ]]; then
            echo "true"
            return
        fi
    done
    echo "false"
}

# Function to search for files recursively and resolve symlinks
search_file_recursive() {
    local file="$1"
    local directory="$2"
    local found_file=""

    # Check if the file exists in the current directory
    if [[ -e "$directory/$file" ]]; then
        # Resolve symlinks if the file is a symlink
        found_file=$(readlink -f "$directory/$file")
    else
        # Search recursively
        local lowercase_file="$(echo "$file" | tr '[:upper:]' '[:lower:]')"
        found_file=$(find "$directory" -type f -iname "$lowercase_file" | head -n 1)
        if [[ -n "$found_file" ]]; then
            # Resolve symlinks if the file is a symlink
            found_file=$(readlink -f "$found_file")
        fi
    fi
    echo "$found_file"
}

# Main script
log d "RetroDECK GZDOOM wrapper init"

# Check non-option arguments for a filename containing a single quote
for a in "$@"; do
    case "$a" in
        +*|-) continue ;;
    esac
    if [[ "$a" == *"'"* ]]; then
        log e "Invalid filename: \"$a\" contains a single quote.\nPlease rename the file in a proper way before continuing."
        rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
            --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>\"$a\" contains a single quote.\nPlease rename the file in a proper way before continuing."
    exit 1
    fi
done

# Determine if one of the arguments is a .doom file (we might be launched with +options first)
doom_file=""
for a in "$@"; do
    # ignore option entries that start with '+' or '-'
    case "$a" in
        +*|-) continue ;;
    esac
    if [[ "${a##*.}" == "doom" ]]; then
        doom_file="$a"
        break
    fi
done

# If a .doom file wasn't found yet, try to detect any provided candidate file arg (first non-option)
target_arg=""
for a in "$@"; do
    case "$a" in
        +*|-) continue ;;
    esac
    target_arg="$a"
done

# If no target was found, fall back to $1 to preserve legacy behavior
if [[ -z "$target_arg" ]]; then
    target_arg="$1"
fi

# If the chosen target arg doesn't have the .doom extension, we take the non-doom path
log d "Selected target: '$target_arg' (doom_file='$doom_file')"

if [[ "${doom_file}" == "" && "${target_arg##*.}" != "doom" ]]; then
    # Check if the file is in the IWAD list
    if [[ $(is_iwad "$target_arg") == "true" ]]; then
        log d "iWAD found"
        command="$gzdoom -config /var/config/gzdoom/gzdoom.ini -iwad \"$target_arg\""
    else
        log d "WAD or PK3 file found"
        command="$gzdoom -config /var/config/gzdoom/gzdoom.ini -file \"$target_arg\""
    fi

    # Log the command
    log i "Loading: \"$target_arg\""
    log i "Executing command \"$command\""

    # Execute the command with double quotes
    eval "$command"

# Check if a .doom file was found in arguments
elif [[ -n "$doom_file" || "${target_arg##*.}" == "doom" ]]; then
    if [[ -z "$doom_file" ]]; then
        doom_file="$target_arg"
    fi
    log i "Found a doom file: \"$doom_file\""

    # Check if the .doom file exists
    if [[ ! -e "$doom_file" ]]; then
        log e "doom file not found in \"$doom_file\""
        rd_zenity --error --no-wrap \
	    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
	    --title "RetroDECK" \
	    --text="File \"$doom_file\" not found. Quitting."
        exit 1
    fi

    # Read the .doom file and compose the command
    command="$gzdoom -config /var/config/gzdoom/gzdoom.ini"

    while IFS= read -r line; do
        # Check if the line contains a single quote
        if [[ "$line" == *"'"* ]]; then
            log e "Invalid filename: A file contained in \"$doom_file\" contains a single quote"
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK" \
                    --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>A file contained in \"$doom_file\" contains a single quote.\nPlease rename the file and fix its name in the .doom file."
            exit 1
        fi
        found_file=$(search_file_recursive "$line" "$(dirname "$doom_file")")

        # If the file is not found, exit with an error
        if [[ -z "$found_file" ]]; then
            log "[ERROR] File not found: $line"
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK" \
                --text="File \"$line\" not found. Quitting."
            exit 1
        fi

        # Check if the file is an IWAD
        if [[ $(is_iwad "$found_file") == "true" ]]; then
            command+=" -iwad \"$found_file\""
            log i "Appending the param \"-iwad $found_file\""
        else
            command+=" -file \"$found_file\""
            log i "Appending the param \"-file $found_file\""
        fi
    done < "$doom_file"

    # Log the command
    log i "Executing command \"$command\""

    # Execute the command with double quotes
    eval "$command"
fi
