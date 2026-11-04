#!/bin/bash

export retroverse_data="$XDG_CONFIG_HOME/retroverse"

#########################################
# Helpers
#########################################

get_client_schema::retroverse() {
  # Print the client schema version declared in this component's manifest
  # USAGE: get_client_schema::retroverse

  local schema
  schema=$(jq -r '.[] | .manifest | select(has("retroverse")) | .retroverse.client_schema_version // empty' "$component_manifest_cache_file")
  if [[ ! "$schema" =~ ^[0-9]+$ ]]; then
    log e "RetroVERSE client_schema_version is missing or not an integer in the component manifest"
    return 1
  fi
  printf '%s' "$schema"
}

get_supported_store_schema::retroverse() {
  # Print the highest store schema version this client can read, from this component's manifest
  # USAGE: get_supported_store_schema::retroverse

  local schema
  schema=$(jq -r '.[] | .manifest | select(has("retroverse")) | .retroverse.store_schema_version // empty' "$component_manifest_cache_file")
  if [[ ! "$schema" =~ ^[0-9]+$ ]]; then
    log e "RetroVERSE store_schema_version is missing or not an integer in the component manifest"
    return 1
  fi
  printf '%s' "$schema"
}

get_source_repo::retroverse() {
  # Print the GitHub owner/repo for a configured store source.
  # USAGE: get_source_repo::retroverse "$source_id"

  local source_id="$1"
  local repo
  repo=$(jq -r --arg source "$source_id" '.[] | .manifest | select(has("retroverse")) | .retroverse.sources[$source].repo // empty' "$component_manifest_cache_file")
  if [[ -z "$repo" ]]; then
    log e "No RetroVERSE source named $source_id is configured"
    return 1
  fi
  printf '%s' "$repo"
}

