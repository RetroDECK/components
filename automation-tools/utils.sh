#!/bin/bash

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

export logfile="$(realpath grab.log)"

if [[ -f ".tmpfunc/logger.sh" ]]; then
    source ".tmpfunc/logger.sh"
else
    # Fallback logger function if logger.sh is not available

    log() {
        echo "[$1] $2" >&2
        echo "[$1] $2" >> "$logfile"
    }

    log e "Logger script not found. Please ensure .tmpfunc/logger.sh exists." >&2
fi
export logging_level="debug"

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

    echo ""
    echo "-----------------------------------------------------------"
    echo "   PREPARING ARTIFACTS FOR COMPONENT: $component"
    echo "-----------------------------------------------------------"

    log i "Grabbing type '$type' from URL: $url" "$logfile"
    mkdir -p "$component/artifacts"

    case "$type" in
        flatpak_id)
            log i "Type flatpak_id detected, skipping download." "$logfile"
            manage_flatpak_id "$component" "$url"
            return
            ;;
        flatpak_artifacts)
            log i "Type flatpak_artifacts detected, handling flatpak artifacts from URL: $url" "$logfile"
            manage_flatpak_artifacts "$component" "$url" "$version"
            FINALIZE_PATH="$MANAGED_OUTPUT_PATH"
            FINALIZE_VERSION="$MANAGED_OUTPUT_VERSION"
            FINALIZE_COMPONENT="$component"
            return
            ;;
    esac

    # --- Resolve Wildcards First ---
    log i "Resolving wildcards in URL..." "$logfile"

    case "$url" in
        *github.com*'*'*)
            log i "GitHub wildcard URL detected, resolving via GitHub API..." "$logfile"

            repo=$(echo "$url" | sed -E 's|https://github.com/([^/]+/[^/]+).*|\1|')
            pattern=$(basename "$url")
            pattern_regex="${pattern//\*/.*}"

            releases=$(curl -s "https://api.github.com/repos/$repo/releases")

            if ! echo "$releases" | jq empty > /dev/null 2>&1; then
                log e "Invalid JSON from GitHub API." "$logfile"
                exit 1
            fi

            if echo "$releases" | grep -q "API rate limit exceeded"; then
                log e "GitHub API rate limit exceeded." "$logfile"
                exit 1
            fi

            asset_url=$(echo "$releases" | jq -r --arg pattern "$pattern_regex" '
                .[] | .assets[]? | select(.name | test($pattern)) | .browser_download_url
            ' | head -n 1)

            if [[ -z "$asset_url" ]]; then
                log e "No matching asset found for pattern: $pattern" "$logfile"
                exit 1
            fi

            url="$asset_url"
            log i "Resolved URL: $url" "$logfile"
            ;;

        *buildbot.libretro.com*'*'*)
            log i "Buildbot wildcard URL detected, resolving latest folder..." "$logfile"

            base_url="${url%%\**}"
            tail_path="${url#*\*}"

            folder=$(curl -s "$base_url" | grep -oP '<a href="/stable/\K[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)

            if [[ -n "$folder" ]]; then
                url="${base_url}${folder}/${tail_path}"
                version="$folder"
                log i "Resolved URL: $url" "$logfile"
            else
                log e "No version folders found at $base_url." "$logfile"
                exit 1
            fi
            ;;
    esac

    # --- Determine Output Path ---
    log i "Determining output path..." "$logfile"

    if [[ "$url" =~ ^(http|https|ftp|ftps|sftp|ssh):// ]]; then
        filename=$(basename "$url")
        if [[ "$filename" =~ \.tar\.(gz|bz2|xz)$ ]]; then
            file_extension="tar.${BASH_REMATCH[1]}"
        else
            file_extension="${filename##*.}"
        fi
        output_path="$component/artifacts/$component.$file_extension"

        if [[ ! -f "$output_path" ]]; then
            log i "Downloading $url -> $output_path" "$logfile"
            wget -qc "$url" -O "$output_path" || { log e "Failed to download $url" "$logfile"; exit 1; }

            if [[ ! -s "$output_path" ]]; then
                log e "Downloaded file is empty. Something went wrong." "$logfile"
                exit 1
            fi

            if file "$output_path" | grep -q "HTML"; then
                log e "Downloaded file is HTML. Probably a 404 page." "$logfile"
                head -n 20 "$output_path"
                exit 1
            fi
        else
            log i "Using already downloaded $output_path" "$logfile"
        fi
    else
        log i "Using local file: $url" "$logfile"
        output_path="$url"
    fi

    log i "Output path: $output_path" "$logfile"

    log i "Checking version..." "$logfile"
    version=$(version_check "link" "$component" "$url")

    log d "Evaluating type: $type" "$logfile"

    # Reset globals
    MANAGED_OUTPUT_PATH=""
    MANAGED_OUTPUT_VERSION=""

    case "$type" in
        appimage)
            manage_appimage "$component" "$output_path" "$version"
            ;;
        generic)
            manage_generic "$component" "$output_path" "$version"
            ;;
        *)
            log e "Unsupported type for automatic management: $type" "$logfile"
            exit 1
            ;;
    esac

    if [[ -z "$MANAGED_OUTPUT_PATH" ]]; then
        log e "manage_${type} did not set output!" "$logfile"
        exit 1
    fi

    if [[ "$MANAGED_OUTPUT_PATH" == "skip" ]]; then
        log i "Skipping $component, already up-to-date." "$logfile"
        return
    fi

    FINALIZE_PATH="$MANAGED_OUTPUT_PATH"
    FINALIZE_VERSION="$MANAGED_OUTPUT_VERSION"
    FINALIZE_COMPONENT="$component"

    if [[ ! -e "$FINALIZE_PATH" ]]; then
        log d "FINALIZE_PATH=$FINALIZE_PATH" "$logfile"
        [[ -e "$FINALIZE_PATH" ]] && log d "Finalize path exists." "$logfile" || log d "Finalize path does NOT exist!" "$logfile"
        ls -lah "$(dirname "$FINALIZE_PATH")"
        exit 1
    fi
}

