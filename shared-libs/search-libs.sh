#!/bin/bash

SEARCH_PATHS=(/app /usr/lib /usr/lib64)
mkdir -p "${FLATPAK_DEST}/lib/"

POSTFIX="${1:-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)}"
lib_list="shared-libs-${POSTFIX}.txt"

if [ ! -f "$lib_list" ]; then
    echo "[ERROR] Library list file $lib_list not found. Please provide a valid library list file."
    exit 1
fi

# De-duplicate and sort for cleaner search
mapfile -t unique_libs < <(sort -u "$lib_list")
echo "Searching for shared libraries in ${SEARCH_PATHS[*]} from \"$lib_list\"..."
echo "[DEBUG] De-duplicated library list: ${unique_libs[*]}"

need_to_debug=false
not_found_libs=()

for lib in "${unique_libs[@]}"; do
    # Exact search
    path=$(find "${SEARCH_PATHS[@]}" -type f -name "$lib" 2>/dev/null | head -n 1)
    if [ -z "$path" ]; then
        # Partial/recursive search
        path=$(find "${SEARCH_PATHS[@]}" -type f -iname "*$lib*" 2>/dev/null | head -n 1)
        [ -z "$path" ] && { echo "❌ Library not found: $lib"; not_found_libs+=("$lib"); need_to_debug=true; continue; }
    fi

    dest="${FLATPAK_DEST}/lib/$(basename "$path")"
    if [ "$path" != "$dest" ]; then
        cp -fL "$path" "${FLATPAK_DEST}/lib/" && echo "✅ Copied $lib to ${FLATPAK_DEST}/lib/ (recursive mode)"
    fi
done

echo ""

# Debug missing libraries if needed
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