#!/usr/bin/env bash
set -euo pipefail

# Finds the newest (most recently published) non-draft release whose tag starts with "cooker-"
# and (optionally) contains a given asset name.
#
# Outputs the tag to stdout.

ASSET_NAME="${ASSET_NAME:-components_version_list.md}"
REPO="${GITHUB_REPOSITORY:-}"
TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$REPO" ]]; then
  echo "[ERROR] GITHUB_REPOSITORY is required (e.g. RetroDECK/components)" >&2
  exit 1
fi

api_url="https://api.github.com/repos/$REPO/releases?per_page=100"

headers=("-H" "Accept: application/vnd.github+json")
if [[ -n "$TOKEN" ]]; then
  headers+=("-H" "Authorization: token $TOKEN")
fi

json=$(curl -fsSL "${headers[@]}" "$api_url")

tag=$(echo "$json" | jq -r --arg asset "$ASSET_NAME" '
  map(select(.draft == false))
  | map(select(.tag_name | startswith("cooker-")))
  | map(select((.assets // []) | any(.name == $asset)))
  | sort_by(.published_at // .created_at)
  | reverse
  | .[0].tag_name // empty
')

if [[ -z "$tag" ]]; then
  # If we didn't find the asset, still try to return newest cooker tag (best-effort)
  tag=$(echo "$json" | jq -r '
    map(select(.draft == false))
    | map(select(.tag_name | startswith("cooker-")))
    | sort_by(.published_at // .created_at)
    | reverse
    | .[0].tag_name // empty
  ')
fi

echo "$tag"
