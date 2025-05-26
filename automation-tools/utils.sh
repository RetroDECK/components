# NOTE: be aware that WORK_DIR is a disposable directory, so you should not use it to store any data that you want to keep after the script ends, that is going in $component/artifacts

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
# Auto-detect CI/CD environment and force artifact generation
if [[ -n "$CI" || -n "$GITHUB_ACTIONS" || -n "$GITLAB_CI" || -n "$BUILDKITE" || -n "$JENKINS_HOME" ]]; then
    FORCE=1
    log d "CI/CD environment detected — forcing artifact regeneration (FORCE=1)" "$logfile"
fi

grab() {

    local args
    args=($(parse_flags "$@"))
    export type="${args[0]}"
    export url="${args[1]}"
    export component="${args[2]:-$(basename "$(dirname "$(realpath "${BASH_SOURCE[1]}")")")}"
    export WORK_DIR=$(mktemp -d)
    local output_path=""

    echo ""
    echo "-----------------------------------------------------------"
    echo "   PREPARING ARTIFACTS FOR COMPONENT: $component"
    echo "-----------------------------------------------------------"

    log d "Preparing work directory: $WORK_DIR" "$logfile"
    mkdir -p "$WORK_DIR"
    log d "Component: $component" "$logfile"
    mkdir -p "$component/artifacts"

    log i "Grabbing type '$type' from URL: $url" "$logfile"

    case "$type" in
        flatpak_id)
            log i "Type flatpak_id detected, skipping download." "$logfile"
            manage_flatpak_id
            return
            ;;
        flatpak_artifacts)
            log i "Type flatpak_artifacts detected, handling flatpak artifacts from URL: $url" "$logfile"
            manage_flatpak_artifacts
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
                export version="$folder"
                log i "Resolved URL: $url" "$logfile"
            else
                log e "No version folders found at $base_url." "$logfile"
                exit 1
            fi
            ;;
    esac

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
    version_check "link" "$component" "$url"

    log d "Evaluating type: $type" "$logfile"

    case "$type" in
        appimage)
            manage_appimage
            ;;
        generic)
            manage_generic
            ;;
        *)
            log e "Unsupported type for automatic management: $type" "$logfile"
            exit 1
            ;;
    esac
}