resolve_path::retroverse() {
  # Resolve $name and ${name} tokens anywhere in a path, failing on any unset or empty variable or malformed token
  # The result must be an absolute path. It is written to the named variable; nothing is written on failure.
  # USAGE: resolve_path::retroverse "$path" "$output_variable_name"

  local rv_input="$1"
  local -n rv_resolve_out="$2"
  local rv_remaining="$rv_input"
  local rv_result=""
  local rv_name
  local rv_token_regex='^([^$]*)\$(\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))(.*)$'

  while [[ "$rv_remaining" == *'$'* ]]; do
    if [[ ! "$rv_remaining" =~ $rv_token_regex ]]; then
      log e "Malformed token in path: $rv_input"
      return 1
    fi
    rv_result+="${BASH_REMATCH[1]}"
    rv_name="${BASH_REMATCH[3]:-${BASH_REMATCH[4]}}"
    rv_remaining="${BASH_REMATCH[5]}"
    if [[ -z "${!rv_name+x}" || -z "${!rv_name}" ]]; then
      log e "Unresolvable token \$$rv_name in path: $rv_input"
      return 1
    fi
    rv_result+="${!rv_name}"
  done
  rv_result+="$rv_remaining"

  if [[ "$rv_result" != /* ]]; then
    log e "Path does not resolve to an absolute path: $rv_input -> $rv_result"
    return 1
  fi

  rv_resolve_out="$rv_result"
}

#########################################
# Installed version records handlers, too complicated for set_component_option
#########################################

edit_rd_conf::retroverse() {
  # Apply changes to $rd_conf based on passed filter and arguments
  # USAGE: edit_rd_conf::retroverse "$filter" "[$jq_args...]"

  local filter="$1"
  shift
  if ! jq "$@" "$filter" "$rd_conf" > "$rd_conf.tmp"; then
    rm -f "$rd_conf.tmp"
    log e "Failed to update $rd_conf"
    return 1
  fi
  mv "$rd_conf.tmp" "$rd_conf"
}

get_installed_version::retroverse() {
  # Print the recorded version of an installed item
  # Returns 1 if no version is recorded
  # USAGE: get_installed_version::retroverse "$source_id" "$item_id"

  jq -er --arg source "$1" --arg item "$2" '.retroverse_installed[$source][$item] // empty' "$rd_conf" || return 1
}

set_installed_version::retroverse() {
  # Record the installed version of an item, creating the section as needed
  # USAGE: set_installed_version::retroverse "$source_id" "$item_id" "$version"

  edit_rd_conf::retroverse '.retroverse_installed[$source][$item] = $version' \
    --arg source "$1" --arg item "$2" --arg version "$3"
}

remove_installed_version::retroverse() {
  # Remove an item's version record, dropping the source and the whole section when they become empty
  # USAGE: remove_installed_version::retroverse "$source_id" "$item_id"

  edit_rd_conf::retroverse '
    del(.retroverse_installed[$source][$item])
    | if (.retroverse_installed[$source] // {}) == {} then del(.retroverse_installed[$source]) else . end
    | if (.retroverse_installed // {}) == {} then del(.retroverse_installed) else . end
  ' --arg source "$1" --arg item "$2"
}

#########################################
# Store refresh
#########################################

make_workdir::retroverse() {
  # Create and print a fresh work directory under $retroverse_data/tmp
  # USAGE: make_workdir::retroverse

  mkdir -p "$retroverse_data/tmp" || return 1
  mktemp -d -p "$retroverse_data/tmp" "op.XXXXXX"
}

hash_file::retroverse() {
  # Print the sha256 of a regular file
  # Returns 1 if the path is not a regular file
  # USAGE: hash_file::retroverse "$file"

  [[ -f "$1" ]] || return 1
  sha256sum -- "$1" | awk '{ print $1 }'
}

verify_hash::retroverse() {
  # Return 0 if a file's sha256 matches the expected value
  # USAGE: verify_hash::retroverse "$file" "$expected_sha256"

  local file="$1"
  local expected="$2"
  local actual
  actual=$(hash_file::retroverse "$file") || return 1
  [[ -n "$expected" && "$actual" == "$expected" ]]
}

resolve_release_tag::retroverse() {
  # Print the release tag a channel resolves to for a GitHub repo
  # stable uses /releases/latest, which excludes prereleases and drafts
  # beta takes the most recently published non-draft release
  # USAGE: resolve_release_tag::retroverse "$repo" "$channel"

  local repo="$1"
  local channel="$2"
  local api="https://api.github.com/repos/$repo/releases"
  local response tag

  case "$channel" in
    stable)
      if ! response=$(curl --silent --fail --max-time 10 "$api/latest"); then
        log w "Could not query the latest release of $repo"
        return 1
      fi
      tag=$(jq -r '.tag_name // empty' <<< "$response")
      ;;
    beta)
      if ! response=$(curl --silent --fail --max-time 10 "$api?per_page=100"); then
        log w "Could not query releases of $repo"
        return 1
      fi
      tag=$(jq -r '[.[] | select(.draft | not)] | sort_by(.published_at) | last | .tag_name // empty' <<< "$response")
      ;;
    *)
      log e "Unknown RetroVERSE channel: $channel"
      return 1
      ;;
  esac

  if [[ -z "$tag" ]]; then
    log w "No release found for $repo on channel $channel"
    return 1
  fi
  printf '%s' "$tag"
}

fetch_store::retroverse() {
  # Download and validate a release's inventory and artwork into a work directory, then swap them into the store cache
  # USAGE: fetch_store::retroverse "$repo" "$source_id" "$release_tag" "$workdir"

  local repo="$1"
  local source_id="$2"
  local release_tag="$3"
  local workdir="$4"
  local base="https://github.com/$repo/releases/download/$release_tag"
  local staging="$workdir/store"
  local store_dir="$retroverse_data/store/$source_id"

  mkdir -p "$staging/artwork" || return 1

  download_file "$base/retroverse.json" "$staging/retroverse.json" "RetroVERSE inventory"
  if ! jq -e 'type == "object"' "$staging/retroverse.json" > /dev/null 2>&1; then
    log e "Downloaded inventory for $source_id is missing or not valid JSON"
    return 1
  fi

  local supported_schema
  supported_schema=$(get_supported_store_schema::retroverse) || return 1

  local store_schema blob_source
  IFS=$'\x1f' read -r store_schema blob_source < <(jq -r '[(.store_schema_version // "" | tostring), (.source_id // "")] | join("\u001f")' "$staging/retroverse.json")

  if [[ ! "$store_schema" =~ ^[0-9]+$ ]]; then
    log e "Inventory for $source_id has no valid store_schema_version"
    return 1
  fi
  if [[ "$store_schema" -gt "$supported_schema" ]]; then
    log e "Inventory for $source_id uses store schema $store_schema, this client supports up to $supported_schema"
    return 1
  fi
  if [[ "$blob_source" != "$source_id" ]]; then
    log e "Inventory declares source_id \"$blob_source\" but was fetched as \"$source_id\""
    return 1
  fi

  download_file "$base/artwork.tar.gz" "$workdir/artwork.tar.gz" "RetroVERSE artwork"
  download_file "$base/artwork.tar.gz.sha" "$workdir/artwork.tar.gz.sha" "RetroVERSE artwork checksum"
  local artwork_sha
  artwork_sha=$(awk '{ print $1; exit }' "$workdir/artwork.tar.gz.sha" 2>/dev/null)
  if ! verify_hash::retroverse "$workdir/artwork.tar.gz" "$artwork_sha" \
     || ! tar -xzf "$workdir/artwork.tar.gz" -C "$staging/artwork"; then
    log w "Artwork for $source_id could not be downloaded or verified, continuing without thumbnails"
    rm -rf "$staging/artwork"
    mkdir -p "$staging/artwork"
  fi

  printf '%s\n' "$release_tag" > "$staging/release_tag"

  mkdir -p "$retroverse_data/store" || return 1
  if [[ -d "$store_dir" ]]; then
    mv "$store_dir" "$workdir/previous" || return 1
  fi
  if ! mv "$staging" "$store_dir"; then
    log e "Failed to swap in the new store cache for $source_id"
    [[ -d "$workdir/previous" ]] && mv "$workdir/previous" "$store_dir"
    return 1
  fi

  log i "RetroVERSE store $source_id refreshed to $release_tag"
}

refresh_store::retroverse() {
  # Fetch the inventory and artwork for a source from the release selected by the configured channel
  # The cache is kept when the selected release tag has not changed
  # If the release cannot be resolved but a cache exists, the cache is kept and the function succeeds with a warning, so the store stays browsable offline
  # USAGE: refresh_store::retroverse "[$source_id]"

  local source_id="${1:-official}"
  local store_dir="$retroverse_data/store/$source_id"

  local repo
  repo=$(get_source_repo::retroverse "$source_id") || return 1

  local channel
  channel=$(get_component_option "retroverse" "channel")
  channel="${channel:-stable}"

  local release_tag
  if ! release_tag=$(resolve_release_tag::retroverse "$repo" "$channel"); then
    if [[ -f "$store_dir/retroverse.json" ]]; then
      log w "Using cached RetroVERSE store for $source_id"
      return 0
    fi
    log e "RetroVERSE store $source_id is unreachable and no cache exists"
    return 1
  fi

  local cached_tag
  cached_tag=$(cat "$store_dir/release_tag" 2>/dev/null)
  if [[ -f "$store_dir/retroverse.json" && "$cached_tag" == "$release_tag" ]]; then
    log d "RetroVERSE store $source_id is current at $release_tag"
    return 0
  fi

  local workdir
  workdir=$(make_workdir::retroverse) || return 1
  local rc=0
  fetch_store::retroverse "$repo" "$source_id" "$release_tag" "$workdir" || rc=1
  rm -rf -- "$workdir"
  return "$rc"
}

#########################################
# Inventory and cache lookups
#########################################

cache_file::retroverse() {
  # Print the path of an item's installed manifest cache file
  # USAGE: cache_file::retroverse "$source_id" "$item_id"

  printf '%s' "$retroverse_data/installed/$1/$2.json"
}

get_store_entry::retroverse() {
  # Print an item's published entry from the cached inventory 
  # Returns 1 if the item is not listed
  # USAGE: get_store_entry::retroverse "$source_id" "$item_id"

  local inventory="$retroverse_data/store/$1/retroverse.json"
  [[ -f "$inventory" ]] || return 1
  jq -ce --arg item "$2" 'first(.items[] | select(.id == $item))' "$inventory" || return 1
}

list_items::retroverse() {
  # Print the ids of every item in a source's inventory, followed by any installed items no longer listed in it
  # USAGE: list_items::retroverse "$source_id"

  local source_id="$1"
  local inventory="$retroverse_data/store/$source_id/retroverse.json"
  {
    [[ -f "$inventory" ]] && jq -r '.items[].id' "$inventory"
    jq -r --arg source "$source_id" '.retroverse_installed[$source] // {} | keys[]' "$rd_conf"
  } | awk '!seen[$0]++'
}

get_artwork_path::retroverse() {
  # Print the path of an item's cached thumbnail
  # Returns 1 if it has none
  # USAGE: get_artwork_path::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"
  local entry
  if ! entry=$(get_store_entry::retroverse "$source_id" "$item_id"); then
    entry=$(cat "$(cache_file::retroverse "$source_id" "$item_id")" 2>/dev/null) || return 1
  fi

  local name
  name=$(jq -r '.artwork // empty' <<< "$entry")
  if [[ -z "$name" || "$name" == */* || "$name" == .* ]]; then
    return 1
  fi

  local path="$retroverse_data/store/$source_id/artwork/$name"
  [[ -f "$path" ]] || return 1
  printf '%s' "$path"
}

