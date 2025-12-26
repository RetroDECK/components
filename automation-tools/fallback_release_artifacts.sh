#!/usr/bin/env bash

set -euo pipefail

# Fallback logic:
# - For each component missing artifacts, try to download its latest available artifact from GitHub Releases.
# - Search releases from newest to oldest and stop at the first match.
# - Intended to be used ONLY for non-main branches (workflow should gate this).

log() {
  local level="$1"; shift
  echo "[$level] $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log ERROR "Missing required command: $1"
    exit 1
  }
}

require_cmd curl
require_cmd jq

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required (e.g. RetroDECK/components)}"

# Prefer an explicit token if provided; else unauthenticated requests.
AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

# Label used to select releases (default: cooker). Keep aligned with workflow tagging.
MATCH_LABEL="${MATCH_LABEL:-cooker}"

FALLBACK_OUT_FILE="${FALLBACK_COMPONENTS_FILE:-fallback_components.txt}"
MISSING_OUT_FILE="${MISSING_COMPONENTS_FILE:-missing_components.txt}"

cd "$REPO_ROOT"

detect_missing_components() {
  local missing=()
  while IFS= read -r folder; do
    [[ -z "$folder" ]] && continue
    if [[ ! -d "$folder" ]]; then
      continue
    fi

    # Only treat directories as components if they have a component recipe/manifest.
    if [[ ! -f "$folder/component_recipe.json" && ! -f "$folder/component_manifest.json" ]]; then
      continue
    fi

    # Must have at least one artifact file to be considered present
    if [[ ! -d "$folder/artifacts" ]] || ! find "$folder/artifacts" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.zip" -o -name "*.gz" -o -name "*.tar" -o -name "*.7z" -o -name "*.appimage" \) | grep -q .; then
      missing+=("$folder")
    fi
  done < <(find . -maxdepth 1 -mindepth 1 -type d -not -name '.*' -exec basename {} \;)

  printf '%s\n' "${missing[@]:-}"
}

fetch_releases_page() {
  local page="$1"
  local url="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases?per_page=100&page=${page}"
  curl -fsSL "${AUTH_HEADER[@]}" "$url"
}

find_asset_in_releases() {
  local releases_json="$1"
  local component="$2"
  local asset_name="$3"

  # Return a TSV line: <tag_name>\t<download_url> for the FIRST match
  jq -r --arg label "$MATCH_LABEL" --arg name "$asset_name" '
    .[]
    | select(.tag_name | test($label))
    | . as $rel
    | ($rel.assets // [])[]?
    | select(.name == $name)
    | [$rel.tag_name, .browser_download_url]
    | @tsv
  ' <<<"$releases_json" | head -n 1
}

download_asset() {
  local url="$1"
  local out="$2"
  mkdir -p "$(dirname "$out")"
  curl -fL "${AUTH_HEADER[@]}" -o "$out" "$url"
}

main() {
  : >"$FALLBACK_OUT_FILE"
  : >"$MISSING_OUT_FILE"

  mapfile -t missing_components < <(detect_missing_components)
  if [[ ${#missing_components[@]} -eq 0 ]]; then
    log INFO "No missing components detected."
    return 0
  fi

  log WARN "Missing components detected: ${missing_components[*]}"
  printf '%s\n' "${missing_components[@]}" >"$MISSING_OUT_FILE"

  for component in "${missing_components[@]}"; do
    local_tar_name="${component}.tar.gz"
    local_sha_name="${component}.tar.gz.sha"

    found_tag=""
    url_tar=""
    url_sha=""

    for page in 1 2 3 4 5; do
      releases_json=""
      if ! releases_json=$(fetch_releases_page "$page" 2>/dev/null); then
        log WARN "Failed to fetch releases page ${page}; continuing..."
        continue
      fi

      # Stop if API returned an empty array
      if [[ "$(jq -r 'length' <<<"$releases_json")" == "0" ]]; then
        break
      fi

      tar_match=$(find_asset_in_releases "$releases_json" "$component" "$local_tar_name" || true)
      sha_match=$(find_asset_in_releases "$releases_json" "$component" "$local_sha_name" || true)

      if [[ -n "$tar_match" ]]; then
        found_tag=$(cut -f1 <<<"$tar_match")
        url_tar=$(cut -f2 <<<"$tar_match")
      fi
      if [[ -n "$sha_match" ]]; then
        # Prefer the tag from tar_match if present; else from sha_match
        [[ -z "$found_tag" ]] && found_tag=$(cut -f1 <<<"$sha_match")
        url_sha=$(cut -f2 <<<"$sha_match")
      fi

      if [[ -n "$url_tar" ]]; then
        break
      fi
    done

    if [[ -z "$url_tar" ]]; then
      log ERROR "Fallback not found for component '$component' (searched releases matching '${MATCH_LABEL}')."
      continue
    fi

    log WARN "Using fallback for '$component' from release '$found_tag'"
    download_asset "$url_tar" "$REPO_ROOT/$component/artifacts/$local_tar_name"
    if [[ -n "$url_sha" ]]; then
      download_asset "$url_sha" "$REPO_ROOT/$component/artifacts/$local_sha_name"
    fi

    echo "${component}|${found_tag}" >>"$FALLBACK_OUT_FILE"
  done

  if [[ -s "$FALLBACK_OUT_FILE" ]]; then
    log INFO "Fallback used for: $(cut -d'|' -f1 "$FALLBACK_OUT_FILE" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  else
    log INFO "No fallback artifacts were recovered."
  fi
}

main "$@"