manage_appimage() {
    log d "Starting manage_appimage function" "$logfile"

    local component="$1"
    local file_path="$2"
    local version="$3"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage appimage for $component from $file_path"
        return 0
    fi

    log i "Managing AppImage for component: $component" "$logfile"

    local temp_root
    temp_root=$(mktemp -d)
    local extracted_dir="$component/artifacts/.tmp_extracted"

    rm -rf "$extracted_dir"
    mkdir -p "$extracted_dir"

    local appimage_path=""

    # Handle archives
    if [[ "$file_path" =~ \.tar\.(gz|xz|bz2)$ || "$file_path" =~ \.7z$ ]]; then
        log i "Extracting archive to temp..." "$logfile"
        if [[ "$file_path" =~ \.7z$ ]]; then
            7z x -y "$file_path" -o"$temp_root" > /dev/null || { log e "Failed to extract 7z archive" "$logfile"; rm -rf "$temp_root"; return 1; }
        else
            tar -xf "$file_path" -C "$temp_root" || { log e "Failed to extract tar archive" "$logfile"; rm -rf "$temp_root"; return 1; }
        fi

        appimage_path=$(find "$temp_root" -type f -name '*.AppImage' | head -n 1)
        [[ -z "$appimage_path" ]] && { log e "No AppImage found in archive." "$logfile"; rm -rf "$temp_root"; return 1; }

    elif [[ "$file_path" =~ \.AppImage$ ]]; then
        appimage_path="$file_path"
        [[ ! -f "$appimage_path" ]] && { log e "AppImage file not found: $appimage_path" "$logfile"; return 1; }
    else
        log e "Unsupported file type for AppImage: $file_path" "$logfile"
        return 1
    fi

    local abs_appimage_path=$(realpath "$appimage_path")

    chmod +x "$appimage_path"

    log d "Running AppImage extraction command..." "$logfile"
    cd "$extracted_dir"
    log d "$(pwd)" "$logfile"
    "$abs_appimage_path" --appimage-extract
    cd - > /dev/null
    extract_status=$?

    if [[ $extract_status -ne 0 ]]; then
        log e "AppImage extraction failed with status $extract_status." "$logfile"
        rm -rf "$temp_root"
        return 1
    fi

    log i "Compressing extracted AppImage contents..." "$logfile"
    local output_appimage_artifact="$component/artifacts/$component.tar.gz"
    tar -czf "$output_appimage_artifact" -C "$extracted_dir/squashfs-root" . 

    rm -rf "$temp_root" "$extracted_dir" "$abs_appimage_path"
    log i "AppImage repacked successfully to: $output_appimage_artifact" "$logfile"

    # Final return
    MANAGED_OUTPUT_PATH="$output_appimage_artifact"
    MANAGED_OUTPUT_VERSION="$version"

}

