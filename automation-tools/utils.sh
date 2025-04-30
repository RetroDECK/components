#!/bin/bash

FORCE=0                 # Force the download even if the version is the same, useful for local retention, enabled by default on CI/CD to avoid missing updates since the version files are present bu the artifacts are not
DRY_RUN=0
FINALIZE_PATH=""
FINALIZE_VERSION=""
FINALIZE_COMPONENT=""
SPLIT="false"           # When this is enalbed it will split the archive into multiple parts if it is larger than 95MB

parse_flags() {
    while [[ "$1" =~ ^-- ]]; do
        case "$1" in
            --force)
                FORCE=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
    # Return the remaining non-flag arguments
    echo "$@"
}

#!/bin/bash

FORCE=0
DRY_RUN=0

parse_flags() {
    while [[ "$1" =~ ^-- ]]; do
        case "$1" in
            --force)
                FORCE=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
    echo "$@"
}

grab() {
    local args
    args=($(parse_flags "$@"))
    local type="${args[0]}"
    local url="${args[1]}"
    local component="${args[2]:-$(basename "$(dirname "$(realpath "${BASH_SOURCE[1]}")")")}"
    local version=""
    local output_path=""
    local output=""

    echo ""
    echo "-----------------------------------------------------------"
    echo "   PREPARING ARTIFACTS FOR COMPONENT: $component"
    echo "-----------------------------------------------------------"

    echo "Grabbing type '$type' from URL: $url"
    mkdir -p "$component/artifacts"

    # Early return for flatpak_id type (no download)
    if [[ "$type" == "flatpak_id" ]]; then
        echo "[INFO] Type flatpak_id detected, skipping download."
        manage_flatpak_id "$component" "$url"
        return
    fi

    # --- Resolve Wildcards First ---
    case "$url" in
        *github.com*'*'*)
            echo "[INFO] GitHub wildcard URL detected, resolving via GitHub API..."

            repo=$(echo "$url" | sed -E 's|https://github.com/([^/]+/[^/]+).*|\1|')
            pattern=$(basename "$url")
            pattern_regex="${pattern//\*/.*}"

            releases=$(curl -s "https://api.github.com/repos/$repo/releases")

            if ! echo "$releases" | jq empty > /dev/null 2>&1; then
                echo "[ERROR] Invalid JSON from GitHub API."
                exit 1
            fi

            if echo "$releases" | grep -q "API rate limit exceeded"; then
                echo "[ERROR] GitHub API rate limit exceeded."
                exit 1
            fi

            asset_url=$(echo "$releases" | jq -r --arg pattern "$pattern_regex" '
                .[] | .assets[]? | select(.name | test($pattern)) | .browser_download_url
            ' | head -n 1)

            if [[ -z "$asset_url" ]]; then
                echo "[ERROR] No matching asset found for pattern: $pattern"
                exit 1
            fi

            url="$asset_url"
            echo "[INFO] Resolved URL: $url"
            ;;

        *buildbot.libretro.com*'*'*)
            echo "[INFO] Buildbot wildcard URL detected, resolving latest folder..."

            base_url="${url%%\**}"
            tail_path="${url#*\*}"

            folder=$(curl -s "$base_url" | grep -oP '<a href="/stable/\K[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)

            if [[ -n "$folder" ]]; then
                url="${base_url}${folder}/${tail_path}"
                version="$folder"
                echo "[INFO] Resolved URL: $url"
            else
                echo "[ERROR] No version folders found at $base_url."
                exit 1
            fi
            ;;
    esac

    # --- Determine Output Path ---
    if [[ "$url" =~ ^(http|https|ftp|ftps|sftp|ssh):// ]]; then
        filename=$(basename "$url")
        if [[ "$filename" =~ \.tar\.(gz|bz2|xz)$ ]]; then
            file_extension="tar.${BASH_REMATCH[1]}"
        else
            file_extension="${filename##*.}"
        fi
        output_path="$component/artifacts/$component.$file_extension"

        if [[ ! -f "$output_path" ]]; then
            echo "[INFO] Downloading $url -> $output_path"
            wget -qc "$url" -O "$output_path" || { echo "[ERROR] Failed to download $url"; exit 1; }

            if [[ ! -s "$output_path" ]]; then
                echo "[ERROR] Downloaded file is empty. Something went wrong."
                exit 1
            fi

            if file "$output_path" | grep -q "HTML"; then
                echo "[ERROR] Downloaded file is HTML. Probably a 404 page."
                cat "$output_path" | head -n 20
                exit 1
            fi
        else
            echo "[INFO] Using already downloaded $output_path"
        fi
    else
        echo "[INFO] Using local file: $url"
        output_path="$url"
    fi

    version=$(version_check "link" "$component" "$url")
    output=$(manage_appimage "$component" "$output_path" "$version" 2>/dev/null | tail -n 1)

    if [[ -z "$output" ]]; then
        echo "[ERROR] manage_appimage returned empty output!"
        exit 1
    fi

    if [[ "$output" == "skip" ]]; then
        echo "[INFO] Skipping $component, already up-to-date."
        return
    fi

    FINALIZE_PATH=$(echo "$output" | cut -d'|' -f1)
    FINALIZE_VERSION=$(echo "$output" | cut -d'|' -f2)
    FINALIZE_COMPONENT="$component"

    if [[ ! -e "$FINALIZE_PATH" ]]; then
        echo "[DEBUG] FINALIZE_PATH=$FINALIZE_PATH"
        [[ -e "$FINALIZE_PATH" ]] && echo "[DEBUG] Finalize path exists." || echo "[DEBUG] Finalize path does NOT exist!"
        ls -lah "$(dirname "$FINALIZE_PATH")"
        exit 1
    fi

}

manage_appimage() {
    local component="$1"
    local file_path="$2"
    local version="$3"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage appimage for $component from $file_path"
        return
    fi

    echo "Managing appimage for component: $component from $file_path"

    local final_appimage="$component/artifacts/$component.AppImage"

    finalize_appimage_file() {
        local source="$1"
        echo "[INFO] Finalizing AppImage..."
        mv "$source" "$final_appimage"
        chmod +x "$final_appimage"
        echo "[INFO] AppImage moved to: $final_appimage"
        echo "$final_appimage|$version"
    }

    if [[ "$file_path" =~ \.tar\.(gz|xz|bz2)$ || "$file_path" =~ \.7z$ ]]; then
        echo "Extracting archive..."
        local tempdir
        tempdir=$(mktemp -d)

        if [[ "$file_path" =~ \.7z$ ]]; then
            7z x -y "$file_path" -o"$tempdir" > /dev/null || { echo "[ERROR] Failed to extract 7z archive"; exit 1; }
        else
            tar -xf "$file_path" -C "$tempdir" || { echo "[ERROR] Failed to extract tar archive"; exit 1; }
        fi

        appimage_path=$(find "$tempdir" -type f -name '*.AppImage' | head -n 1)

        if [[ -n "$appimage_path" ]]; then
            echo "Found AppImage: $(basename "$appimage_path")"
            output=$(finalize_appimage_file "$appimage_path")
        else
            echo "[ERROR] No AppImage found in extracted archive!"
            rm -rf "$tempdir"
            exit 1
        fi

        rm -rf "$tempdir"

    elif [[ "$file_path" =~ \.AppImage$ ]]; then
        echo "Direct AppImage detected."

        if [[ "$file_path" == "$final_appimage" ]]; then
             if [[ ! -f "$file_path" ]]; then
                 echo "[ERROR] Expected file $file_path does not exist."
                 exit 1
             fi
             echo "[INFO] File already exists at destination."
        else
             cp "$file_path" "$final_appimage" || { echo "[ERROR] Failed to copy AppImage"; exit 1; }
        fi

        chmod +x "$final_appimage"
        output="$final_appimage|$version"
    else
        echo "[ERROR] Unsupported appimage file format: $file_path"
        exit 1
    fi

    echo "AppImage management completed"
    echo "$output"
}

manage_flatpak() {

    # TODO: make me quicker by comparing the current hash with the one provided in the release artifacts

    local component="$1"
    local url="$2"
    local version="$3"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage $type for $component from $url"
        return
    fi

    echo "Managing flatpak for component: $component from URL: $url"

    local filename=$(basename "$url")
    if [[ "$filename" =~ \.tar\.(gz|bz2|xz)$ ]]; then
        file_extension="tar.${BASH_REMATCH[1]}"
    else
        file_extension="${filename##*.}"
    fi

    local output_path="$component/artifacts/$component.$file_extension"
    wget -qc "$url" -O "$output_path"
    if [ ! -f "$output_path" ]; then
        echo "[ERROR] Failed to download flatpak from $url"
        return 1
    else
        echo "Flatpak grabbed successfully: \"$output_path\""
    fi

    # return the artifacts path and version
    echo "$output_path|$version"
}

manage_generic() {
    local component="$1"
    local file_path="$2"
    local version="$3"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage generic artifact for $component from $file_path"
        return
    fi

    echo "Managing generic artifact for component: $component from $file_path"

    if [[ ! -f "$file_path" ]]; then
        echo "[ERROR] Generic artifact not found: $file_path"
        exit 1
    fi

    # return the artifacts path and version
    echo "$file_path|$version"
}

# This function not compiling the flatpak, just downloading it and extracting it (+ runtimes and sdk)
manage_flatpak_id() {
    local component="$1"
    local flatpak_id="$2"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage flatpak for $flatpak_id"
        return 0
    fi

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

    local was_installed="true"
    if ! flatpak info --user "$flatpak_id" > /dev/null 2>&1; then
        echo "[INFO] Flatpak $flatpak_id is not installed. Proceeding with installation."
        was_installed="false"
    fi

    flatpak install --user -y --or-update flathub "$flatpak_id"

    local app_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/files"
    local metainfo_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/export/share/metainfo/$flatpak_id.metainfo.xml"

    if [[ ! -f "$metainfo_path" ]]; then
        echo "[ERROR] Metainfo file not found at \"$metainfo_path\"."
        ls -lah "$(dirname "$metainfo_path")"
        exit 1
    fi

    if [[ ! -d "$app_path" ]]; then
        echo "[ERROR] App path not found: \"$app_path\"."
        ls -lah "$(dirname "$app_path")"
        exit 1
    fi

    local extracted_version
    extracted_version=$(version_check "metainfo" "$component" "$metainfo_path")

    if [[ $? -eq 0 ]]; then
        echo "[INFO] Skipping $flatpak_id because version is already up-to-date."
        echo "skip" > result.txt
        [[ "$was_installed" == "false" ]] && flatpak uninstall --user -y "$flatpak_id" || true
        exit 0
    fi

    mkdir -p "$component/artifacts/.tmp"
    echo "[INFO] Copying application files..."
    cp -r "$app_path"/* "$component/artifacts/.tmp/"

    echo "[INFO] Finding required runtimes for $flatpak_id..."
    local runtimes
    runtimes=$(flatpak info --user "$flatpak_id" | awk '/Runtime:/ {print $2} /Sdk:/ {print $2}')
    echo -e "[INFO] Found runtimes:\n$runtimes"

    for runtime_id in $runtimes; do
        echo "[INFO] Including runtime: $runtime_id"

        local runtime_name=$(echo "$runtime_id" | cut -d'/' -f1)
        local runtime_arch=$(echo "$runtime_id" | cut -d'/' -f2)
        local runtime_branch=$(echo "$runtime_id" | cut -d'/' -f3)

        local runtime_path="$HOME/.local/share/flatpak/runtime/$runtime_name/$runtime_arch/$runtime_branch/active/files"

        if [[ -d "$runtime_path" ]]; then
            echo "[INFO] Copying runtime files for $runtime_id..."
            mkdir -p "$component/artifacts/.tmp/runtimes/$runtime_id"
            cp -r "$runtime_path"/* "$component/artifacts/.tmp/runtimes/$runtime_id/" || { echo "[ERROR] Copy failed"; exit 1; }
        else
            echo "[WARNING] Runtime path $runtime_path not found, skipping."
        fi
    done

    # ✅ Imposta le variabili globali per finalize()
    FINALIZE_COMPONENT="$component"
    FINALIZE_PATH="$component/artifacts/.tmp"
    FINALIZE_VERSION="$extracted_version"

    echo "[INFO] Finalizing artifact..."

    # cleanup dopo finalize
    if [[ "$was_installed" == "false" ]]; then
        echo "[INFO] Uninstalling $flatpak_id as it was not previously installed."
        flatpak uninstall --user -y "$flatpak_id" || echo "[WARNING] Failed to uninstall $flatpak_id"
    fi
}

finalize() {
    if [[ -z "$FINALIZE_COMPONENT" || -z "$FINALIZE_PATH" || -z "$FINALIZE_VERSION" ]]; then
        echo "[ERROR] finalize() called without a valid grab step."
        return 1
    fi

    finalize_artifact "$FINALIZE_COMPONENT" "$FINALIZE_PATH" "$FINALIZE_VERSION"
}

finalize_artifact() {
    local component="$1"
    local source_path="$2"
    local version="$3"
    local max_size_mb=95

    local artifact_dir="$component/artifacts"
    mkdir -p "$artifact_dir"

    local artifact_base="$artifact_dir/$component"
    local temp_tar="$artifact_base.tar.gz"
    local tmpzip_dir="$artifact_dir/.tmpzip"

    if [[ -f "$source_path" ]]; then
        echo "[INFO] Source is a file, checking size..."

        local artifact_size_mb=$(( $(stat -c%s "$source_path") / 1024 / 1024 ))

        if [[ "$artifact_size_mb" -gt "$max_size_mb" && "$SPLIT" == "true" ]]; then
            echo "[INFO] File larger than ${max_size_mb}MB, preparing split ZIP archive."

            echo "[INFO] Preparing temporary directory for zipping..."
            rm -rf "$tmpzip_dir"
            mkdir -p "$tmpzip_dir"

            if [[ "$source_path" =~ \.tar\.(gz|bz2|xz)$ ]]; then
                echo "[INFO] Extracting TAR archive before zipping..."
                tar -xf "$source_path" -C "$tmpzip_dir" || { echo "[ERROR] Failed to extract tar archive."; exit 1; }
            elif [[ "$source_path" =~ \.zip$ ]]; then
                echo "[INFO] Extracting ZIP archive before re-zipping..."
                unzip -q "$source_path" -d "$tmpzip_dir" || { echo "[ERROR] Failed to extract zip archive."; exit 1; }
            else
                echo "[INFO] Copying file to temporary zipping folder..."
                cp "$source_path" "$tmpzip_dir/" || { echo "[ERROR] Failed to copy file."; exit 1; }
            fi

            echo "[INFO] Creating split ZIP archive..."
            (cd "$artifact_dir" && zip -r -s ${max_size_mb}m "${component}.zip" ".tmpzip") || { echo "[ERROR] Failed to create split zip archive."; exit 1; }

            echo "[INFO] Cleaning temporary zipping folder..."
            rm -rf "$tmpzip_dir"

            echo "[INFO] Moving split archive parts..."
            for part in "$artifact_dir"/${component}.zip "$artifact_dir"/${component}.z*; do
                [ -e "$part" ] || continue
                hash=($(sha256sum "$part"))
                echo "$hash" > "$artifact_dir/$(basename "$part").sha"
            done

        else
            echo "[INFO] File size is within limit or splitting is disabled, copying directly."
            cp "$source_path" "$artifact_base" || { echo "[ERROR] Failed to copy artifact file."; exit 1; }

            hash=($(sha256sum "$artifact_base"))
            echo "$hash" > "$artifact_dir/$(basename "$artifact_base").sha"
        fi

    elif [[ -d "$source_path" ]]; then
        echo "[INFO] Source is a directory, creating tar.gz to check size..."
        tar -czf "$temp_tar" -C "$source_path" . || { echo "[ERROR] Failed to create tar.gz archive."; exit 1; }

        local artifact_size_mb=$(( $(stat -c%s "$temp_tar") / 1024 / 1024 ))

        if [[ "$artifact_size_mb" -gt "$max_size_mb" ]]; then
            echo "[INFO] Archive larger than ${max_size_mb}MB, preparing split ZIP archive."

            rm -f "$temp_tar"

            echo "[INFO] Preparing temporary directory for zipping..."
            rm -rf "$tmpzip_dir"
            cp -r "$source_path" "$tmpzip_dir" || { echo "[ERROR] Failed to copy directory."; exit 1; }

            echo "[INFO] Creating split ZIP archive..."
            (cd "$artifact_dir" && zip -r -s ${max_size_mb}m "${component}.zip" ".tmpzip") || { echo "[ERROR] Failed to create split zip archive."; exit 1; }

            echo "[INFO] Cleaning temporary zipping folder..."
            rm -rf "$tmpzip_dir"

            echo "[INFO] Moving split archive parts..."
            for part in "$artifact_dir"/${component}.zip "$artifact_dir"/${component}.z*; do
                [ -e "$part" ] || continue
                hash=($(sha256sum "$part"))
                echo "$hash" > "$artifact_dir/$(basename "$part").sha"
            done

        else
            echo "[INFO] Archive size is within limit, keeping tar.gz."
            hash=($(sha256sum "$temp_tar"))
            echo "$hash" > "$artifact_dir/$(basename "$temp_tar").sha"
        fi

    else
        echo "[ERROR] Source path is neither a file nor a directory."
        exit 1
    fi

    if [[ -n "$version" ]]; then
        echo "$version" > "$artifact_dir/version"
    fi
}

write_components_version() {
    # Create or overwrite the components_version.md file
    local output_file="components_version.md"
    echo "# Components Version Summary" > "$output_file"
    echo "" >> "$output_file"

    # Loop through all */*/artifacts/version files
    for version_file in */*/artifacts/version; do
        if [[ -f "$version_file" ]]; then
            local component_name=$(basename "$(dirname "$(dirname "$version_file")")")
            local version=$(cat "$version_file")
            local update_date=$(date -r "$version_file" +"%Y-%m-%d %H:%M:%S")
            
            echo "## $component_name" >> "$output_file"
            echo "- Version: $version" >> "$output_file"
            echo "- Last Updated: $update_date" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done
}

version_check() {
    local check_type="$1"
    local component="$2"
    local source="$3"

    local version=""
    local current_version=""
    local version_file="$component/version"

    # 1. If the source is already a version (for manual or wildcard type), use it directly
    if [[ "$check_type" == "manual" || "$check_type" == "link" || "$check_type" == "file" ]]; then
        if [[ "$source" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            version="$source"
        fi
    fi

    # 2. If it is a URL, extract from the file name
    if [[ -z "$version" && "$source" =~ ^https?:// ]]; then
        version=$(basename "$source" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
    fi

    # 3. Metainfo extraction (only for flatpak/metainfo)
    if [[ -z "$version" && "$check_type" == "metainfo" ]]; then
        local tempdir=""
        local metainfo_file=""

        if [[ -f "$source" ]]; then
            tempdir=$(mktemp -d)

            if [[ "$source" =~ \.tar\.(gz|bz2|xz)$ ]]; then
                tar -xf "$source" -C "$tempdir" || { echo "[ERROR] Failed to extract archive."; rm -rf "$tempdir"; exit 1; }
            elif [[ "$source" =~ \.zip$ ]]; then
                unzip -q "$source" -d "$tempdir" || { echo "[ERROR] Failed to extract archive."; rm -rf "$tempdir"; exit 1; }
            else
                echo "[ERROR] Unsupported archive format for metainfo extraction." >&2
                rm -rf "$tempdir"
                exit 1
            fi

            metainfo_file=$(find "$tempdir" -type f -name "*.metainfo.xml" | head -n 1)
        elif [[ -d "$source" ]]; then
            metainfo_file=$(find "$source" -type f -name "*.metainfo.xml" | head -n 1)
        fi

        if [[ -n "$metainfo_file" ]]; then
            version=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$metainfo_file" 2>/dev/null | head -n 1)
        fi

        [[ -n "$tempdir" ]] && rm -rf "$tempdir"
    fi

    if [[ -z "$version" ]]; then
        echo "[ERROR] Could not determine version for $component (source: \"$source\")" >&2
        exit 1
    fi

    echo "[INFO] Detected version: $version"

    # Compare with the current version (if it exists)
    if [[ -f "$version_file" ]]; then
        current_version=$(cat "$version_file")
        if [[ "$current_version" == "$version" && "${FORCE:-0}" -ne 1 ]]; then
            return 0  # skip
        fi
    fi

    echo "$version" > "$version_file"
    echo "$version"  # output the version
    return 1  # do not skip
}
