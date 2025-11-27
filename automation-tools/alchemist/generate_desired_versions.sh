#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

source "$SCRIPT_DIR/lib/tools/flatpak_api.sh"
source "$SCRIPT_DIR/lib/tools/git_api.sh"
source "$SCRIPT_DIR/lib/tools/github_api.sh"
source "$SCRIPT_DIR/lib/tools/gitlab_api.sh"
source "$SCRIPT_DIR/lib/tools/url_resolver.sh"
source "$SCRIPT_DIR/lib/defaults.sh"

generated_desired_version_file="$SCRIPT_DIR/desired_versions_$(date +%Y_%m_%d).sh"

log() {
  echo "[$1] $2" >&2
}

generate_desired_versions() {
  cp -f "$1" "$generated_desired_version_file"
  source "$1"

  while read -r file; do
    local response=""
    local extracted_version=""
    local component_name="$(basename $(dirname "$file"))"
    local component_source_url="$(jq -r '.[].[0].source_url' "$file")"
    local component_source_type="$(jq -r '.[].[0].source_type' "$file")"
    local component_version="$(jq -r '.[].[0].version//empty' "$file" | envsubst)"

    if [[ ! -n "$component_version" ]]; then
      echo "Component \"$component_name\" does not have a version key, skipping..."
      continue
    fi

    # Sanitize component_name
    component_name="${component_name//-/_}"
    # Uppercase component_name
    component_name="${component_name^^}"

    case "$component_source_type" in
      "http" )
        log info "HTTP source version \"$component_version\" found for component \"$component_name\""
        extracted_version="$component_version"
      ;;
      "local" )
        log info "Local source version \"$component_version\" found for component \"$component_name\""
        extracted_version="$component_version"
      ;;
      "flatpak_id" | "flatpak-id" )
        if [[ "$component_version" == "latest" ]]; then
          response=$(get_latest_flatpak_release_version "$component_source_url")
        fi
        if [[ -n "$response" ]]; then
          log info "Flatpak source version \"$response\" found for component \"$component_name\""
          extracted_version="$response"
        else
          log info "Component \"$component_name\" not using \"latest\" version, retaining current value \"$component_version\"."
          extracted_version="$component_version"
        fi
      ;;
      "github_release" | "github-release" )
        local owner repo
        read -r owner repo <<< "$(parse_github_url "$component_source_url")"

        if [[ "$component_version" == "latest" ]]; then
          response=$(get_latest_github_release_version "$owner" "$repo")
        elif [[ "$component_version" == "newest" ]]; then
          response=$(get_newest_github_release_version "$owner" "$repo")
        fi
        if [[ -n "$response" ]]; then
          log info "GitHub release source version \"$response\" found for component \"$component_name\""
          extracted_version="$response"
        else
          log info "Component \"$component_name\" not using \"latest\" or \"newest\" version, retaining current value \"$component_version\"."
          extracted_version="$component_version"
        fi
      ;;
      "gitlab_release" | "gitlab-release" )
        local instance owner repo
        read -r instance owner repo <<< "$(parse_gitlab_url "$component_source_url")"

        if [[ "$component_version" == "latest" ]]; then
          response=$(get_latest_github_release_version "$instance" "$owner" "$repo")
        elif [[ "$component_version" == "newest" ]]; then
          response=$(get_newest_github_release_version "$instance" "$owner" "$repo")
        fi
        if [[ -n "$response" ]]; then
          log info "GitHub release source version \"$response\" found for component \"$component_name\""
          extracted_version="$response"
        else
          log info "Component \"$component_name\" not using \"latest\" or \"newest\" version, retaining current value \"$component_version\"."
          extracted_version="$component_version"
        fi
      ;;
      "git" )
        local owner repo
        read -r owner repo <<< "$(parse_github_url "$component_source_url")"

        if [[ "$component_version" == "latest" ]]; then
          response=$(get_latest_git_commit_version "$owner" "$repo")
        fi
        if [[ -n "$response" ]]; then
          log info "Git source version \"$response\" found for component \"$component_name\""
          extracted_version="$response"
        else
          log info "Component \"$component_name\" not using \"latest\" version, retaining current value \"$component_version\"."
          extracted_version="$component_version"
        fi
      ;;
      * )
        log error "Unknown component source type: $component_source_type. Skipping..."
      ;;
    esac

    sed -i "s/^export ${component_name}_DESIRED_VERSION=.*/export ${component_name}_DESIRED_VERSION=\"${extracted_version}\"/" "$generated_desired_version_file"

  done < <(find "$PWD" -maxdepth 2 -type f -name "component_recipe.json" -not -path "$PWD/framework/component_recipe.json")
}

parse_args() {
  local original_version_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        original_version_file="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$original_version_file" ]]; then
    log error "Missing required arguments: -f <versions file>"
    return 1
  fi

  generate_desired_versions "$original_version_file"
}

parse_args "$@"