manage_flatpak() {

    log d "Starting manage_flatpak function" "$logfile"

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
        log e "Failed to download flatpak from $url" "$logfile"
        return 1
    else
        echo "Flatpak grabbed successfully: \"$output_path\""
    fi

    # return the artifacts path and version
    echo "$output_path|$version"
}

manage_generic() {

    log d "Starting manage_generic function" "$logfile"

    local component="$1"
    local file_path="$2"
    local version="$3"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage generic artifact for $component from $file_path"
        return
    fi

    echo "Managing generic artifact for component: $component from $file_path"

    if [[ ! -f "$file_path" ]]; then
        log e "Generic artifact not found: $file_path" "$logfile"
        exit 1
    fi

    # return the artifacts path and version
    MANAGED_OUTPUT_PATH="$file_path"
    MANAGED_OUTPUT_VERSION="$version"

}

# This function not compiling the flatpak, just downloading it and extracting it (+ runtimes and sdk)
manage_flatpak_id() {

    log d "Starting manage_flatpak_id function" "$logfile"

    local component="$1"
    local flatpak_id="$2"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] Would manage flatpak for $flatpak_id"
        return 0
    fi

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

    local was_installed="true"
    if ! flatpak info --user "$flatpak_id" > /dev/null 2>&1; then
        log i "Flatpak $flatpak_id is not installed. Proceeding with installation." "$logfile"
        was_installed="false"
    fi

    flatpak install --user -y --or-update flathub "$flatpak_id"

    local app_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/files"
    local metainfo_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/export/share/metainfo/$flatpak_id.metainfo.xml"

    if [[ ! -f "$metainfo_path" ]]; then
        log e "Metainfo file not found at \"$metainfo_path\"." "$logfile"
        ls -lah "$(dirname "$metainfo_path")"
        exit 1
    fi

    if [[ ! -d "$app_path" ]]; then
        log e "App path not found: \"$app_path\"." "$logfile"
        ls -lah "$(dirname "$app_path")"
        exit 1
    fi

    local extracted_version
    extracted_version=$(version_check "metainfo" "$component" "$metainfo_path")

    if [[ $? -eq 0 ]]; then
        log i "Skipping $flatpak_id because version is already up-to-date." "$logfile"
        [[ "$was_installed" == "false" ]] && flatpak uninstall --user -y "$flatpak_id" || true
        exit 0
    fi

    mkdir -p "$component/artifacts/.tmp"
    log i "Copying application files..." "$logfile"
    cp -r "$app_path"/* "$component/artifacts/.tmp/"

    log i "Finding required runtimes for $flatpak_id..." "$logfile"
    local runtimes
    runtimes=$(flatpak info --user "$flatpak_id" | awk '/Runtime:/ {print $2} /Sdk:/ {print $2}')
    echo -e "[INFO] Found runtimes:\n$runtimes"

    for runtime_id in $runtimes; do
        log i "Including runtime: $runtime_id" "$logfile"

        local runtime_name=$(echo "$runtime_id" | cut -d'/' -f1)
        local runtime_arch=$(echo "$runtime_id" | cut -d'/' -f2)
        local runtime_branch=$(echo "$runtime_id" | cut -d'/' -f3)

        local runtime_path="$HOME/.local/share/flatpak/runtime/$runtime_name/$runtime_arch/$runtime_branch/active/files"

        if [[ -d "$runtime_path" ]]; then
            log i "Copying runtime files for $runtime_id..." "$logfile"
            mkdir -p "$component/artifacts/.tmp/runtimes/$runtime_id"
            cp -r "$runtime_path"/* "$component/artifacts/.tmp/runtimes/$runtime_id/" || { log e "Copy failed" "$logfile"; exit 1; }
        else
            echo "[WARNING] Runtime path $runtime_path not found, skipping."
        fi
    done

    FINALIZE_COMPONENT="$component"
    FINALIZE_PATH="$component/artifacts/.tmp"
    FINALIZE_VERSION="$extracted_version"

    log d "FINALIZE_COMPONENT=$FINALIZE_COMPONENT" "$logfile"
    log d "FINALIZE_PATH=$FINALIZE_PATH" "$logfile"
    log d "FINALIZE_VERSION=$FINALIZE_VERSION" "$logfile"

    log i "Finalizing artifact..." "$logfile"

    # cleanup dopo finalize
    if [[ "$was_installed" == "false" ]]; then
        log i "Uninstalling $flatpak_id as it was not previously installed." "$logfile"
        flatpak uninstall --user -y "$flatpak_id" || echo "[WARNING] Failed to uninstall $flatpak_id"
    fi
}

manage_flatpak_artifacts() {
    log d "Starting manage_flatpak_artifacts function" "$logfile"

    local component="$1"
    local url="$2"
    local version="$3"

    local filename
    filename=$(basename "$url")
    local extension="${filename##*.}"
    local output_path="$component/artifacts/$filename"

    mkdir -p "$component/artifacts"

    wget -qc "$url" -O "$output_path" || {
        log e "Failed to download Flatpak artifacts from $url" "$logfile"
        exit 1
    }

    if [[ ! -s "$output_path" ]]; then
        log e "Downloaded file is empty or missing: $output_path" "$logfile"
        exit 1
    fi

    # Tentativo di estrazione versione dal file se non fornita
    if [[ -z "$version" ]]; then
        version=$(version_check "metainfo" "$component" "$output_path" 2>/dev/null)
        if [[ -z "$version" ]]; then
            log w "Unable to extract version from $output_path, falling back to filename." "$logfile"
            version=$(basename "$url" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
            [[ -z "$version" ]] && version="unknown"
        fi
    fi

    # Final return
    MANAGED_OUTPUT_PATH="$output_path"
    MANAGED_OUTPUT_VERSION="$version"

}

finalize() {
    log d "Starting finalize function" "$logfile"

    if [[ -z "$FINALIZE_COMPONENT" || -z "$FINALIZE_PATH" || -z "$FINALIZE_VERSION" ]]; then
        log e "finalize() called without a valid grab step." "$logfile"
        log d "FINALIZE_COMPONENT=$FINALIZE_COMPONENT" "$logfile"
        log d "FINALIZE_PATH=$FINALIZE_PATH" "$logfile"
        log d "FINALIZE_VERSION=$FINALIZE_VERSION" "$logfile"
        return 1
    fi

    local component="${1:-$FINALIZE_COMPONENT}"
    local source_path="${2:-$FINALIZE_PATH}"
    local version="${3:-$FINALIZE_VERSION}"
    local max_size_mb=95
    local artifact_dir="$component/artifacts"
    local temp_tar="$artifact_dir/$component.tar.gz"
    local tmpzip_dir="$artifact_dir/.tmpzip"

    mkdir -p "$artifact_dir"

    if [[ -f "$source_path" ]]; then
        log i "Source is a file: $source_path" "$logfile"

        if [[ "$source_path" == *.AppImage ]]; then
            log i "Detected AppImage file, skipping compression." "$logfile"
            local target_path="$artifact_dir/$component.AppImage"

            if [[ "$(realpath "$source_path")" != "$(realpath "$target_path")" ]]; then
                cp -f "$source_path" "$target_path" || { log e "Failed to copy AppImage." "$logfile"; exit 1; }
            else
                log i "Source and destination are the same file, skipping copy." "$logfile"
            fi

            chmod +x "$target_path"
            sha256sum "$target_path" > "$target_path.sha"

        else
            local artifact_size_mb=$(( $(stat -c%s "$source_path") / 1024 / 1024 ))
            local filename=$(basename "$source_path")
            local target_path="$artifact_dir/$filename"

            if [[ "$artifact_size_mb" -gt "$max_size_mb" && "$SPLIT" == "true" ]]; then
                log i "Large file detected and SPLIT=true. Creating split ZIP..." "$logfile"
                rm -rf "$tmpzip_dir"
                mkdir -p "$tmpzip_dir"
                cp -f "$source_path" "$tmpzip_dir/" || { log e "Failed to copy file to tmp." "$logfile"; exit 1; }
                (cd "$artifact_dir" && zip -r -s ${max_size_mb}m "${component}.zip" ".tmpzip") || { log e "ZIP split failed." "$logfile"; exit 1; }
                rm -rf "$tmpzip_dir"
                for part in "$artifact_dir"/${component}.zip "$artifact_dir"/${component}.z*; do
                    [[ -f "$part" ]] && sha256sum "$part" > "$artifact_dir/$(basename "$part").sha"
                done
            else
                log i "Copying file as-is (no split)." "$logfile"
                if [[ "$(realpath "$source_path")" != "$(realpath "$target_path")" ]]; then
                    cp -f "$source_path" "$target_path" || { log e "Copy failed." "$logfile"; exit 1; }
                else
                    log i "Source and destination are the same file, skipping copy." "$logfile"
                fi
                sha256sum "$target_path" > "$target_path.sha"
            fi
        fi

    elif [[ -d "$source_path" ]]; then
        log i "Source is a directory." "$logfile"

        tar -czf "$temp_tar" -C "$source_path" . || { log e "Tar creation failed." "$logfile"; exit 1; }

        local artifact_size_mb=$(( $(stat -c%s "$temp_tar") / 1024 / 1024 ))

        if [[ "$artifact_size_mb" -gt "$max_size_mb" && "$SPLIT" == "true" ]]; then
            log i "Directory archive is large and SPLIT=true. Creating split ZIP..." "$logfile"
            rm -f "$temp_tar"
            rm -rf "$tmpzip_dir"
            cp -rf "$source_path" "$tmpzip_dir" || { log e "Failed to copy directory." "$logfile"; exit 1; }
            (cd "$artifact_dir" && zip -r -s ${max_size_mb}m "${component}.zip" ".tmpzip") || { log e "Split zip failed." "$logfile"; exit 1; }
            rm -rf "$tmpzip_dir"
            for part in "$artifact_dir"/${component}.zip "$artifact_dir"/${component}.z*; do
                [[ -f "$part" ]] && sha256sum "$part" > "$artifact_dir/$(basename "$part").sha"
            done
        else
            log i "Archive size OK or split disabled. Keeping tar.gz." "$logfile"
            sha256sum "$temp_tar" > "$temp_tar.sha"
        fi

    else
        log e "Source path is neither a file nor a directory: $source_path" "$logfile"
        exit 1
    fi

    if [[ -n "$version" ]]; then
        echo "$version" > "$artifact_dir/version"
    fi

    rm -rf "$artifact_dir/.tmp"
}


write_components_version() {

    log d "Starting write_components_version function" "$logfile"

    # Create or overwrite the components_version.md file
    local components_version_file="components_version.md"
    if [[ ! -f "$components_version_file" ]]; then
        echo "# Components Version Summary" > "$components_version_file"
    fi
    echo "" >> "$components_version_file"

    # Loop through all */artifacts/version files
    for version_file in */artifacts/version; do
        if [[ -f "$version_file" ]]; then
            local component_name=$(basename "$(dirname "$(dirname "$version_file")")")
            local version=$(cat "$version_file")
            local update_date=$(date -r "$version_file" +"%Y-%m-%d %H:%M:%S")

            log d "Component: $component_name" "$logfile"
            log d "Version: $version" "$logfile"
            log d "Last Updated: $update_date" "$logfile"
            
            echo "## $component_name" >> "$components_version_file"
            echo "- Version: $version" >> "$components_version_file"
            echo "- Last Updated: $update_date" >> "$components_version_file"
            echo "" >> "$components_version_file"
        fi
    done
}

