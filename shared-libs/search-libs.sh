#!/bin/bash

# Call me with an argument, for example:
# ./search-libs.sh $POSTFIX to properly name the folder
# If no argument is given, a random 4-character string will be used as postfix
# I will search for libraries listed in shared-libs-$POSTFIX.txt, so if postfix is 6.8, the file will be shared-libs-6.8.txt

SEARCH_PATHS=(/app /usr/lib /usr/lib64)
mkdir -p ${FLATPAK_DEST}/lib/
if [ -z "$1" ]; then
    POSTFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)
else
    POSTFIX="$1"
fi

echo "Searching for shared libraries in ${SEARCH_PATHS[@]}..."

while read -r lib; do
    path=$(find "${SEARCH_PATHS[@]}" -type f -name "$lib" 2>/dev/null | head -n 1)
    if [ -n "$path" ]; then
        cp -fL "$path" "${FLATPAK_DEST}/lib/" 2>/dev/null && echo "✅ Copied $lib to ${FLATPAK_DEST}/lib/"
    else
    # Try recursive search for partial matches if exact name not found
    path=$(find "${SEARCH_PATHS[@]}" -type f -iname "*$lib*" 2>/dev/null | head -n 1)
    if [ -n "$path" ]; then
        cp -fL "$path" "${FLATPAK_DEST}/lib/" 2>/dev/null && echo "✅ Copied $lib to ${FLATPAK_DEST}/lib/ (recursive mode)"
    else
        echo "❌ Library not found: $lib"
        not_found_libs+=("$lib")
        need_to_debug=true
    fi
    fi
done < shared-libs-$POSTFIX.txt
echo ""

if [ "$need_to_debug" = true ]; then
    echo "Some libraries were not found. Searching for them..."
    for not_found_lib in "${not_found_libs[@]}"; do
    echo "Searching for: \"$not_found_lib\" in ${SEARCH_PATHS[@]}"
    find "${SEARCH_PATHS[@]}" -type f -iname "*$not_found_lib*"
    if [ $? -ne 0 ] || [ -z "$(find "${SEARCH_PATHS[@]}" -type f -iname "*$not_found_lib*" 2>/dev/null | head -n 1)" ]; then
        echo "Not found in SEARCH_PATHS, searching from root / (this may take a while)..."
        find / -type f -iname "*$not_found_lib*" 2>/dev/null
    fi
    done
    echo ""
fi