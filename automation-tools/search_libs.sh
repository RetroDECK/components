#!/bin/bash

# This script searches for shared libraries in specified paths and copies them to a destination directory.
# Usage: search_libs <library_list_file>
# Ensure the script is run with a library list file as an argument
# Example:
# ./search-libs.sh /shared-libs/retrodeck-shared-libs.6.8.txt

search_libs() {
    SEARCH_PATHS=(/app /usr/lib /usr/lib64)
    mkdir -p "${FLATPAK_DEST}/lib/"

    lib_list="$1"

    if [ ! -f "$lib_list" ]; then
        echo "[ERROR] Library list file $lib_list not found. Please provide a valid library list file."
        return 1
    fi

    mapfile -t unique_libs < <(grep -v '^\s*#' "$lib_list" | sort -u)
    echo "Searching for shared libraries in ${SEARCH_PATHS[*]} from \"$lib_list\"..."
    echo "[DEBUG] De-duplicated library list: ${unique_libs[*]}"

    need_to_debug=false
    not_found_libs=()

    for lib in "${unique_libs[@]}"; do
        path=$(find "${SEARCH_PATHS[@]}" -type f -name "$lib" 2>/dev/null | head -n 1)
        if [ -z "$path" ]; then
            path=$(find "${SEARCH_PATHS[@]}" -type f -iname "*$lib*" 2>/dev/null | head -n 1)
            [ -z "$path" ] && { echo "❌ Library not found: $lib"; not_found_libs+=("$lib"); need_to_debug=true; continue; }
        fi

        dest="${FLATPAK_DEST}/lib/$(basename "$path")"
        if [ "$path" != "$dest" ]; then
            cp -fL "$path" "${FLATPAK_DEST}/lib/"
            actual_name="$(basename "$path")"
            echo "✅ Copied $lib to ${FLATPAK_DEST}/lib/$actual_name"
        fi
    done

    echo ""

    if [ "$need_to_debug" = true ]; then
        echo "Some libraries were not found. Searching for them..."

        for not_found_lib in "${not_found_libs[@]}"; do
            echo "Searching for: \"$not_found_lib\" in ${SEARCH_PATHS[*]}"
            result=$(find "${SEARCH_PATHS[@]}" -type f -iname "*$not_found_lib*" 2>/dev/null | head -n 10)
            if [ -n "$result" ]; then
                echo "Found (in SEARCH_PATHS):"
                echo "$result"
            else
                echo "Not found in SEARCH_PATHS, searching from root / (this may take a while)..."
                find / -type f -iname "*$not_found_lib*" 2>/dev/null | head -n 10
            fi
            echo ""
        done
    fi
}