version_check() {
    log d "Starting version_check function" "$logfile"

    local check_type="$1"
    local component="$2"
    local source="$3"

    local version=""
    local current_version=""
    local version_file="$component/version"

    case "$check_type" in
        manual|link|file)
        if [[ "$source" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            version="$source"

        elif [[ "$source" =~ ^https?:// ]]; then
            # Try standard version pattern
            version=$(echo "$source" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)

            # Fallback: try nightly or date-based version
            if [[ -z "$version" ]]; then
                version=$(echo "$source" | grep -oE 'nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n 1)
            fi

            if [[ -z "$version" ]]; then
                version=$(echo "$source" | grep -oE '[0-9]{4}[_-][0-9]{2}[_-][0-9]{2}' | head -n 1)
            fi

        elif [[ -f "$source" ]]; then
            version=$(basename "$source" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
        fi
        ;;

        metainfo)
            if [[ -f "$source" && "$source" =~ \.(metainfo|appdata)\.xml$ ]]; then
                version=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$source" 2>/dev/null | head -n 1)

            elif [[ -d "$source" ]]; then
                local metainfo_file
                metainfo_file=$(find "$source" -type f \( -name "*.metainfo.xml" -o -name "*.appdata.xml" \) | head -n 1)
                if [[ -n "$metainfo_file" ]]; then
                    version=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$metainfo_file" 2>/dev/null | head -n 1)
                fi

            elif [[ -f "$source" && "$source" =~ \.tar\.(gz|xz|bz2)$ ]]; then
                local metainfo_path
                metainfo_path=$(tar -tf "$source" | grep -m1 -E '\.(metainfo|appdata)\.xml$')
                if [[ -n "$metainfo_path" ]]; then
                    log d "Found metadata in archive: $metainfo_path" "$logfile"
                    version=$(tar -xOf "$source" "$metainfo_path" 2>/dev/null | \
                        xmlstarlet sel -t -v "/component/releases/release[1]/@version" 2>/dev/null | head -n 1)
                fi

            elif [[ -f "$source" && "$source" =~ \.zip$ ]]; then
                version=$(unzip -p "$source" '*.metainfo.xml' '*.appdata.xml' 2>/dev/null | \
                    xmlstarlet sel -t -v "/component/releases/release[1]/@version" 2>/dev/null | head -n 1)

            else
                log w "Unsupported format for metainfo extraction: $source" "$logfile"
            fi
            ;;
        
        *)
            log e "Unknown version check type: $check_type" "$logfile"
            exit 1
            ;;
    esac

    if [[ -z "$version" ]]; then
        log w "Could not determine version for $component (source: \"$source\"), setting as \"unknown\"" "$logfile"
        version="unknown"
    fi

    log i "Detected version: $version" "$logfile"

    if [[ -f "$version_file" ]]; then
        current_version=$(cat "$version_file")
        if [[ "$current_version" == "$version" && "${FORCE:-0}" -ne 1 ]]; then
            echo "$version"
            return 0
        fi
    fi

    echo "$version" > "$version_file"
    echo "$version"
    return 1
}

