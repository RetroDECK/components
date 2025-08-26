#!/bin/bash

# NOTE: be aware that WORK_DIR is a disposable directory, so you should not use it to store any data that you want to keep after the script ends, that is going in $component/artifacts

# TODO: create a proper function to handle archives instead of repeating the same code in each component

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

export logfile="$(realpath -m assemble.log)"
export rd_logging_level="debug"

if [[ -f ".tmpfunc/logger.sh" ]]; then
    # Set up logging variables for the external logger BEFORE sourcing
    export logging_level="$rd_logging_level"
    export rd_logs_folder="$(dirname "$logfile")"
    source ".tmpfunc/logger.sh"
else
    # Fallback logger function if logger.sh is not available

    log() {
        echo "[$1] $2" >&2
        echo "[$1] $2" >> "$logfile"
    }

    log e "Logger script not found. Please ensure .tmpfunc/logger.sh exists." "$logfile"
fi

FORCE=0                 # Force the download even if the version is the same, useful for local retention, enabled by default on CI/CD to avoid missing updates since the version files are present bu the artifacts are not
DRY_RUN=0
GITHUB_REPO=$(git config --get remote.origin.url | sed -E 's|.*github.com[:/](.*)\.git|\1|')
# Fix GITHUB_REPO if it mistakenly has the full URL
if [[ "$GITHUB_REPO" == https://github.com/* ]]; then
  GITHUB_REPO="${GITHUB_REPO#https://github.com/}"
fi
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
export extras="rd_extras"      # Name of the extras folder used to place components extras such as free bioses, cheats files and such
components_version_list="components_version_list.md"
export component="${args[2]:-$(basename "$(dirname "$(realpath "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")")")}"
export version_file="$component/component_version"
safe_download_warning="false"

parse_flags() {
    local even_dirs=()
    while [[ "$1" =~ ^-- ]]; do
        case "$1" in
            --force)
                FORCE=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --even)
                shift
                if [[ -z "$1" || "$1" =~ ^-- ]]; then
                    echo "Error: --even requires a path argument"
                    exit 1
                fi
                even_dirs+=("$1")
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
    export EVEN_DIRS=("${even_dirs[@]}")
    echo "$@"
}

