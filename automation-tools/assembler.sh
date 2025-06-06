# NOTE: be aware that WORK_DIR is a disposable directory, so you should not use it to store any data that you want to keep after the script ends, that is going in $component/artifacts

# TODO: create a proper function to handle archives instead of repeating the same code in each component

#!/bin/bash

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

export logfile="$(realpath assemble.log)"

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
GITHUB_REPO=$(git config --get remote.origin.url | sed -E 's|.*github.com[:/](.*)\.git|\1|')
# Fix GITHUB_REPO if it mistakenly has the full URL
if [[ "$GITHUB_REPO" == https://github.com/* ]]; then
  GITHUB_REPO="${GITHUB_REPO#https://github.com/}"
fi
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
EXTRAS="rd_extras"      # Name of the extras folder used to place components extras such as free bioses, cheats files and such
components_version_list="components_version_list.md"
export component="${args[2]:-$(basename "$(dirname "$(realpath "${BASH_SOURCE[1]}")")")}"
export version_file="$component/component_version"

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
        gh_latest_release)
            manage_gh_latest_release
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

    # Extract to WORK_DIR
    case "$output_path" in
        *.tar.gz|*.tar.bz2|*.tar.xz)
            tar -xf "$output_path" -C "$WORK_DIR" || {
                log e "Failed to extract tar archive: $output_path" "$logfile"
                exit 1
            }
            ;;
        *.zip)
            unzip -q "$output_path" -d "$WORK_DIR" || {
                log e "Failed to extract zip archive: $output_path" "$logfile"
                exit 1
            }
            ;;
        *.7z)
            7z x -y "$output_path" -o"$WORK_DIR" > /dev/null || {
                log e "Failed to extract 7z archive: $output_path" "$logfile"
                exit 1
            }
            ;;
        *)
            tar -xf "$output_path" -C "$WORK_DIR" || {
                log e "Failed to extract generic artifact: $output_path" "$logfile"
                exit 1
            }
            ;;
    esac

    rm -f "$output_path" # Remove the original archive to save space

    # Move extracted files into artifacts dir
    log d "Moving extracted contents to $component/artifacts/" "$logfile"
    cp -rL "$WORK_DIR"/* "$component/artifacts/" || {
        log e "Failed to move extracted files to artifacts." "$logfile"
        exit 1
    }
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
            local need_to_ls="true"
            }
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

    mv "$WORK_DIR/files/bin/" "$component/artifacts/"
    mv "$WORK_DIR/files/lib/" "$component/artifacts/"
    mv "$WORK_DIR/files/share/" "$component/artifacts/"
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

    if [[ -n "$GITHUB_TOKEN" ]]; then
        wget -qc --header="Authorization: token ${GITHUB_TOKEN}" "$asset_url" -O "$asset_download_path" || {
            log e "Failed to download asset." "$logfile"
            exit 1
        }
    else
        wget -qc "$asset_url" -O "$asset_download_path" || {
            log e "Failed to download asset." "$logfile"
            exit 1
        }
    fi

    version_check "link" "$component" "$asset_url"

    case "$asset_download_path" in
        *.tar.gz|*.tar.bz2|*.tar.xz|*.tar)
            tar -xf "$asset_download_path" -C "$WORK_DIR" || {
                log e "Failed to extract asset (tar)." "$logfile"
                exit 1
            }
            ;;
        *.zip)
            unzip -q "$asset_download_path" -d "$WORK_DIR" || {
                log e "Failed to extract asset (zip)." "$logfile"
                exit 1
            }
            ;;
        *.7z)
            7z x -y "$asset_download_path" -o"$WORK_DIR" > /dev/null || {
                log e "Failed to extract asset (7z)." "$logfile"
                exit 1
            }
            ;;
        *)
            log e "Unsupported archive format for $asset_download_path" "$logfile"
            exit 1
            ;;
    esac

    rm -f "$asset_download_path"
    mv "$WORK_DIR/"* "$component/artifacts/" || {
        log e "Failed to move extracted files to artifacts directory." "$logfile"
        exit 1
    }
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
    local inject_files=("component_launcher.sh" "component_manifest.json" "component_functions.sh" "component_prepare.sh" "rd_config")
    for file in "${inject_files[@]}"; do
        full_path="$component/$file"
        if [[ -f "$full_path" ]]; then
            cp "$full_path" "$artifact_dir"
            [[ "$file" == *.sh ]] && chmod +x "$artifact_dir/$(basename "$file")"
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

