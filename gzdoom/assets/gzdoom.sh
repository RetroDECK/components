#!/bin/bash

log d "RetroDECK Doom Parser booting..."

# Source the global.sh script if not already sourced
if [ -z "${GLOBAL_SOURCED+x}" ]; then
    source /app/libexec/global.sh
fi

# Define the IWAD files list
IWAD_FILES=(
        "ACTION2.WAD"       # Action Doom 2: Urban Brawl
        "BLASPHEM.WAD"      # Blasphemer
        "CHEX.WAD"          # Chex Quest
        "CHEX3.WAD"         # Chex Quest 3
        "DELAWEARE.WAD"     # Delaweare 
        "DOOM.WAD"          # Doom shareware
        "DOOM1.WAD"         # Doom 
        "DOOM2.WAD"         # Doom II: Hell on Earth
        "DOOM2F.WAD"        # Doom II French
        "DOOM64.WAD"        # Doom 64
        "DOOM_COMPLETE.PK3" # WadSmoosh merged Doom
        "FREEDOOM1.WAD"     # Freedoom Phase 1
        "FREEDOOM2.WAD"     # Freedoom Phase 2 
        "FREEDM.WAD"        # Freedoom Deathmatch
        "HEXDD.WAD"         # Hexen: Deathkings of the Dark Citadel
        "HEXEN.WAD"         # Hexen: Beyond Heretic
        "HACX.WAD"          # HACX
        "HARM1.WAD"         # Harmony
        "HERETIC.WAD"       # Heretic: Shadow of the Serpent Riders
        "HERETIC1.WAD"      # Heretic shareware
        "PLUTONIA.WAD"      # Plutonia Experiment
        "ROTWB.WAD"         # Rise Of The Wool Ball
        "SQUARE1.PK3"       # The Adventures of Square
        "STRIFE0.WAD"       # Strife shareware
        "STRIFE1.WAD"       # Strife
        "TNT.WAD"           # TNT: Evilution
        "VOICES.WAD"        # Strife Voices                                                                              
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
    # We'll try several places so this works when the DOOM folder is symlinked
    # 1) $directory/$file
    # 2) recursive find under $directory
    # 3) script-level doom dir (relative to assets) recursive

    # 0. normalize file name for case-insensitive search
    local lowercase_file="$(echo "$file" | tr '[:upper:]' '[:lower:]')"

    # Resolve directory symlinks (if the DOOM folder itself was symlinked)
    if [[ -L "$directory" ]]; then
        directory=$(readlink -f "$directory")
    fi

    # Try direct path first
    if [[ -e "$directory/$file" ]]; then
        found_file=$(readlink -f "$directory/$file")
        echo "$found_file"
        return
    fi

    # Try recursive find under provided directory (case-insensitive)
    # Use the basename for recursive search, so entries listed as "subdir/name.wad"
    # will still match files located below the given directory.
    local base="$(basename "$file")"
    # Collect all case-insensitive matches, prefer one whose basename equals requested basename exactly
    mapfile -t matches < <(find "$directory" -type f -iname "$base" 2>/dev/null || true)
    if [[ ${#matches[@]} -gt 0 ]]; then
        # First try to find a case-sensitive basename match
        found_file=""
        for m in "${matches[@]}"; do
            if [[ "$(basename "$m")" == "$base" ]]; then
                found_file="$m"
                break
            fi
        done
        # Fallback to the first match if no exact-case match found
        if [[ -z "$found_file" ]]; then
            found_file="${matches[0]}"
        fi
        found_file=$(readlink -f "$found_file")
        echo "$found_file"
        return
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
        log e "DOOM Invalid filename: \"$a\" contains a single quote.\nPlease rename the file in a proper way before continuing."
        rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK: DOOM - 🛑 Warning: Invalid Filename 🛑" \
            --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>\"$1\" contains a single quote.\nPlease rename the file properly before continuing."
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
	    --title "RetroDECK: DOOM - 🛑 Warning: File not found 🛑" \
	    --text="File \"$doom_file\" not found. Quitting."
        exit 1
    fi

    # Read the .doom file and compose the command
    command="$gzdoom -config /var/config/gzdoom/gzdoom.ini"

    while IFS= read -r line; do
        # Trim leading/trailing whitespace
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Ignore empty lines and comment lines
        if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
            continue
        fi

        # Remove surrounding quotes if present
        if [[ "$line" =~ ^\".*\"$ ]]; then
            line="${line:1:${#line}-2}"
        fi

        # Check if the line contains a single quote
        if [[ "$line" == *"'"* ]]; then
            log e "Invalid filename: A file contained in \"$doom_file\" contains a single quote"
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK: DOOM - 🛑 Warning: .doom file error 🛑" \
                --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>\"$1\" contains a single quote.\nPlease rename the file properly in the .doom file before continuing."
            exit 1
        fi

        # Search for the file recursively
        found_file=$(search_file_recursive "$line" "$(dirname "$doom_file")")

        # If the file is not found, exit with an error
        if [[ -z "$found_file" ]]; then
            log "[ERROR] File not found in \"$line\""
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK: DOOM - 🛑 Warning: Not found 🛑" \
                --text="File \"$line\" not found. Quitting."
            exit 1
        fi

        # Add param depending on file extension (.ini -> -cfg, iwads -> -iwad, others -> -file)
        ext="${found_file##*.}"
        ext_lc="${ext,,}"
        case "$ext_lc" in
            ini)
                command+=" -cfg \"$found_file\""
                log i "Appending the param \"-cfg $found_file\""
                ;;
            wad|pk3|ipk3)
                if [[ $(is_iwad "$found_file") == "true" ]]; then
                    command+=" -iwad \"$found_file\""
                    log i "Appending the param \"-iwad $found_file\""
                else
                    command+=" -file \"$found_file\""
                    log i "Appending the param \"-file $found_file\""
                fi
                ;;
            *)
                command+=" -file \"$found_file\""
                log i "Appending the param \"-file $found_file\""
                ;;
        esac
    done < "$doom_file"

    # Log the command
    log i "Executing command \"$command\""

    # Execute the command with double quotes
    eval "$command"
fi
