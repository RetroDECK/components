#!/bin/bash

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

write_components_version() {
    log d "Starting write_components_version function" "$logfile"

    log d "Initializing components version list file: $components_version_list" "$logfile"
    echo "# Components Version Summary" > "$components_version_list"
    echo "" >> "$components_version_list"

    local skip_api_requests=0

    local branch_name="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
    local match_label="cooker"
    [[ "$branch_name" == "main" ]] && match_label="main"

    # Iterate over immediate child directories of REPO_ROOT so we can
    # report components even when the component_version file is missing.
    while IFS= read -r -d '' component_dir; do
        local version_file="$component_dir/component_version"
        log d "Checking component directory: $component_dir (version file: $version_file)" "$logfile"

        local current_version
        if [[ -f "$version_file" ]]; then
            current_version=$(< "$version_file")
            log d "Version file contents: $current_version" "$logfile"
            update_date=$(date -r "$version_file" +"%Y-%m-%d")
        else
            # Default to "unknown" when the component_version file is absent
            current_version="unknown"
            log w "Version file not found for component at: $component_dir, using default: $current_version" "$logfile"
            # Fall back to directory modification time if available
            update_date=$(date -r "$component_dir" +"%Y-%m-%d" 2>/dev/null || echo "N/A")
        fi

        local component_name
        component_name=$(basename "$component_dir")

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
    done < <(find "$REPO_ROOT" -mindepth 1 -maxdepth 1 -type d -print0)
}