check_component_present::retroverse() {
  # Return 0 if a component has an entry in the component manifest cache
  # USAGE: check_component_present::retroverse "$component_name"

  jq -e --arg component "$1" 'any(.[]; .manifest | has($component))' "$component_manifest_cache_file" > /dev/null
}

check_external_component_present::retroverse() {
  # Return 0 if a component is installed as an external component
  # USAGE: check_external_component_present::retroverse "$component_name"

  [[ -f "$rd_external_components_path/$1/component_manifest.json" ]]
}

check_component_conflict::retroverse() {
  # Return 0 if a component item shares its name with a core component, which installing it would override.
  # USAGE: check_component_conflict::retroverse "$item_id"

  [[ -f "$rd_components/$1/component_manifest.json" ]]
}

check_is_installed::retroverse() {
  # Return 0 if an item is recorded as installed and, for component items, the component is still present
  # A record for a component that was removed outside RetroVERSE counts as not installed
  # USAGE: check_is_installed::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"
  local cache_file
  cache_file=$(cache_file::retroverse "$source_id" "$item_id")

  get_installed_version::retroverse "$source_id" "$item_id" > /dev/null || return 1
  [[ -f "$cache_file" ]] || return 1

  local class
  class=$(jq -r '.class // empty' "$cache_file")
  if [[ "$class" == "component" ]]; then
    check_external_component_present::retroverse "$item_id" || return 1
  fi
  return 0
}

