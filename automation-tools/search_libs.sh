#!/bin/bash

# This script searches for shared libraries in specified paths and copies them to a destination directory.
# Usage: search_libs <library_list_file>
# Example:
# ./search-libs.sh /shared-libs/retrodeck-shared-libs.6.8.txt

search_libs() {
    # Add local component paths first, then system paths
    # Use absolute paths to avoid confusion
    local component_lib_dir="$(realpath -m "${FLATPAK_DEST}/../lib" 2>/dev/null)"
    local artifacts_lib_dir="$(realpath -m "${FLATPAK_DEST}/lib")"

    # Add squashfs-root (AppImage extracted) if present
    local squashfs_root_dir="${component}/squashfs-root"
    local squashfs_lib_dir="${squashfs_root_dir}/lib"
    if [[ -d "$squashfs_root_dir" ]]; then
        SEARCH_PATHS=("$artifacts_lib_dir" "$component_lib_dir" "$squashfs_lib_dir" "$squashfs_root_dir" "$squashfs_root_dir/usr/lib" /app /usr/lib /usr/lib64)
    else
        SEARCH_PATHS=("$artifacts_lib_dir" "$component_lib_dir" /app /usr/lib /usr/lib64)
    fi
    # Exclude /run from search
    mkdir -p "${FLATPAK_DEST}/lib/"

    lib_list="$1"

    if [ ! -f "$lib_list" ]; then
        log e "Library list file $lib_list not found."
        return 1
    fi

    # Load libraries from the provided list
    log d "🔍 Searching for libraries from: \"$lib_list\"..." "$logfile"
    mapfile -t all_libs < <(grep -v '^\s*#' "$lib_list" | sort -u)

    # Load filtered patterns from filtered_libs.txt
    local filtered_libs_file="$(dirname "$0")/../filtered_libs.txt"
    local filtered_patterns=()
    if [[ -f "$filtered_libs_file" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            filtered_patterns+=("$line")
        done < "$filtered_libs_file"
    fi
    log i "📦 Loaded ${#all_libs[@]} libraries from list" "$logfile"

    need_to_debug=false
    not_found_libs=()

    for lib in "${all_libs[@]}"; do
        # Salta la ricerca se la libreria è filtrata
        local is_filtered=false
        for pattern in "${filtered_patterns[@]}"; do
            if [[ "$lib" == $pattern ]]; then
                echo "⏭️  Skipping $lib as it's filtered in filtered_libs.txt"
                is_filtered=true
                break
            fi
        done
        if [[ "$is_filtered" == true ]]; then
            continue
        fi
        # Check if library is already present in artifacts (from AppImage extraction)
        if [[ -f "${FLATPAK_DEST}/lib/$lib" ]]; then
            echo "📦 Using native library from component: $lib (skipping external copy)"
            continue
        fi
        echo "[DEBUG] Searching for $lib in paths:"
        for search_path in "${SEARCH_PATHS[@]}"; do
            echo "  - $search_path"
        done
        path=$(find "${SEARCH_PATHS[@]}" -type f -name "$lib" \
            ! -path "/run/*" \
            ! -path "/home/*" \
            ! -path "/tmp/*" 2>/dev/null | tee /tmp/search_libs_debug.log | head -n 1)
        if [ -n "$path" ]; then
            echo "[DEBUG] Found $lib at: $path"
        fi
        if [ -z "$path" ]; then
            path=$(find "${SEARCH_PATHS[@]}" -type f -iname "*$lib*" \
                ! -path "/run/*" \
                ! -path "/home/*" \
                ! -path "/tmp/*" 2>/dev/null | tee -a /tmp/search_libs_debug.log | head -n 1)
            if [ -n "$path" ]; then
                echo "[DEBUG] Found $lib (variant) at: $path"
            fi
            if [ -z "$path" ]; then
                # Special handling: if libopenh264.so.7 is requested, create symlink from .2.5.1 if available
                if [ "$lib" == "libopenh264.so.7" ] && [ -f "${FLATPAK_DEST}/lib/libopenh264.so.2.5.1" ]; then
                    give_libopenh264_warning=true
                    continue
                fi
                echo "❌ Library not found: $lib"
                not_found_libs+=("$lib")
                need_to_debug=true
                continue
            fi
        fi
        dest="${FLATPAK_DEST}/lib/$(basename "$path")"
        if [ "$path" != "$dest" ]; then
            cp -fL "$path" "${FLATPAK_DEST}/lib/"
            # Set executable permissions for shared libraries
            chmod +x "${FLATPAK_DEST}/lib/$(basename "$path")"
            actual_name="$(basename "$path")"
            echo "✅ Copied $lib to ${FLATPAK_DEST}/lib/$actual_name (with executable permissions)"
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

    # Copy all Qt plugins from the runtime
    qt_plugin_root="/usr/lib/plugins"
    qt_plugin_dest="${FLATPAK_DEST}/usr/lib/plugins"

    if [ -d "$qt_plugin_root" ]; then
        echo "🔁 Copying all Qt plugins from $qt_plugin_root to $qt_plugin_dest"
        mkdir -p "$qt_plugin_dest"
        cp -r "$qt_plugin_root/"* "$qt_plugin_dest/"
        echo "✅ Qt plugins copied to $qt_plugin_dest"
    else
        echo "❌ Qt plugin directory not found: $qt_plugin_root"
    fi

    if [ "$give_libopenh264_warning" = true ]; then
        echo "⚠️  Warning: You included libopenh264.so.2.5.1, but you also requested libopenh264.so.7."
        echo "You may need to create a symlink manually if the application requires it."
        echo "We do this because libopenh264.so.7 is usually just a symlink to libopenh264.so.2.5.1 and not a separate library."
        echo "LibMan is already instructed to create this symlink, so it should be fine."
        echo ""
    fi
}