manage_appimage() {
    log d "Starting manage_appimage function" "$logfile"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage appimage for $component from $output_path" "$logfile"
        return 0
    fi

    log i "Managing AppImage for component: $component" "$logfile"

    local temp_root
    temp_root=$(mktemp -d)

    local appimage_path=""

    # Handle archives
    if [[ "$output_path" =~ \.tar\.(gz|xz|bz2)$ || "$output_path" =~ \.7z$ ]]; then
        log i "Extracting archive to temp..." "$logfile"
        if [[ "$output_path" =~ \.7z$ ]]; then
            7z x -y "$output_path" -o"$temp_root" > /dev/null || {
                log e "Failed to extract 7z archive" "$logfile"
                rm -rf "$temp_root"
                return 1
            }
        else
            tar -xf "$output_path" -C "$temp_root" || {
                log e "Failed to extract tar archive" "$logfile"
                rm -rf "$temp_root"
                return 1
            }
        fi

        appimage_path=$(find "$temp_root" -type f -name '*.AppImage' | head -n 1)
        [[ -z "$appimage_path" ]] && {
            log e "No AppImage found in archive." "$logfile"
            rm -rf "$temp_root"
            return 1
        }

    elif [[ "$output_path" =~ \.AppImage$ ]]; then
        appimage_path="$output_path"
        [[ ! -f "$appimage_path" ]] && {
            log e "AppImage file not found: $appimage_path" "$logfile"
            return 1
        }
    else
        log e "Unsupported file type for AppImage: $output_path" "$logfile"
        return 1
    fi

    local abs_appimage_path
    abs_appimage_path=$(realpath "$appimage_path")
    chmod +x "$abs_appimage_path"

    log d "Running AppImage extraction command..." "$logfile"
    cd "$WORK_DIR"
    "$abs_appimage_path" --appimage-extract
    extract_status=$?
    cd - > /dev/null

    if [[ $extract_status -ne 0 ]]; then
        log e "AppImage extraction failed with status $extract_status." "$logfile"
        rm -rf "$temp_root"
        return 1
    fi

    # Cleanup
    [[ -d "$WORK_DIR/squashfs-root/share/metainfo" ]] && rm -rf "$WORK_DIR/squashfs-root/share/metainfo"
    # Remove any .desktop files and .DirIcon from the extracted AppImage
    # Define a list of filenames to search for and delete
    files_to_remove=(".DirIcon" "*.desktop" "*.metainfo.xml")

    files_to_delete=()
    for pattern in "${files_to_remove[@]}"; do
        while IFS= read -r file; do
            files_to_delete+=("$file")
        done < <(find "$WORK_DIR/squashfs-root" -type f -name "$pattern")
    done

    for file in "${files_to_delete[@]}"; do
        rm -f "$file"
    done

    # Move only if dirs exist
    [[ -d "$WORK_DIR/squashfs-root/usr" ]] && mv "$WORK_DIR/squashfs-root/usr"/* "$component/artifacts/" || log w "No usr/ content found"
    [[ -d "$WORK_DIR/squashfs-root/share" ]] && mv "$WORK_DIR/squashfs-root/share" "$component/artifacts/"
    [[ -d "$WORK_DIR/squashfs-root/apprun-hooks" ]] && mv "$WORK_DIR/squashfs-root/apprun-hooks" "$component/artifacts/"

    # Move any other top-level files (e.g. binaries, .pak, etc.)
    find "$WORK_DIR/squashfs-root" -maxdepth 1 -type f -exec mv {} "$component/artifacts/" \;

    rm -rf "$temp_root" "$abs_appimage_path"
    log i "AppImage files moved to artifacts directory." "$logfile"
}

manage_generic() {

    log d "Starting manage_generic function" "$logfile"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage generic artifact for $component from $output_path" "$logfile"
        return
    fi

    log i "Managing generic artifact for component: $component from $output_path" "$logfile"

    if [[ ! -f "$output_path" ]]; then
        log e "Generic artifact not found: $output_path" "$logfile"
        exit 1
    fi

}

# This function not compiling the flatpak, just downloading it and extracting it (+ runtimes and sdk)
manage_flatpak_id() {

    log d "Starting manage_flatpak_id function" "$logfile"

    local flatpak_id="$url"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage flatpak for $flatpak_id" "$logfile"
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

    export version=$(version_check "metainfo" "$component" "$metainfo_path")

    if [[ $? -eq 0 ]]; then
        log i "Skipping $flatpak_id because version is already up-to-date." "$logfile"
        [[ "$was_installed" == "false" ]] && flatpak uninstall --user -y "$flatpak_id" || true
        exit 0
    fi

    # Roughly moving all the files to the work directory
    cp -r "$app_path" "$WORK_DIR"

    log i "Removing debug symbols from $flatpak_id..." "$logfile"
    rm -rf "$WORK_DIR/lib/debug"

    log i "Copying application files in the actual artifacts directory..." "$logfile"
    mv "$WORK_DIR/bin" "$component/artifacts/"
    mv "$WORK_DIR/lib" "$component/artifacts/"
    mv "$WORK_DIR/share/ppsspp/assets" "$component/artifacts/"
    mv "$WORK_DIR/share" "$component/artifacts/"

    log i "Finding required runtimes for $flatpak_id..." "$logfile"
    local runtimes
    runtimes=$(flatpak info --user "$flatpak_id" | awk '/Runtime:/ {print $2} /Sdk:/ {print $2}')
    log i "Found runtimes:\n$runtimes" "$logfile"

    for runtime_id in $runtimes; do
        log i "Including runtime: $runtime_id" "$logfile"

        local runtime_name=$(echo "$runtime_id" | cut -d'/' -f1)
        local runtime_arch=$(echo "$runtime_id" | cut -d'/' -f2)
        local runtime_branch=$(echo "$runtime_id" | cut -d'/' -f3)

        local runtime_path="$HOME/.local/share/flatpak/runtime/$runtime_name/$runtime_arch/$runtime_branch/active/files"

        if [[ -d "$runtime_path" ]]; then
            log i "Copying runtime files for $runtime_id..." "$logfile"
            mkdir -p "$component/artifacts/runtimes/$runtime_id"
            cp -r "$runtime_path"/* "$component/artifacts/runtimes/$runtime_id/" || { log e "Copy failed" "$logfile"; exit 1; }
        else
            echo "[WARNING] Runtime path $runtime_path not found, skipping."
        fi
    done

    # Uninstall the flatpak if it was not previously installed
    if [[ "$was_installed" == "false" ]]; then
        log i "Uninstalling $flatpak_id as it was not previously installed." "$logfile"
        flatpak uninstall --user -y "$flatpak_id" || log w "Failed to uninstall $flatpak_id" "$logfile"
    fi
}

manage_flatpak_artifacts() {
    log d "Starting manage_flatpak_artifacts function" "$logfile"

    local filename=$(basename "$url")
    local extension="${filename##*.}"
    local output_path="$component/artifacts/$filename"

    mkdir -p "$WORK_DIR/$component/artifacts"

    wget -qc "$url" -O "$output_path" || {
        log e "Failed to download Flatpak artifacts from $url" "$logfile"
        exit 1
    }

    if [[ ! -s "$output_path" ]]; then
        log e "Downloaded file is empty or missing: $output_path" "$logfile"
        exit 1
    fi

    # Attempt to extract version from the file if not provided
    if [[ -z "$version" ]]; then
        export version=$(version_check "metainfo" "$component" "$output_path" 2>/dev/null)
        if [[ -z "$version" ]]; then
            log w "Unable to extract version from $output_path, falling back to filename." "$logfile"
            export version=$(basename "$url" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
            [[ -z "$version" ]] && version="unknown"
        fi
    fi

    mkdir -p "$WORK_DIR"
    tar -xf "$output_path" -C "$WORK_DIR" || {
        log e "Failed to extract Flatpak artifacts from $output_path" "$logfile"
        exit 1
    }

    mv "$WORK_DIR/files/bin/" "$component/artifacts/"
    mv "$WORK_DIR/files/lib/" "$component/artifacts/"
    mv "$WORK_DIR/files/share/" "$component/artifacts/"
}

finalize() {
    log i "Finalizing $component" "$logfile"

    local artifact_dir="$component/artifacts"

    if [[ -z "$component" || -z "$version" ]]; then
        log e "finalize() missing required environment: component=$component version=$version" "$logfile"
        return 1
    fi

    if [[ ! -d "$artifact_dir" ]]; then
        log e "Artifact directory does not exist: $artifact_dir" "$logfile"
        ls -lah "$component"
        return 1
    fi

    # Inject standard component files if present
    local inject_files=("component_launcher.sh" "manifest.json" "functions.sh" "prepare_component.sh")
    for file in "${inject_files[@]}"; do
        if [[ -f "$file" ]]; then
            mv "$file" "$artifact_dir"
            [[ "$file" == *.sh ]] && chmod +x "$artifact_dir/$file"
        fi
    done

    # Package artifact directory
    local tar_output_path="${component}/${component}.tar.gz"
    tar -czf "$tar_output_path" -C "$artifact_dir" . || {
        log e "Tar creation failed." "$logfile"
        return 1
    }
    sha256sum "$tar_output_path" > "$tar_output_path.sha"
    mv "$tar_output_path" "$artifact_dir/"
    mv "$tar_output_path.sha" "$artifact_dir/"

    echo "$version" > "$artifact_dir/version"

    if [[ -d $WORK_DIR ]]; then
        log i "Cleaning up work directory: $WORK_DIR" "$logfile"
        rm -rf "$WORK_DIR"
    fi

    log d "Final artifact contents:" "$logfile"
    tar -tzf "$artifact_dir/$component.tar.gz" | while read -r line; do
        log d "  $line" "$logfile"
    done

    log i "Finalization complete for $component" "$logfile"
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
            export version=$(cat "$version_file")
            local update_date=$(date -r "$version_file" +"%Y-%m-%d %H:%M:%S")

            log d "Component: $component_name" "$logfile"
            log d "Version: $version" "$logfile"
            log d "Last Updated: $update_date" "$logfile"
            
            echo "**$component_name**: $version (updated on $update_date)" >> "$components_version_file"
            echo "" >> "$components_version_file"
        fi
    done
}

version_check() {
    log d "Starting version_check function" "$logfile"

    local check_type="$1"
    local component="$2"
    local source="$3"

    local current_version=""
    local version_file="$component/version"
    local extracted_version=""

    case "$check_type" in
        manual|link|file)
            if [[ "$source" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                extracted_version="$source"

            elif [[ "$source" =~ ^https?:// ]]; then
                extracted_version=$(echo "$source" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)

                [[ -z "$extracted_version" ]] && \
                    extracted_version=$(echo "$source" | grep -oE 'nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n 1)

                [[ -z "$extracted_version" ]] && \
                    extracted_version=$(echo "$source" | grep -oE '[0-9]{4}[_-][0-9]{2}[_-][0-9]{2}' | head -n 1)

            elif [[ -f "$source" ]]; then
                extracted_version=$(basename "$source" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
            fi
            ;;

        metainfo)
            if [[ -f "$source" && "$source" =~ \.(metainfo|appdata)\.xml$ ]]; then
                extracted_version=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$source" 2>/dev/null)

            elif [[ -d "$source" ]]; then
                local metainfo_file
                metainfo_file=$(find "$source" -type f \( -name "*.metainfo.xml" -o -name "*.appdata.xml" \) | head -n 1)
                [[ -n "$metainfo_file" ]] && \
                    extracted_version=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$metainfo_file" 2>/dev/null)

            elif [[ -f "$source" && "$source" =~ \.tar\.(gz|xz|bz2)$ ]]; then
                local metainfo_path
                metainfo_path=$(tar -tf "$source" | grep -m1 -E '\.(metainfo|appdata)\.xml$')
                if [[ -n "$metainfo_path" ]]; then
                    log d "Found metadata in archive: $metainfo_path" "$logfile"
                    extracted_version=$(tar -xOf "$source" "$metainfo_path" 2>/dev/null | \
                        xmlstarlet sel -t -v "/component/releases/release[1]/@version" 2>/dev/null)
                fi

            elif [[ -f "$source" && "$source" =~ \.zip$ ]]; then
                extracted_version=$(unzip -p "$source" '*.metainfo.xml' '*.appdata.xml' 2>/dev/null | \
                    xmlstarlet sel -t -v "/component/releases/release[1]/@version" 2>/dev/null)

            else
                log w "Unsupported format for metainfo extraction: $source" "$logfile"
            fi
            ;;
        
        *)
            log e "Unknown version check type: $check_type" "$logfile"
            return 1
            ;;
    esac

    if [[ -z "$extracted_version" ]]; then
        log w "Could not determine version for $component (source: \"$source\"), setting as \"unknown\"" "$logfile"
        extracted_version="unknown"
    fi

    export version="$extracted_version"
    log i "Detected version: $version" "$logfile"

    if [[ -f "$version_file" ]]; then
        current_version=$(< "$version_file")
        if [[ "$current_version" == "$version" && "$FORCE" -ne 1 ]]; then
            log i "Version check passed: $version (no update needed)" "$logfile"
            return 0
        fi
    fi

    echo "$version" > "$version_file"
    log i "Version file updated: $version_file with version $version" "$logfile"
    return 1
}