#########################################
# Requirements and state
#########################################

check_requirement::retroverse() {
  # Test one requirement string against the local install
  # Returns 0 if met, 1 if not met, 2 if malformed
  # USAGE: check_requirement::retroverse "$source_id" "$requirement"

  local source_id="$1"
  local requirement="$2"
  local type="${requirement%%:*}"
  local value="${requirement#*:}"

  if [[ "$requirement" != *:* || -z "$value" ]]; then
    log e "Malformed requirement: $requirement"
    return 2
  fi

  case "$type" in
    component)
      check_component_present::retroverse "$value" || return 1
      ;;
    item)
      check_is_installed::retroverse "$source_id" "$value" || return 1
      ;;
    client_schema)
      if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        log e "Malformed requirement: $requirement"
        return 2
      fi
      local client_schema
      client_schema=$(get_client_schema::retroverse) || return 2
      [[ "$client_schema" -ge "$value" ]] || return 1
      ;;
    *)
      log e "Unknown requirement type: $requirement"
      return 2
      ;;
  esac
  return 0
}

get_requirement_source::retroverse() {
  # Print "store" if an unmet requirement can be satisfied by installing something from the same inventory, otherwise "none"
  # USAGE: get_requirement_source::retroverse "$source_id" "$requirement"

  local inventory="$retroverse_data/store/$1/retroverse.json"
  local requirement="$2"
  local value="${requirement#*:}"

  if [[ -f "$inventory" ]]; then
    case "${requirement%%:*}" in
      component)
        if jq -e --arg id "$value" 'any(.items[]; .id == $id and .class == "component")' "$inventory" > /dev/null; then
          echo "store"
          return
        fi
        ;;
      item)
        if jq -e --arg id "$value" 'any(.items[]; .id == $id)' "$inventory" > /dev/null; then
          echo "store"
          return
        fi
        ;;
    esac
  fi
  echo "none"
}

get_unmet_requirements::retroverse() {
  # Print every unmet requirement of an entry, including min_client_schema, as "requirement<TAB>store|none" lines
  # Prints nothing when all requirements are met
  # USAGE: get_unmet_requirements::retroverse "$source_id" "$entry_json"

  local source_id="$1"
  local entry="$2"
  local -a requirements=()
  mapfile -t requirements < <(jq -r '((.min_client_schema // empty) | "client_schema:\(.)"), (.requires // [])[]' <<< "$entry")

  local requirement
  for requirement in "${requirements[@]}"; do
    [[ -z "$requirement" ]] && continue
    if check_requirement::retroverse "$source_id" "$requirement"; then
      continue
    fi
    printf '%s\t%s\n' "$requirement" "$(get_requirement_source::retroverse "$source_id" "$requirement")"
  done
}

get_item_state::retroverse() {
  # Print the store state of an item, one of:
  #   installed_current        installed, store version matches
  #   installed_update         installed, store version differs and its requirements are met
  #   installed_update_blocked installed, store version differs but its requirements are not met
  #   installed_unlisted       installed, no longer in the inventory
  #   requires_client          not installed, needs a newer client schema
  #   requires_missing         not installed, a requirement cannot be satisfied from the store
  #   requires_store           not installed, every unmet requirement is available in the store
  #   unmanaged                component present as an external component but not installed through RetroVERSE
  #   available                can be installed
  # USAGE: get_item_state::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"
  local entry unmet

  if check_is_installed::retroverse "$source_id" "$item_id"; then
    if ! entry=$(get_store_entry::retroverse "$source_id" "$item_id"); then
      echo "installed_unlisted"
      return 0
    fi
    local installed_version store_version
    installed_version=$(get_installed_version::retroverse "$source_id" "$item_id")
    store_version=$(jq -r '.version' <<< "$entry")
    if [[ "$store_version" == "$installed_version" ]]; then
      echo "installed_current"
    else
      unmet=$(get_unmet_requirements::retroverse "$source_id" "$entry")
      if [[ -n "$unmet" ]]; then
        echo "installed_update_blocked"
      else
        echo "installed_update"
      fi
    fi
    return 0
  fi

  if ! entry=$(get_store_entry::retroverse "$source_id" "$item_id"); then
    log e "Item $item_id is neither installed nor listed in $source_id"
    return 1
  fi

  unmet=$(get_unmet_requirements::retroverse "$source_id" "$entry")
  if [[ -n "$unmet" ]]; then
    if grep -q '^client_schema:' <<< "$unmet"; then
      echo "requires_client"
    elif grep -qv $'\tstore$' <<< "$unmet"; then
      echo "requires_missing"
    else
      echo "requires_store"
    fi
    return 0
  fi

  if [[ "$(jq -r '.class' <<< "$entry")" == "component" ]] && check_external_component_present::retroverse "$item_id"; then
    echo "unmanaged"
    return 0
  fi

  echo "available"
}

