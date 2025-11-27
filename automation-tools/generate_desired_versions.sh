#!/bin/bash

desired_version_file="./desired_versions_$(date +%Y_%m_%d).sh"

log() {
  echo "[$1] $2" >&2
}

resolve_latest_github_release_version() {
  local url="$1"

  url="${url%.git}"

  if [[ "$url" =~ github\.com[/:]([^/]+)/([^/#?]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
  fi

  local api_url="https://api.github.com/repos/$owner/$repo/releases/latest"
  local response
  response=$(curl -sS "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for $owner/$repo"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r '.tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse latest version from GitHub API response"
    return 1
  fi

  echo "$version"
  return 0
}

resolve_newest_github_release_version() {
  local url="$1"

  url="${url%.git}"

  if [[ "$url" =~ github\.com[/:]([^/]+)/([^/#?]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
  fi

  local api_url="https://api.github.com/repos/$owner/$repo/releases"
  local response
  response=$(curl -sS "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch newest release for $owner/$repo"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r 'sort_by(.published_at) | reverse | .[0].tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse newest version from GitHub API response"
    return 1
  fi

  echo "$version"
  return 0
}

resolve_git_version() {
  local url="$1"

  url="${url%.git}"

  local owner="${BASH_REMATCH[1]}"
  local repo="${BASH_REMATCH[2]}"

  local response
  response=$(curl -s "https://api.github.com/repos/$owner/$repo/commits/HEAD" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r '.sha')

  if [[ -z "$version" ]]; then
    return 1
  fi

  echo "$version"
  return 0
}

resolve_flatpak_version() {
  local flatpak_id="$1"

  local response
  response=$(flatpak remote-info --user flathub "$flatpak_id" 2>&1)
  local flatpak_cmd_exit=$?

  if [[ "$flatpak_cmd_exit" -ne 0 ]]; then
    return 1
  fi

  local version
  version=$(echo "$response" | grep -E 'Commit:|Incheckning:' | awk '{print $2}')

  if [[ -z "$version" ]]; then
    return 1
  fi

  echo "$version"
  return 0
}

generate_desired_versions() {
  # Default file intro
  echo '#!/bin/bash' > "$desired_version_file"
  echo >> "$desired_version_file"
  echo '# Defaults for runtime desired versions' >> "$desired_version_file"
  echo 'export DESIRED_QT6_RUNTIME_VERSION="6.10"' >> "$desired_version_file"
  echo 'export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"' >> "$desired_version_file"
  echo >> "$desired_version_file"
  echo '# Defaults for component source desired versions' >> "$desired_version_file"

  while read -r file; do
    local response=""
    local component_name="$(basename $(dirname "$file"))"
    local component_source_url="$(jq -r '.[].[0].source_url' "$file")"
    local component_source_type="$(jq -r '.[].[0].source_type' "$file")"
    local component_version="$(jq -r '.[].[0].version//empty' "$file" | envsubst)"

    if [[ ! -n "$component_version" ]]; then
      echo "Component \"$component_name\" does not have a version key, skipping..."
      continue
    fi

    if [[ ! "$component_name" == "framework" ]]; then
      # Sanitize component_name
      component_name="${component_name//-/_}"
      # Uppercase component_name
      component_name="${component_name^^}"

      case "$component_source_type" in
        "http")
          log info "HTTP source version \"$component_version\" found for component \"$component_name\""
          echo "export ${component_name}_DESIRED_VERSION=\"$component_version\"" >> "$desired_version_file"
        ;;
        "local")
          log error "Local source version \"$component_version\" found for component \"$component_name\""
          echo "export ${component_name}_DESIRED_VERSION=\"$component_version\"" >> "$desired_version_file"
        ;;
        "flatpak_id")
          response=$(resolve_flatpak_version "$component_source_url")
          if [[ -n "$response" ]]; then
            log info "Flatpak source version \"$response\" found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"$response\"" >> "$desired_version_file"
          else
            log error "Flatpak source version could not be found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"UNKNOWN\"" >> "$desired_version_file"
          fi
        ;;
        "github_release")
          if [[ "$component_version" == "latest" ]]; then
            response=$(resolve_latest_github_release_version "$component_source_url")
          elif [[ "$component_version" == "newest" ]]; then
            response=$(resolve_newest_github_release_version "$component_source_url")
          else
            response="$component_version"
          fi
          if [[ -n "$response" ]]; then
            log info "GitHub release source version \"$response\" found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"$response\"" >> "$desired_version_file"
          else
            log error "GitHub release source version could not be found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"UNKNOWN\"" >> "$desired_version_file"
          fi
        ;;
        "git")
          response=$(resolve_git_version "$component_source_url")
          if [[ -n "$response" ]]; then
            log info "Git source version \"$response\" found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"$response\"" >> "$desired_version_file"
          else
            log error "Git source version could not be found for component \"$component_name\""
            echo "export ${component_name}_DESIRED_VERSION=\"UNKNOWN\"" >> "$desired_version_file"
          fi
        ;;
        *)
          log error "Unknown component source type: $component_source_type. Skipping..."
        ;;
      esac
    fi

  done < <(find "$(realpath .)" -maxdepth 2 -type f -name "component_recipe.json")

  # Default file outro
  echo >> "$desired_version_file"
  echo '# Framework component desired versions' >> "$desired_version_file"
  echo 'if [[ "${GITHUB_REF_NAME:-}" != "main" ]]; then' >> "$desired_version_file"
  echo '    export FRAMEWORK_DESIRED_VERSION="cooker-latest on $(date +%Y-%m-%d)"' >> "$desired_version_file"
  echo 'else' >> "$desired_version_file"
  echo '    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"' >> "$desired_version_file"
  echo 'fi' >> "$desired_version_file"
}

parse_args() {
  local version_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        version_file="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$version_file" ]]; then
    log error "Missing required arguments: -f <versions file>"
    return 1
  fi

  source "$version_file"

  generate_desired_versions
}

parse_args "$@"