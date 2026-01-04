#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -f <components_version_list.md> -c <component_name>" >&2
}

file=""
component=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      file="$2"; shift 2;;
    -c|--component)
      component="$2"; shift 2;;
    *)
      usage; exit 2;;
  esac
done

if [[ -z "${file}" || -z "${component}" ]]; then
  usage
  exit 2
fi

if [[ ! -f "$file" ]]; then
  echo "[ERROR] File not found: $file" >&2
  exit 1
fi

# Parse markdown table rows of the form:
# | Component | Version | Built at (UTC) |
# | name | version | timestamp |
# Component name may be prefixed with "⚠️ ".

awk -v want="$component" -F'|' '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  /^[|]/ {
    name = trim($2)
    ver  = trim($3)
    if (name ~ /^⚠️[[:space:]]+/) sub(/^⚠️[[:space:]]+/, "", name)
    if (name == want) { print ver; found=1; exit }
  }
  END { if (!found) exit 3 }
' "$file"
