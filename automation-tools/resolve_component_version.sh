#!/usr/bin/env bash
set -euo pipefail

# Resolve the concrete version that will be used by a component recipe.
# This avoids relying on "latest" tags and mirrors the resolvers used by the downloaders.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ALCHEMIST_DIR="$REPO_ROOT/automation-tools/alchemist"

# Some alchemist libs expect SCRIPT_DIR and defaults.
export SCRIPT_DIR="$ALCHEMIST_DIR"

source "$ALCHEMIST_DIR/lib/defaults.sh"

source "$ALCHEMIST_DIR/lib/tools/flatpak_api.sh"
source "$ALCHEMIST_DIR/lib/tools/git_api.sh"
source "$ALCHEMIST_DIR/lib/tools/github_api.sh"
source "$ALCHEMIST_DIR/lib/tools/gitlab_api.sh"

# some libs expect a log() function
log() { :; }

usage() {
  echo "Usage: $0 -r <component_recipe.json> [-v <desired_versions.sh>]" >&2
}

recipe=""
versions_file="$ALCHEMIST_DIR/desired_versions.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--recipe)
      recipe="$2"; shift 2;;
    -v|--versions)
      versions_file="$2"; shift 2;;
    *)
      usage; exit 2;;
  esac
done

if [[ -z "$recipe" ]]; then
  usage
  exit 2
fi

if [[ ! -f "$recipe" ]]; then
  echo "[ERROR] Recipe not found: $recipe" >&2
  exit 1
fi

if [[ ! -f "$versions_file" ]]; then
  echo "[ERROR] Versions file not found: $versions_file" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$versions_file"

component_name=$(jq -r 'keys[0]' "$recipe")
source_type=$(jq -r --arg c "$component_name" '.[$c][0].source_type' "$recipe")
source_url=$(jq -r --arg c "$component_name" '.[$c][0].source_url' "$recipe" | envsubst)
version=$(jq -r --arg c "$component_name" '.[$c][0].version // empty' "$recipe" | envsubst)

if [[ -z "$version" ]]; then
  exit 3
fi

case "$source_type" in
  http|local)
    echo "$version"; exit 0;;

  flatpak_id|flatpak-id)
    if [[ "$version" == "latest" ]]; then
      resolved=$(get_latest_flatpak_release_version "$source_url" || true)
      [[ "$resolved" == "null" ]] && resolved=""
      if [[ -n "$resolved" ]]; then
        echo "$resolved"; exit 0
      fi
    fi
    echo "$version"; exit 0;;

  github_release|github-release)
    read -r owner repo <<< "$(parse_github_url "$source_url")"
    resolved=""
    if [[ "$version" == "latest" ]]; then
      resolved=$(get_latest_github_release_version "$owner" "$repo" || true)
    elif [[ "$version" == "newest" ]]; then
      resolved=$(get_newest_github_release_version "$owner" "$repo" || true)
    fi
    [[ "$resolved" == "null" ]] && resolved=""
    if [[ -n "$resolved" ]]; then
      echo "$resolved"; exit 0
    fi
    echo "$version"; exit 0;;

  gitlab_release|gitlab-release)
    read -r instance owner repo <<< "$(parse_gitlab_url "$source_url")"
    resolved=""
    if [[ "$version" == "latest" ]]; then
      resolved=$(get_latest_gitlab_release_version "$instance" "$owner" "$repo" || true)
    elif [[ "$version" == "newest" ]]; then
      resolved=$(get_newest_gitlab_release_version "$instance" "$owner" "$repo" || true)
    fi
    [[ "$resolved" == "null" ]] && resolved=""
    if [[ -n "$resolved" ]]; then
      echo "$resolved"; exit 0
    fi
    echo "$version"; exit 0;;

  git)
    read -r owner repo <<< "$(parse_github_url "$source_url")"
    if [[ "$version" == "latest" ]]; then
      resolved=$(get_latest_git_commit_version "$owner" "$repo" || true)
      [[ "$resolved" == "null" ]] && resolved=""
      if [[ -n "$resolved" ]]; then
        echo "$resolved"; exit 0
      fi
    fi
    echo "$version"; exit 0;;

  *)
    echo "$version"; exit 0;;
esac