safe_download() {
    local url="$1"
    local dest="$2"
    local component_name="${3:-$component}"  # Use provided or fallback to current

    log i "Attempting to download: $url -> $dest" "$logfile"
    wget -qc "$url" -O "$dest"

    if [[ $? -ne 0 || ! -s "$dest" ]]; then
        log w "Primary download failed for $component_name from $url" "$logfile"
        rm -f "$dest"

        # Try to recover component.zip from the "latest" release of the RetroDECK/components repo
        local fallback_repo="${FALLBACK_GITHUB_REPO:-RetroDECK/components}"
        local zip_name="${component_name}.zip"
        local latest_release_json
        if [[ -n "$GITHUB_TOKEN" ]]; then
            latest_release_json=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/$fallback_repo/releases/latest")
        else
            latest_release_json=$(curl -s "https://api.github.com/repos/$fallback_repo/releases/latest")
        fi
        local latest_asset_url
        latest_asset_url=$(echo "$latest_release_json" | jq -r --arg zip "$zip_name" '.assets[]? | select(.name == $zip) | .browser_download_url' | head -n 1)
        if [[ -n "$latest_asset_url" ]]; then
            log w "Recovering $zip_name from the 'latest' release of $fallback_repo" "$logfile"
            wget -qc "$latest_asset_url" -O "$dest"
            if [[ $? -eq 0 && -s "$dest" ]]; then
                export safe_download_warning="true"
                return 0
            fi
        fi
        # If not found in the latest release, search all releases for the most recent containing component.zip
        local all_releases_json
        if [[ -n "$GITHUB_TOKEN" ]]; then
            all_releases_json=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/$fallback_repo/releases")
        else
            all_releases_json=$(curl -s "https://api.github.com/repos/$fallback_repo/releases")
        fi
        if echo "$all_releases_json" | grep -q "API rate limit exceeded"; then
            log e "GitHub API rate limit exceeded while trying fallback." "$logfile"
            return 1
        fi
        # Sort releases by date and look for the most recent component.zip
        local fallback_asset_url
        fallback_asset_url=$(echo "$all_releases_json" | jq -r --arg zip "$zip_name" '
            sort_by(.published_at) | reverse | .[] | .assets[]? | select(.name == $zip) | .browser_download_url' | head -n 1)
        if [[ -n "$fallback_asset_url" ]]; then
            log w "Recovering $zip_name from the most recent release containing it in $fallback_repo" "$logfile"
            wget -qc "$fallback_asset_url" -O "$dest"
            if [[ $? -eq 0 && -s "$dest" ]]; then
                export safe_download_warning="true"
                return 0
            fi
        fi
        log e "No asset $zip_name found in releases of $fallback_repo" "$logfile"
        return 1
    fi

    log i "Download successful: $dest" "$logfile"
    return 0
}

assemble() {

    local args
    args=($(parse_flags "$@"))
    export type="${args[0]}"
    export url="${args[1]}"
    export WORK_DIR=$(mktemp -d)
    local output_path=""

    echo ""
    echo "-------------------------------------------"
    echo "   ASSEMBLING COMPONENT: $component"
    echo "-------------------------------------------"

    # Auto-detect CI/CD environment and force artifact generation
    if [[ -n "$CI" || -n "$GITHUB_ACTIONS" || -n "$GITLAB_CI" || -n "$BUILDKITE" || -n "$JENKINS_HOME" ]]; then
        FORCE=1
        log d "CI/CD environment detected — forcing artifact regeneration (FORCE=1)" "$logfile"
    fi

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
        *api/v4/projects/*/packages/generic/*'*'*)
            log i "GitLab wildcard URL detected, resolving via GitLab API..." "$logfile"

            gitlab_base="${url%%/api/v4/*}"
            repo_id=$(echo "$url" | grep -oP '/api/v4/projects/\K[0-9]+')
            package_name=$(echo "$url" | sed -E 's|.*/packages/generic/([^/]+)/.*|\1|')

            packages_api="$gitlab_base/api/v4/projects/$repo_id/packages?package_name=$package_name&order_by=version&sort=desc"
            log d "Querying package versions: $packages_api" "$logfile"
            packages_json=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$packages_api")
            latest_version=$(echo "$packages_json" | jq -r '.[0].version')

            if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
                log e "No versions found for package: $package_name" "$logfile"
                exit 1
            fi

            export version="$latest_version"
            log i "Resolved latest version: $version" "$logfile"

            url="${url//\*/$version}"
            log i "Resolved URL: $url" "$logfile"
            ;;
        # Handle local file wildcards (e.g., /path/to/*.zip)
        /*\**)
            log i "Local file wildcard detected, resolving..." "$logfile"
            local_dir=$(dirname "$url")
            pattern=$(basename "$url")
            resolved_file=$(find "$local_dir" -maxdepth 1 -type f -name "$pattern" | sort | head -n 1)
            if [[ -z "$resolved_file" ]]; then
                log e "No matching local file found for pattern: $url" "$logfile"
                exit 1
            fi
            url="$resolved_file"
            log i "Resolved local file: $url" "$logfile"
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
            safe_download "$url" "$output_path" "$component" || { log e "Failed to download $url" "$logfile"; exit 1; }

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
    # TODO: bad, streamline me
    if [[ "$type" == "gh_latest_release" ]]; then
        log i "Skipping version_check here for gh_latest_release (handled later)" "$logfile"
    else
        version_check "link" "$component" "$url"
    fi

    log d "Evaluating type: $type" "$logfile"

    case "$type" in
        appimage)
            manage_appimage
            ;;
        generic)
            manage_generic
            ;;
        local)
            manage_local
            ;;
        gh_latest_release)
            manage_gh_latest_release
            ;;
        *)
            log e "Unsupported type for automatic management: $type" "$logfile"
            exit 1
            ;;
    esac
}

# Universal library filter - removes system-critical libraries from any directory
filter_critical_system_libraries() {
    local target_dir="$1"
    local filter_type="${2:-lib}"  # 'lib' for directory filtering, 'list' for text file filtering
    
    log i "🛡️ Filtering critical system libraries from: $target_dir (type: $filter_type)" "$logfile"
    
    # List of system-critical library patterns to exclude/remove
    local critical_patterns=(
        "libc.so*"
        "libdl.so*"
        "libpthread.so*"
        "librt.so*"
        "libm.so*"
        "ld-linux*"
        "linux-vdso*"
        "libgcc_s.so*"
        "libstdc++.so*"
        "libresolv.so*"
        "libnss_*"
        "libutil.so*"
        "libcrypt.so*"
        "libelf.so*"
        "libz.so*"
        "libbz2.so*"
        "liblzma.so*"
        "libexpat.so*"
        "libffi.so*"
        "libpcre*"
        "libselinux.so*"
        "libcap.so*"
        "libacl.so*"
        "libattr.so*"
    )
    
    if [[ "$filter_type" == "lib" ]]; then
        # Filter actual library files in directories
        if [[ -d "$target_dir" ]]; then
            for lib_file in "$target_dir"/*.so* "$target_dir"/**/lib*.so*; do
                if [[ -f "$lib_file" ]]; then
                    local lib_name=$(basename "$lib_file")
                    
                    # Check if this library matches any critical pattern
                    for pattern in "${critical_patterns[@]}"; do
                        if [[ "$lib_name" == $pattern ]]; then
                            log w "🚫 Removing critical system library: $lib_name" "$logfile"
                            rm -f "$lib_file"
                            break
                        fi
                    done
                    
                    # Set executable permissions for remaining libraries
                    if [[ -f "$lib_file" ]]; then
                        chmod +x "$lib_file"
                        log d "✅ Kept and set permissions: $lib_name" "$logfile"
                    fi
                fi
            done
            
            # Handle subdirectories recursively
            find "$target_dir" -type d -mindepth 1 | while read -r subdir; do
                filter_critical_system_libraries "$subdir" "lib"
            done
        fi
        
    elif [[ "$filter_type" == "list" ]]; then
        # Filter text files (for required_libraries processing)
        local input_file="$target_dir"
        local output_file="$3"  # Third parameter is output file for list filtering
        
        if [[ ! -f "$input_file" ]]; then
            log e "Input file not found: $input_file" "$logfile"
            return 1
        fi
        
        # Clear output file
        > "$output_file"
        
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            
            local skip_line=false
            
            # Check if line contains any critical library pattern
            for pattern in "${critical_patterns[@]}"; do
                if [[ "$line" == *"$pattern"* ]]; then
                    log w "🚫 Filtering out critical library: $line" "$logfile"
                    skip_line=true
                    break
                fi
            done
            
            # Add to output if not critical
            if [[ "$skip_line" == false ]]; then
                echo "$line" >> "$output_file"
                log d "✅ Keeping library: $line" "$logfile"
            fi
            
        done < "$input_file"
        
        log i "✅ Library list filtering complete" "$logfile"
    fi
}

# Filter AppImage libraries to exclude system-critical ones
filter_appimage_libs() {
    local source_dir="$1"
    local dest_dir="$2"
    
    log i "🔍 Filtering AppImage libraries from: $source_dir" "$logfile"
    
    # Copy all non-lib directories first
    for item in "$source_dir"/*; do
        if [[ -d "$item" && "$(basename "$item")" != "lib" ]]; then
            log d "📁 Copying directory: $(basename "$item")" "$logfile"
            cp -rL "$item" "$dest_dir/"
        elif [[ -f "$item" ]]; then
            log d "📄 Copying file: $(basename "$item")" "$logfile"
            cp -L "$item" "$dest_dir/"
        fi
    done
    
    # Handle lib directory - copy first, then filter
    if [[ -d "$source_dir/lib" ]]; then
        log i "🔧 Processing lib directory..." "$logfile"
        mkdir -p "$dest_dir/lib"
        cp -rL "$source_dir/lib/"* "$dest_dir/lib/" 2>/dev/null || true
        
        # Apply unified filtering
        filter_critical_system_libraries "$dest_dir/lib" "lib"
    fi
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
    if [[ "$output_path" =~ \.tar(\.(gz|xz|bz2))?$ || "$output_path" =~ \.7z$ || "$output_path" =~ \.zip$ ]]; then
        log i "Extracting archive to temp..." "$logfile"
        if [[ "$output_path" =~ \.7z$ ]]; then
            7z x -y "$output_path" -o"$temp_root" > /dev/null || {
                log e "Failed to extract 7z archive" "$logfile"
                rm -rf "$temp_root"
                return 1
            }
        else
            extract_archive "$output_path" "$temp_root" || {
            log e "Failed to extract archive for AppImage." "$logfile"
            rm -rf "$temp_root"
            return 1
        }
        fi
        rm -f "$output_path" # Remove the original archive to save space

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
    [[ -d "$WORK_DIR/squashfs-root/usr/share/metainfo" ]] && rm -rf "$WORK_DIR/squashfs-root/usr/share/metainfo"
    [[ -d "$WORK_DIR/squashfs-root/usr/lib/debug" ]] && rm -rf "$WORK_DIR/squashfs-root/usr/lib/debug"
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

    # Move only if dirs exist, but filter out system-critical libraries
    if [[ -d "$WORK_DIR/squashfs-root/usr" ]]; then
        log i "Filtering AppImage contents to exclude system-critical libraries..." "$logfile"
        filter_appimage_libs "$WORK_DIR/squashfs-root/usr" "$component/artifacts/"
    else
        log w "No usr/ content found" "$logfile"
    fi
    [[ -d "$WORK_DIR/squashfs-root/share" ]] && mv "$WORK_DIR/squashfs-root/share" "$component/artifacts/"
    [[ -d "$WORK_DIR/squashfs-root/apprun-hooks" ]] && mv "$WORK_DIR/squashfs-root/apprun-hooks" "$component/artifacts/"

    # Move any other top-level files (e.g. binaries, .pak, etc.)
    find "$WORK_DIR/squashfs-root" -maxdepth 1 -type f -exec mv {} "$component/artifacts/" \;

    rm -rf "$temp_root" "$abs_appimage_path"
    log i "AppImage files moved to artifacts directory." "$logfile"
    
    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries
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

    extract_archive "$output_path" "$WORK_DIR"

    log d "Moving extracted contents to $component/artifacts/" "$logfile"
    cp -rL "$WORK_DIR"/* "$component/artifacts/" || {
        log e "Failed to move extracted files to artifacts." "$logfile"
        exit 1
    }
    
    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries
}

# This function not compiling the flatpak, just downloading it and extracting it (+ runtimes and sdk)
manage_flatpak_id() {
    log d "Starting manage_flatpak_id function" "$logfile"

    local flatpak_id="$url"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage flatpak for $flatpak_id" "$logfile"
        return 0
    fi

    # Ensure flathub is added as a remote
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

    local was_installed="true"
    if ! flatpak info --user "$flatpak_id" > /dev/null 2>&1; then
        log i "Flatpak $flatpak_id is not installed. Proceeding with installation." "$logfile"
        was_installed="false"
    fi

    # Install or update the Flatpak app (user scope)
    flatpak install --user -y --or-update flathub "$flatpak_id"

    # Define expected file locations
    local app_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/files"
    local metainfo_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/export/share/metainfo/$flatpak_id.metainfo.xml"
    if [[ ! -f "$metainfo_path" ]]; then
        metainfo_path="$HOME/.local/share/flatpak/app/$flatpak_id/x86_64/stable/active/export/share/metainfo/$flatpak_id.appdata.xml"
    fi

    # Ensure the metainfo exists for version detection
    if [[ ! -f "$metainfo_path" ]]; then
        log e "Metainfo file not found at \"$metainfo_path\"." "$logfile"
        ls -lah "$(dirname "$metainfo_path")"
        exit 1
    fi

    # Ensure the app files exist
    if [[ ! -d "$app_path" ]]; then
        log e "App path not found: \"$app_path\"." "$logfile"
        ls -lah "$(dirname "$app_path")"
        exit 1
    fi

    # Perform version check using the metainfo XML
    version_check "metainfo" "$component" "$metainfo_path"
    if [[ $? -eq 0 ]]; then
        log i "Skipping $flatpak_id because version is already up-to-date." "$logfile"
        [[ "$was_installed" == "false" ]] && flatpak uninstall --user -y "$flatpak_id" || true
        exit 0
    fi

    # Copy app contents into a temporary working directory
    cp -rL "$app_path" "$WORK_DIR"

    log i "Removing debug symbols from $flatpak_id..." "$logfile"
    rm -rf "$WORK_DIR/lib/debug"

    log i "Copying application files to artifacts directory..." "$logfile"

    # Target folders to extract: only those that exist at top level
    target_dirs=(bin lib share)

    # Loop through each folder type
    for target in "${target_dirs[@]}"; do
        # Search only one level deep into $WORK_DIR to avoid nested matches like usr/lib
        found_path=$(find "$WORK_DIR" -mindepth 1 -maxdepth 2 -type d -name "$target" | head -n 1)

        if [[ -n "$found_path" ]]; then
            log i "Found top-level $target at $found_path, moving to artifacts..." "$logfile"
            cp -rL "$found_path" "$component/artifacts/" || {
                log e "Failed to copy $target from $found_path" "$logfile"
                exit 1
            }
            # Filter and set executable permissions for shared libraries if we copied lib directory
            if [[ "$target" == "lib" ]]; then
                log i "Filtering and setting permissions for Flatpak libraries..." "$logfile"
                filter_critical_system_libraries "$component/artifacts/lib" "lib"
            fi
            local need_to_ls="true"
        else
            log w "No top-level '$target' found in $WORK_DIR" "$logfile"
            local need_to_ls="true"
        fi
    done

    if [[ "$need_to_ls" == "true" ]]; then
        ls -lah "$WORK_DIR"
        need_to_ls="false"
    fi

    # Runtimes are disabled as they are managed in shared-libs
    # log i "Finding required runtimes for $flatpak_id..." "$logfile"
    # local runtimes
    # runtimes=$(flatpak info --user "$flatpak_id" | awk '/Runtime:/ {print $2} /Sdk:/ {print $2}')
    # log i "Found runtimes:\n$runtimes" "$logfile"

    # for runtime_id in $runtimes; do
    #     log i "Including runtime: $runtime_id" "$logfile"

    #     local runtime_name=$(echo "$runtime_id" | cut -d'/' -f1)
    #     local runtime_arch=$(echo "$runtime_id" | cut -d'/' -f2)
    #     local runtime_branch=$(echo "$runtime_id" | cut -d'/' -f3)

    #     local runtime_path="$HOME/.local/share/flatpak/runtime/$runtime_name/$runtime_arch/$runtime_branch/active/files"

    #     if [[ -d "$runtime_path" ]]; then
    #         log i "Copying runtime files for $runtime_id..." "$logfile"
    #         mkdir -p "$component/artifacts/runtimes/$runtime_id"
    #         cp -r "$runtime_path"/* "$component/artifacts/runtimes/$runtime_id/" || { log e "Copy failed" "$logfile"; exit 1; }
    #     else
    #         echo "[WARNING] Runtime path $runtime_path not found, skipping."
    #     fi
    # done

    # Clean up any now-empty directories left behind
    find "$WORK_DIR" -depth -type d -empty -delete

    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries

    # Uninstall the Flatpak if it was not previously installed
    if [[ "$was_installed" == "false" ]]; then
        log i "Uninstalling $flatpak_id as it was not previously installed." "$logfile"
        flatpak uninstall --user -y "$flatpak_id" || log w "Failed to uninstall $flatpak_id" "$logfile"
    fi
}

manage_flatpak_artifacts() {
    log d "Starting manage_flatpak_artifacts function" "$logfile"

    local temp_dir=$(mktemp -d)

    local filename=$(basename "$url")
    local extension="${filename##*.}"
    local output_path="$temp_dir/$filename"

    mkdir -p "$(dirname "$output_path")"

    safe_download "$url" "$output_path" "$component" || {
        log e "Failed to download Flatpak artifacts from $url" "$logfile"
        exit 1
    }

    if [[ ! -s "$output_path" ]]; then
        log e "Downloaded file is empty or missing: $output_path" "$logfile"
        exit 1
    fi

    # Attempt to extract version from the file if not provided
    if [[ -z "$version" ]]; then
        version_check "metainfo" "$component" "$output_path"
        if [[ -z "$version" ]]; then
            log w "Unable to extract version from $output_path, falling back to filename." "$logfile"
            version=$(basename "$url" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
            [[ -z "$version" ]] && version="unknown"
        fi
    fi

    mkdir -p "$WORK_DIR"
    tar -xf "$output_path" -C "$WORK_DIR" || {
        log e "Failed to extract Flatpak artifacts from $output_path" "$logfile"
        exit 1
    }

    # Copy directories and merge with existing content
    if [[ -d "$WORK_DIR/files/bin" ]]; then
        mkdir -p "$component/artifacts/bin"
        cp -rL "$WORK_DIR/files/bin/"* "$component/artifacts/bin/" 2>/dev/null || true
        log i "Copied bin directory contents to artifacts" "$logfile"
    fi
    
    if [[ -d "$WORK_DIR/files/lib" ]]; then
        mkdir -p "$component/artifacts/lib"
        cp -rL "$WORK_DIR/files/lib/"* "$component/artifacts/lib/" 2>/dev/null || true
        # Filter and set executable permissions for shared libraries
        log i "Filtering and setting permissions for Flatpak artifacts libraries..." "$logfile"
        filter_critical_system_libraries "$component/artifacts/lib" "lib"
        log i "Copied lib directory contents to artifacts" "$logfile"
    fi
    
    if [[ -d "$WORK_DIR/files/share" ]]; then
        mkdir -p "$component/artifacts/share"
        cp -rL "$WORK_DIR/files/share/"* "$component/artifacts/share/" 2>/dev/null || true
        log i "Copied share directory contents to artifacts" "$logfile"
    fi
    
    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries
    
    # Clean up temp directory
    rm -rf "$temp_dir"
}

manage_gh_latest_release() {
    log d "Starting manage_gh_latest_release function" "$logfile"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage latest GitHub release for $component from $url" "$logfile"
        return 0
    fi

    log i "Managing latest GitHub release for component: $component" "$logfile"

    # Parse url
    local repo asset_pattern
    if [[ "$url" == */*/* ]]; then
        repo="${url%/*}"
        asset_pattern="${url#*/*/}"
    else
        repo="$url"
        asset_pattern=""
    fi

    log d "Parsed repo: $repo" "$logfile"

    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local release_json

    log d "Fetching latest official release JSON from: $api_url" "$logfile"

    if [[ -n "$GITHUB_TOKEN" ]]; then
        release_json=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
    else
        release_json=$(curl -s "$api_url")
    fi

    if echo "$release_json" | grep -q "API rate limit exceeded"; then
        log e "GitHub API rate limit exceeded." "$logfile"
        exit 1
    fi

    if ! echo "$release_json" | jq empty >/dev/null 2>&1; then
        log e "Invalid JSON from GitHub API." "$logfile"
        exit 1
    fi

    # Convert wildcard pattern to regex
    local pattern_regex
    if [[ -n "$asset_pattern" ]]; then
        pattern_regex="${asset_pattern//\*/.*}"
        log d "Asset pattern provided: $asset_pattern" "$logfile"
        log d "Converted pattern to regex: $pattern_regex" "$logfile"
    else
        pattern_regex="$component"
    fi

    # Check assets in latest official release
    asset_url=$(echo "$release_json" | jq -r --arg pattern "$pattern_regex" '
        .assets[]? | select(.name | test($pattern; "i")) | .browser_download_url' | head -n 1)

    if [[ -z "$asset_url" ]]; then
        log w "No matching asset found in latest official release. Checking latest prerelease." "$logfile"
        # Fallback: check the latest prerelease
        local releases_api_url="https://api.github.com/repos/$repo/releases"
        local releases_json

        if [[ -n "$GITHUB_TOKEN" ]]; then
            releases_json=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$releases_api_url")
        else
            releases_json=$(curl -s "$releases_api_url")
        fi

        if echo "$releases_json" | grep -q "API rate limit exceeded"; then
            log e "GitHub API rate limit exceeded." "$logfile"
            exit 1
        fi

        # Find the first prerelease
        release_json=$(echo "$releases_json" | jq 'map(select(.prerelease == true)) | .[0]')

        if [[ -z "$release_json" || "$release_json" == "null" ]]; then
            log e "No prerelease found with matching asset either." "$logfile"
            exit 1
        fi

        # Try to find matching asset in prerelease
        asset_url=$(echo "$release_json" | jq -r --arg pattern "$pattern_regex" '
            .assets[]? | select(.name | test($pattern; "i")) | .browser_download_url' | head -n 1)

        if [[ -z "$asset_url" ]]; then
            log e "No matching asset found in latest prerelease either." "$logfile"
            exit 1
        fi

        log w "Using asset from latest prerelease!" "$logfile"
    fi

    log i "Downloading asset from: $asset_url" "$logfile"
    asset_filename=$(basename "$asset_url")
    asset_download_path="$WORK_DIR/$asset_filename"

    # safe_download does not support token yet
    if [[ -n "$GITHUB_TOKEN" ]]; then
        wget -qc --header="Authorization: token ${GITHUB_TOKEN}" "$asset_url" -O "$asset_download_path" || {
            log e "Failed to download asset." "$logfile"
            # If wget with token fails, try safe_download as fallback
            safe_download "$asset_url" "$asset_download_path" "$component" || {
                log e "Failed to download asset (even with fallback)." "$logfile"
                exit 1
            }
        }
    else
        safe_download "$asset_url" "$asset_download_path" "$component" || {
        log e "Failed to download asset (even with fallback)." "$logfile"
        exit 1
    }

    fi

    version_check "link" "$component" "$asset_url"

    extract_archive "$asset_download_path" "$WORK_DIR" || {
        log e "Failed to extract asset archive." "$logfile"
        exit 1
    }

    rm -f "$asset_download_path"
    mv "$WORK_DIR/"* "$component/artifacts/" || {
        log e "Failed to move extracted files to artifacts directory." "$logfile"
        exit 1
    }
    
    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries
}

manage_local() {
    log d "Starting manage_local function" "$logfile"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log i "[DRY-RUN] Would manage local file for $component from $url" "$logfile"
        return
    fi

    log i "Managing local file artifact for component: $component from $url" "$logfile"

    if [[ ! -f "$url" ]]; then
        log e "Local file not found: $url" "$logfile"
        exit 1
    fi

    # Check if it's an archive or a single file
    case "$url" in
        *.tar.gz|*.tar.bz2|*.tar.xz|*.tar|*.zip|*.7z)
            extract_archive "$url" "$WORK_DIR"
            ;;
        *)
            log i "No extraction needed, treating as single file." "$logfile"
            cp -L "$url" "$component/artifacts/" || {
                log e "Failed to copy local file to artifacts." "$logfile"
                exit 1
            }
            # Process required libraries for this component
            log i "Processing component-specific required libraries..." "$logfile"
            process_required_libraries
            return
            ;;
    esac

    log d "Moving extracted contents to $component/artifacts/" "$logfile"
    cp -rL "$WORK_DIR"/* "$component/artifacts/" || {
        log e "Failed to move extracted files to artifacts directory." "$logfile"
        exit 1
    }
    
    # Process required libraries for this component
    log i "Processing component-specific required libraries..." "$logfile"
    process_required_libraries
}

# Process required libraries automatically
process_required_libraries() {
    local required_libs_file="$component/required_libraries.txt"

    log i "🔍 Processing component-specific libraries for: $component" "$logfile"

    if [[ ! -f "$required_libs_file" ]]; then
        log d "No required_libraries.txt found for $component, skipping component-specific library processing" "$logfile"
        return 0
    fi
    
    log i "📖 Processing component-specific libraries from: $required_libs_file" "$logfile"
    
    # Source the search_libs function
    if [[ -f "automation-tools/search_libs.sh" ]]; then
        source "automation-tools/search_libs.sh"
    else
        log w "search_libs.sh not found, trying manual library processing" "$logfile"
        process_libraries_manual "$required_libs_file"
        return $?
    fi
    
    # Set up environment for search_libs
    export FLATPAK_DEST="$component/artifacts"
    
    # Create a temporary processed library file
    local temp_lib_file=$(mktemp)
    process_library_file "$required_libs_file" "$temp_lib_file"
    
    # Filter out critical system libraries before processing
    local filtered_lib_file=$(mktemp)
    filter_critical_system_libraries "$temp_lib_file" "list" "$filtered_lib_file"
    
    # Use search_libs to copy libraries
    if [[ -s "$filtered_lib_file" ]]; then
        log i "🔧 Using search_libs to copy component-specific libraries..." "$logfile"
        search_libs "$filtered_lib_file"
        
        # Apply post-copy filtering to remove any critical libs that slipped through
        if [[ -d "$component/artifacts/lib" ]]; then
            filter_critical_system_libraries "$component/artifacts/lib" "lib"
        fi
    else
        log i "No component-specific libraries to process after filtering" "$logfile"
    fi
    
    # Clean up
    rm -f "$temp_lib_file" "$filtered_lib_file"
}

# Process the library file to extract library names
process_library_file() {
    local input_file="$1"
    local output_file="$2"
    
    log d "📋 Processing component library file: $input_file" "$logfile"
    
    # Clear output file
    > "$output_file"
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Check if line looks like ldd output
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]=\>[[:space:]]*(not\ found|/.*)[[:space:]]*(\(.*\))?$ ]]; then
            # Extract library name from ldd output (standard format: name => path)
            local lib_name="${BASH_REMATCH[1]}"
            echo "$lib_name" >> "$output_file"
            log i "📚 Found library from ldd: $lib_name" "$logfile"
        elif [[ "$line" =~ ^[[:space:]]*(/[^[:space:]]+)[[:space:]]+(\(.*\))$ ]]; then
            # Extract library name from ldd output (dynamic linker format: /path (address))
            local lib_path="${BASH_REMATCH[1]}"
            local lib_name=$(basename "$lib_path")
            echo "$lib_name" >> "$output_file"
            log i "🔗 Found dynamic linker from ldd: $lib_name" "$logfile"
        elif [[ "$line" =~ ^[[:space:]]*([^[:space:]]+\.(so|so\.[0-9]+(\.[0-9]+)*)).*$ ]]; then
            # Direct library name
            local lib_name="${BASH_REMATCH[1]}"
            echo "$lib_name" >> "$output_file"
            log i "📚 Found library: $lib_name" "$logfile"
        elif [[ "$line" =~ ^[[:space:]]*plugins/ ]]; then
            # Plugin directory - pass through as is
            echo "$line" >> "$output_file"
            log i "🔌 Found plugin directory: $line" "$logfile"
        else
            # Unknown format, log warning but continue
            log w "❓ Unrecognized library format: $line" "$logfile"
        fi
    done < "$input_file"
    
    log d "✅ Processed component library file, output written to: $output_file" "$logfile"
}

# Fallback manual library processing if search_libs is not available
process_libraries_manual() {
    local required_libs_file="$1"
    local lib_dir="$component/artifacts/lib"
    
    log i "Performing manual library processing..." "$logfile"
    mkdir -p "$lib_dir"
    
    # Search only in local component and shared-libs directories, NOT on the host system
    local component_lib_dir="$(realpath -m "$component/lib" 2>/dev/null)"
    local shared_libs_dir="$(realpath -m "shared-libs" 2>/dev/null)"
    local search_paths=("$lib_dir" "$component_lib_dir" "$shared_libs_dir")
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Extract library name
        local lib_name=""
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]=\>[[:space:]]*not\ found ]]; then
            lib_name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*([^[:space:]]+\.(so|so\.[0-9]+(\.[0-9]+)*)).*$ ]]; then
            lib_name="${BASH_REMATCH[1]}"
        fi
        
        if [[ -n "$lib_name" ]]; then
            log i "Searching for library: $lib_name" "$logfile"
            local found=false
            
            for search_path in "${search_paths[@]}"; do
                local found_lib=$(find "$search_path" -name "$lib_name" -type f 2>/dev/null | head -n 1)
                if [[ -n "$found_lib" ]]; then
                    cp -L "$found_lib" "$lib_dir/"
                    # Set executable permissions for shared libraries
                    chmod +x "$lib_dir/$(basename "$found_lib")"
                    log i "✅ Copied $lib_name from $found_lib (with executable permissions)" "$logfile"
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == false ]]; then
                log w "❌ Library not found: $lib_name" "$logfile"
            fi
        fi
    done < "$required_libs_file"
    
    # Apply filtering to remove any critical libraries that were copied
    if [[ -d "$lib_dir" ]]; then
        filter_critical_system_libraries "$lib_dir" "lib"
    fi
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

    # Process --even directories/files if provided
    if [[ -n "${EVEN_DIRS[*]}" ]]; then
        log i "Processing --even directories/files..." "$logfile"
        for even_path in "${EVEN_DIRS[@]}"; do
            if [[ -e "$even_path" ]]; then
                log i "Adding --even path to artifacts: $even_path" "$logfile"
                if [[ -d "$even_path" ]]; then
                    cp -rL "$even_path" "$artifact_dir/" || {
                        log w "Failed to copy --even directory: $even_path" "$logfile"
                    }
                elif [[ -f "$even_path" ]]; then
                    cp -L "$even_path" "$artifact_dir/" || {
                        log w "Failed to copy --even file: $even_path" "$logfile"
                    }
                fi
            else
                log w "--even path does not exist: $even_path" "$logfile"
            fi
        done
    fi

    # Remove existing $component.tar.gz if present to avoid conflicts
    local tar_file="$artifact_dir/$component.tar.gz"
    if [[ -f "$tar_file" ]]; then
        log w "Existing archive $tar_file found, deleting before creating new one." "$logfile"
        rm -f "$tar_file"
    fi

        # Remove existing $component.tar.gz if present to avoid conflicts
    local sha_file="$artifact_dir/$component.tar.gz.sha"
    if [[ -f "$sha_file" ]]; then
        log w "Existing sha $sha_file found, deleting before creating new one." "$logfile"
        rm -f "$sha_file"
    fi

    # Inject standard component files if present
    log i "Injecting standard component files into artifact directory..." "$logfile"
    local inject_files=("component_launcher.sh" "component_manifest.json" "component_functions.sh" "component_prepare.sh" "rd_config")
    for file in "${inject_files[@]}"; do
        full_path="$component/$file"
        if [[ -f "$full_path" ]]; then
            cp "$full_path" "$artifact_dir"
            [[ "$file" == *.sh ]] && chmod +x "$artifact_dir/$(basename "$file")"
        elif [[ -d "$full_path" ]]; then
            cp -r "$full_path" "$artifact_dir"
        fi
    done
    # Copy version_file separately since it is already a full path
    if [[ -f "$version_file" ]]; then
        cp "$version_file" "$artifact_dir"
    fi

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

    log i "Cleaning up artifacts directory, keeping only archive and checksum..." "$logfile"
    find "$artifact_dir" -mindepth 1 -maxdepth 1 \
        ! -name "$(basename "$component.tar.gz")" \
        ! -name "$(basename "$component.tar.gz.sha")" \
        -exec rm -rf {} +

    log i "Finalization complete for $component" "$logfile"
}

write_components_version() {
    log d "Starting write_components_version function" "$logfile"

    log d "Initializing components version list file: $components_version_list" "$logfile"
    echo "# Components Version Summary" > "$components_version_list"
    echo "" >> "$components_version_list"

    local skip_api_requests=0

    local branch_name="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
    local match_label="cooker"
    [[ "$branch_name" == "main" ]] && match_label="main"

    for version_file in $(find "$REPO_ROOT" -type f -name "component_version"); do
        log d "Checking version file: $version_file..." "$logfile"
        if [[ ! -f "$version_file" ]]; then
            log w "Version file not found: $version_file, skipping..." "$logfile"
            continue
        fi
        local current_version
        current_version=$(< "$version_file")
        log d "Version file contents: $current_version" "$logfile"

        local component_name
        component_name=$(basename "$(dirname "$version_file")")
        local update_date
        update_date=$(date -r "$version_file" +"%Y-%m-%d")

        log d "Processing component: $component_name, version: $current_version, last updated: $update_date" "$logfile"

        local version_url=""
        local old_version=""

        if [[ $skip_api_requests -eq 1 ]]; then
            log w "Skipping API requests due to earlier rate-limit warning." "$logfile"
        else
            local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases"
            log d "Using GitHub API URL: $api_url" "$logfile"

            local releases_json
            if [[ -n "$GITHUB_TOKEN" ]]; then
                releases_json=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
            else
                releases_json=$(curl -s "$api_url")
            fi

            # Check if response is an error object
            if echo "$releases_json" | jq -e 'if type == "object" then . else empty end' >/dev/null; then
                local error_message
                error_message=$(echo "$releases_json" | jq -r '.message // empty')

                if [[ "$error_message" == *"API rate limit exceeded"* ]]; then
                    log e "GitHub API rate limit exceeded! Further API requests will be skipped." "$logfile"
                    skip_api_requests=1
                else
                    log w "GitHub API error for $component_name: $error_message" "$logfile"
                fi
            else
                # Validate: must be an array
                if echo "$releases_json" | jq -e 'if type == "array" then . else empty end' >/dev/null; then
                    version_url=$(echo "$releases_json" | jq -r --arg label "$match_label" '
                        .[]
                        | select(.tag_name | test($label))
                        | .assets[]?
                        | select(.name == "component_version")
                        | .browser_download_url' | head -n 1)
                else
                    log w "Unexpected API response for $component_name. Skipping API fetch." "$logfile"
                fi
            fi
        fi

        if [[ -n "$version_url" ]]; then
            log d "Fetching previous version from: $version_url" "$logfile"
            old_version=$(curl -s "$version_url")
        else
            log w "Previous version for $component_name not found in releases matching '$match_label' or skipped." "$logfile"
        fi

        if [[ $safe_download_warning == "true" ]]; then
            echo -e "**$component_name**: $current_version (WARNING: URI was unreachable, used latest available version)\n" >> "$components_version_list"
        fi

        if [[ -n "$old_version" && "$old_version" != "$current_version" ]]; then
            echo -e "**$component_name**: $current_version (was $old_version, grabbed on $update_date)\n" >> "$components_version_list"
        else
            echo -e "**$component_name**: $current_version (grabbed on $update_date)\n" >> "$components_version_list"
        fi
    done
}

version_check() {

    # usage: version_check <check_type> <component> <source>
    # check_type: manual|link|file|metainfo
    # component: name of the component being checked
    # source: URL, file path, or metainfo XML file

    log d "Starting version_check function" "$logfile"

    local check_type="$1"
    local component="$2"
    local source="$3"

    local current_version=""
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
        extracted_version="latest on $(date +%Y-%m-%d)"
    fi

    export version="$extracted_version"
    log i "Detected version: $version" "$logfile"

    if [[ -f "$version_file" ]]; then
        current_version=$(< "$version_file")
        if [[ "$current_version" == "$version" && "$FORCE" -ne 1 ]]; then
            log i "Version check passed: $version (same as previous), continuing to generate artifact." "$logfile"
        fi
    fi

    if [[ "$FORCE" -eq 1 || "$current_version" != "$version" ]]; then
        echo "$version" > "$version_file"
        log i "Version file updated: $version_file with version $version" "$logfile"
    fi

    return 1
}

extract_archive() {
    local archive="$1"
    local dest_dir="$2"

    if [[ ! -f "$archive" ]]; then
        log e "Archive not found: $archive" "$logfile"
        return 1
    fi

    log i "Extracting archive: $archive -> $dest_dir" "$logfile"

    # Extract based on file extension
    case "$archive" in
        *.tar.gz|*.tar.bz2|*.tar.xz|*.tar)
            tar -xf "$archive" -C "$dest_dir" || {
                log e "Failed to extract tar archive: $archive" "$logfile"
                return 1
            }
            ;;
        *.zip)
            unzip -q "$archive" -d "$dest_dir" || {
                log e "Failed to extract zip archive: $archive" "$logfile"
                return 1
            }
            ;;
        *.7z)
            7z x -y "$archive" -o"$dest_dir" > /dev/null || {
                log e "Failed to extract 7z archive: $archive" "$logfile"
                return 1
            }
            ;;
        *)
            log w "Unsupported archive format: $archive" "$logfile"
            return 1
            ;;
    esac

    # Remove the original archive after extraction
    rm -f "$archive"

    # Recursively check for nested archives
    find "$dest_dir" -type f \( \
        -iname "*.tar.gz" -o -iname "*.tar.bz2" -o -iname "*.tar.xz" -o -iname "*.tar" \
        -o -iname "*.zip" -o -iname "*.7z" \) | while read -r nested_archive; do
            log i "Found nested archive: $nested_archive — extracting recursively." "$logfile"
            local nested_dir
            nested_dir=$(dirname "$nested_archive")
            extract_archive "$nested_archive" "$nested_dir"
    done
}