#########################################
# Deploy plan
#########################################

build_deploy_plan::retroverse() {
  # Expand an entry's files[] and file_hashes into one row per deployed file, resolving every destination first
  # Rows are tab-separated: artifact path, absolute destination, policy, sha256
  # Directory entries (trailing "/" on source) expand to every hashed file beneath them
  # A file source with a trailing "/" on its destination lands inside that directory under its own name
  # Fails without writing a plan on any unresolvable destination, unknown policy, missing hash, empty directory entry or duplicate destination
  # USAGE: build_deploy_plan::retroverse "$entry_file" "$plan_file"

  local entry_file="$1"
  local plan_file="$2"

  if ! jq -e '(.files | type) == "array" and ((.file_hashes // {}) | type) == "object"' "$entry_file" > /dev/null 2>&1; then
    log e "Entry has no valid files[] or file_hashes"
    return 1
  fi

  local -a rows=()
  local -A resolved_destinations=()
  local -A seen_entries=()
  local index destination kind relative artifact_path policy hash resolved

  while IFS=$'\x1f' read -r index destination kind relative artifact_path policy hash; do
    seen_entries["$index"]=1

    case "$policy" in
      sync|replace|preserve_if_modified|install_once) ;;
      *)
        log e "Unknown policy \"$policy\" in files[$index]"
        return 1
        ;;
    esac

    if [[ -z "$hash" ]]; then
      log e "No hash for $artifact_path in files[$index]"
      return 1
    fi

    if [[ -z "${resolved_destinations[$index]+x}" ]]; then
      resolve_path::retroverse "$destination" resolved || return 1
      resolved_destinations["$index"]="$resolved"
    fi
    resolved="${resolved_destinations[$index]}"

    if [[ "$kind" == "dir" ]]; then
      resolved="${resolved%/}/$relative"
    elif [[ "$resolved" == */ ]]; then
      resolved="$resolved${artifact_path##*/}"
    fi

    rows+=("$artifact_path"$'\t'"$resolved"$'\t'"$policy"$'\t'"$hash")
  done < <(jq -r '
    (.file_hashes // {}) as $hashes
    | .files | to_entries[]
    | (.key | tostring) as $index
    | .value
    | .destination as $destination
    | (.policy // "sync") as $policy
    | ((.source // "") | ltrimstr("./")) as $source
    | if ($source | endswith("/")) then
        ($source | if . == "/" then "" else . end) as $prefix
        | $hashes | to_entries[] | select(.key | startswith($prefix))
        | [$index, $destination, "dir", (.key | ltrimstr($prefix)), .key, $policy, .value]
      else
        [$index, $destination, "file", "", $source, $policy, ($hashes[$source] // "")]
      end
    | join("\u001f")
  ' "$entry_file")

  local file_count
  file_count=$(jq '.files | length' "$entry_file")
  local i=0
  while [[ "$i" -lt "$file_count" ]]; do
    if [[ -z "${seen_entries[$i]+x}" ]]; then
      log e "files[$i] matches no files in file_hashes"
      return 1
    fi
    i=$((i + 1))
  done

  if [[ ${#rows[@]} -eq 0 ]]; then
    log e "Entry deploys no files"
    return 1
  fi

  local duplicates
  duplicates=$(printf '%s\n' "${rows[@]}" | cut -f2 | LC_ALL=C sort | uniq -d)
  if [[ -n "$duplicates" ]]; then
    log e "Several files deploy to the same destination: $duplicates"
    return 1
  fi

  printf '%s\n' "${rows[@]}" > "$plan_file"
}

load_plan_hashes::retroverse() {
  # Load a plan into an associative array of destination -> sha256
  # USAGE: load_plan_hashes::retroverse "$plan_file" "$associative_array_name"

  local plan_file="$1"
  local -n rv_plan_hashes="$2"
  local artifact_path destination policy hash
  while IFS=$'\t' read -r artifact_path destination policy hash; do
    rv_plan_hashes["$destination"]="$hash"
  done < "$plan_file"
}

#########################################
# Recorded file operations and rollback
#########################################
# Every change to the filesystem goes through these, appending to $workdir/journal:
#   mkdir<TAB>dir                 directory created
#   moved<TAB>path<TAB>backup     existing path moved aside (replaced or deleted)
#   created<TAB>path              file written
# Rollback replays the journal newest-first
# Backups live in $workdir and are discarded with it

make_parents::retroverse() {
  # Create a directory and any missing parents, recording each directory created
  # USAGE: make_parents::retroverse "$workdir" "$directory"

  local workdir="$1"
  local target="$2"
  local dir="$target"
  local -a missing=()

  while [[ -n "$dir" && ! -d "$dir" ]]; do
    missing+=("$dir")
    dir="${dir%/*}"
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  if ! mkdir -p -- "$target"; then
    log e "Could not create directory $target"
    return 1
  fi

  local i=$(( ${#missing[@]} - 1 ))
  while [[ "$i" -ge 0 ]]; do
    printf 'mkdir\t%s\n' "${missing[$i]}" >> "$workdir/journal"
    i=$((i - 1))
  done
}

move_aside::retroverse() {
  # Move an existing path into the work directory's backup area, recording it
  # Used for both replacement and deletion
  # USAGE: move_aside::retroverse "$workdir" "$path"

  local workdir="$1"
  local path="$2"
  local slot

  mkdir -p "$workdir/backup" || return 1
  slot=$(mktemp -d -p "$workdir/backup") || return 1
  if ! mv -- "$path" "$slot/item"; then
    log e "Could not move $path aside"
    return 1
  fi
  printf 'moved\t%s\t%s\n' "$path" "$slot/item" >> "$workdir/journal"
}

place_file::retroverse() {
  # Copy a file to its destination, moving any existing path aside first and recording every change
  # USAGE: place_file::retroverse "$workdir" "$source_file" "$destination"

  local workdir="$1"
  local source_file="$2"
  local destination="$3"

  make_parents::retroverse "$workdir" "${destination%/*}" || return 1
  if [[ -e "$destination" || -L "$destination" ]]; then
    move_aside::retroverse "$workdir" "$destination" || return 1
  fi

  printf 'created\t%s\n' "$destination" >> "$workdir/journal"
  if ! cp -f -- "$source_file" "$destination"; then
    log e "Could not write $destination"
    return 1
  fi
}

rollback::retroverse() {
  # Undo every change recorded in a work directory's journal, newest first
  # USAGE: rollback::retroverse "$workdir"

  local journal="$1/journal"
  [[ -f "$journal" ]] || return 0

  log w "Rolling back changes"
  local action path backup
  while IFS=$'\t' read -r action path backup; do
    case "$action" in
      created)
        rm -f -- "$path"
        ;;
      moved)
        mkdir -p -- "${path%/*}"
        mv -T -- "$backup" "$path" || log e "Could not restore $path from $backup"
        ;;
      mkdir)
        rmdir -- "$path" 2>/dev/null
        ;;
    esac
  done < <(tac "$journal")
}

prune_directories::retroverse() {
  # Remove every empty directory in a list, deepest first, writing the ones that still exist to a new list
  # USAGE: prune_directories::retroverse "$directory_list" "$output_list"

  local directory_list="$1"
  local output_list="$2"
  local dir

  : > "$output_list"
  while IFS= read -r dir; do
    [[ -z "$dir" || ! -d "$dir" ]] && continue
    if rmdir -- "$dir" 2>/dev/null; then
      log d "Removed empty directory $dir"
    else
      printf '%s\n' "$dir" >> "$output_list"
    fi
  done < <(LC_ALL=C sort -ru "$directory_list")
}

#########################################
# Shared install actions
#########################################

check_gate::retroverse() {
  # Log every unmet requirement of an entry and return 1 if there are any
  # USAGE: check_gate::retroverse "$source_id" "$entry_json"

  local unmet
  unmet=$(get_unmet_requirements::retroverse "$1" "$2")
  [[ -z "$unmet" ]] && return 0

  local requirement satisfiable
  while IFS=$'\t' read -r requirement satisfiable; do
    log e "Unmet requirement: $requirement"
  done <<< "$unmet"
  return 1
}

download_payload::retroverse() {
  # Download an entry's archive to $workdir/payload.tar.gz and verify it against the entry's hash
  # USAGE: download_payload::retroverse "$workdir"

  local workdir="$1"
  local url sha256 name
  IFS=$'\x1f' read -r url sha256 name < <(jq -r '[(.url // ""), (.sha256 // ""), (.name // .id)] | join("\u001f")' "$workdir/entry.json")

  if [[ -z "$url" || -z "$sha256" ]]; then
    log e "Entry has no url or sha256"
    return 1
  fi

  download_file "$url" "$workdir/payload.tar.gz" "$name"
  if ! verify_hash::retroverse "$workdir/payload.tar.gz" "$sha256"; then
    log e "Checksum verification failed for $url"
    return 1
  fi
}

extract_payload::retroverse() {
  # Extract $workdir/payload.tar.gz into $workdir/payload
  # USAGE: extract_payload::retroverse "$workdir"

  local workdir="$1"
  mkdir -p "$workdir/payload" || return 1
  if ! tar -xzf "$workdir/payload.tar.gz" -C "$workdir/payload"; then
    log e "Could not extract payload"
    return 1
  fi
}

commit::retroverse() {
  # Finalize an install or update
  # Prune empty item directories, write the manifest cache and directory list through the journal so a failure here still rolls back, then record the version
  # USAGE: commit::retroverse "$source_id" "$item_id" "$workdir"

  local source_id="$1"
  local item_id="$2"
  local workdir="$3"
  local cache_file
  cache_file=$(cache_file::retroverse "$source_id" "$item_id")
  local dirs_file="${cache_file%.json}.dirs"

  local version
  version=$(jq -r '.version // empty' "$workdir/entry.json")
  if [[ -z "$version" ]]; then
    log e "Entry has no version"
    return 1
  fi

  {
    [[ -f "$dirs_file" ]] && cat "$dirs_file"
    [[ -f "$workdir/journal" ]] && awk -F'\t' '$1 == "mkdir" { print $2 }' "$workdir/journal"
  } > "$workdir/dirs.all"
  prune_directories::retroverse "$workdir/dirs.all" "$workdir/dirs"

  place_file::retroverse "$workdir" "$workdir/entry.json" "$cache_file" || return 1
  place_file::retroverse "$workdir" "$workdir/dirs" "$dirs_file" || return 1
  set_installed_version::retroverse "$source_id" "$item_id" "$version" || return 1
}

forget_item::retroverse() {
  # Remove an item's manifest cache, directory list and version record
  # USAGE: forget_item::retroverse "$source_id" "$item_id"

  local cache_file
  cache_file=$(cache_file::retroverse "$1" "$2")
  rm -f -- "$cache_file" "${cache_file%.json}.dirs"
  remove_installed_version::retroverse "$1" "$2"
}

#########################################
# Data item install actions
#########################################

deploy_install::retroverse() {
  # Deploy every file in $workdir/plan from the extracted payload, regardless of policy
  # USAGE: deploy_install::retroverse "$workdir"

  local workdir="$1"
  local artifact_path destination policy hash source_file

  while IFS=$'\t' read -r -u 3 artifact_path destination policy hash; do
    source_file="$workdir/payload/$artifact_path"
    if [[ ! -f "$source_file" ]]; then
      log e "Payload is missing $artifact_path"
      return 1
    fi
    place_file::retroverse "$workdir" "$source_file" "$destination" || return 1
  done 3< "$workdir/plan"
}

deploy_update::retroverse() {
  # Apply $workdir/plan over an existing install described by $workdir/old_plan, honouring per-file policies, then remove unmodified orphans
  # Orphans whose content differs from what was installed are left in place
  # USAGE: deploy_update::retroverse "$workdir"

  local workdir="$1"
  local -A old_hashes=()
  local -A new_destinations=()
  load_plan_hashes::retroverse "$workdir/old_plan" old_hashes

  local artifact_path destination policy hash source_file local_hash

  while IFS=$'\t' read -r -u 3 artifact_path destination policy hash; do
    new_destinations["$destination"]=1
    source_file="$workdir/payload/$artifact_path"
    if [[ ! -f "$source_file" ]]; then
      log e "Payload is missing $artifact_path"
      return 1
    fi

    if [[ "$policy" == "install_once" && -n "${old_hashes[$destination]+x}" ]]; then
      log d "Leaving install_once file $destination untouched"
      continue
    fi

    if [[ ! -e "$destination" ]]; then
      place_file::retroverse "$workdir" "$source_file" "$destination" || return 1
      continue
    fi

    case "$policy" in
      sync)
        local_hash=$(hash_file::retroverse "$destination")
        if [[ "$local_hash" == "$hash" ]]; then
          continue
        fi
        ;;
      preserve_if_modified)
        local_hash=$(hash_file::retroverse "$destination")
        if [[ "$local_hash" == "$hash" ]]; then
          continue
        fi
        if [[ -n "${old_hashes[$destination]+x}" && "$local_hash" != "${old_hashes[$destination]}" ]]; then
          log i "Preserving locally modified file $destination"
          continue
        fi
        ;;
    esac

    place_file::retroverse "$workdir" "$source_file" "$destination" || return 1
  done 3< "$workdir/plan"

  while IFS=$'\t' read -r -u 3 artifact_path destination policy hash; do
    if [[ -n "${new_destinations[$destination]+x}" ]]; then
      continue
    fi
    if [[ ! -e "$destination" && ! -L "$destination" ]]; then
      continue
    fi
    local_hash=$(hash_file::retroverse "$destination")
    if [[ "$local_hash" == "$hash" ]]; then
      log d "Removing orphan $destination"
      move_aside::retroverse "$workdir" "$destination" || return 1
    else
      log i "Leaving locally modified orphan $destination in place"
    fi
  done 3< "$workdir/old_plan"
}

install_data::retroverse() {
  # Install a data item
  # All destinations resolve before anything is downloaded or touched, any failure rolls back
  # USAGE: install_data::retroverse "$source_id" "$item_id" "$workdir"

  local source_id="$1"
  local item_id="$2"
  local workdir="$3"

  build_deploy_plan::retroverse "$workdir/entry.json" "$workdir/plan" || return 1
  download_payload::retroverse "$workdir" || return 1
  extract_payload::retroverse "$workdir" || return 1

  if ! deploy_install::retroverse "$workdir" || ! commit::retroverse "$source_id" "$item_id" "$workdir"; then
    rollback::retroverse "$workdir"
    return 1
  fi
  log i "Installed $source_id/$item_id"
}

update_data::retroverse() {
  # Update an installed data item to the entry in $workdir/entry.json
  # Any failure restores the previous state
  # USAGE: update_data::retroverse "$source_id" "$item_id" "$workdir"

  local source_id="$1"
  local item_id="$2"
  local workdir="$3"

  build_deploy_plan::retroverse "$workdir/entry.json" "$workdir/plan" || return 1
  if ! build_deploy_plan::retroverse "$workdir/old_entry.json" "$workdir/old_plan"; then
    log e "Cannot resolve the installed destinations of $item_id, refusing to update"
    return 1
  fi
  download_payload::retroverse "$workdir" || return 1
  extract_payload::retroverse "$workdir" || return 1

  if ! deploy_update::retroverse "$workdir" || ! commit::retroverse "$source_id" "$item_id" "$workdir"; then
    rollback::retroverse "$workdir"
    return 1
  fi
  log i "Updated $source_id/$item_id"
}

uninstall_data::retroverse() {
  # Remove every file declared by an installed data item's cached manifest, prune its directories and forget it
  # Continues past individual failures and returns 1 if any occurred
  # USAGE: uninstall_data::retroverse "$source_id" "$item_id" "$workdir"

  local source_id="$1"
  local item_id="$2"
  local workdir="$3"
  local cache_file
  cache_file=$(cache_file::retroverse "$source_id" "$item_id")

  if ! build_deploy_plan::retroverse "$cache_file" "$workdir/plan"; then
    log e "Cannot resolve the installed destinations of $item_id, refusing to uninstall"
    return 1
  fi

  local failed=0
  local artifact_path destination policy hash
  while IFS=$'\t' read -r -u 3 artifact_path destination policy hash; do
    if [[ -e "$destination" || -L "$destination" ]]; then
      rm -f -- "$destination" || failed=1
    fi
  done 3< "$workdir/plan"

  local dirs_file="${cache_file%.json}.dirs"
  if [[ -f "$dirs_file" ]]; then
    prune_directories::retroverse "$dirs_file" "$workdir/dirs.left"
  fi

  forget_item::retroverse "$source_id" "$item_id" || failed=1
  if [[ "$failed" -ne 0 ]]; then
    log e "Uninstall of $source_id/$item_id completed with errors"
    return 1
  fi
  log i "Uninstalled $source_id/$item_id"
}

#########################################
# Component item install actions
#########################################

install_component::retroverse() {
  # Install or update a component item
  # An already present external component, managed or not, goes through the upgrade path so its post-update handler runs
  # USAGE: install_component::retroverse "$source_id" "$item_id" "$workdir"

  local source_id="$1"
  local item_id="$2"
  local workdir="$3"
  local archive="$workdir/payload.tar.gz"

  download_payload::retroverse "$workdir" || return 1

  local archive_component
  archive_component=$(get_component_name_from_archive "$archive")
  if [[ "$archive_component" != "$item_id" ]]; then
    log e "Archive for $item_id contains component \"$archive_component\""
    return 1
  fi

  if check_external_component_present::retroverse "$item_id"; then
    upgrade_external_component "$archive" || return 1
  else
    if check_component_conflict::retroverse "$item_id"; then
      log w "Component $item_id overrides the core component of the same name"
    fi
    install_external_component "$archive" || return 1
  fi

  if ! commit::retroverse "$source_id" "$item_id" "$workdir"; then
    rollback::retroverse "$workdir"
    log e "Component $item_id was installed but its RetroVERSE record could not be written"
    return 1
  fi
  log i "Installed component $source_id/$item_id"
}

uninstall_component::retroverse() {
  # Remove a component item and forget it
  # A component already removed outside RetroVERSE only has its record cleared
  # USAGE: uninstall_component::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"

  if check_external_component_present::retroverse "$item_id"; then
    remove_external_component "$item_id" || return 1
  else
    log w "Component $item_id is no longer installed, clearing its RetroVERSE record"
  fi
  forget_item::retroverse "$source_id" "$item_id" || return 1
  log i "Uninstalled component $source_id/$item_id"
}
