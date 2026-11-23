#!/bin/bash

export retroverse_data="$XDG_CONFIG_HOME/retroverse"

# Client-specific settings
export retroverse_ui_title="RetroVERSE"
export retroverse_ui_width=1100
export retroverse_ui_height=650
# jq helpers for the UI: Pango-escape a string, and flatten it to one line
export retroverse_ui_jq_defs='
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  def line: gsub("[\t\n\r\u001f]"; " ");
'

#########################################
# Helpers
#########################################

get_supported_store_schema::retroverse() {
  # Print the highest store schema version this client can read, from this component's manifest
  # USAGE: get_supported_store_schema::retroverse

  local schema
  schema=$(jq -r '.[] | .manifest | select(has("retroverse")) | .retroverse.retroverse_schema_version // empty' "$component_manifest_cache_file")
  if [[ ! "$schema" =~ ^[0-9]+$ ]]; then
    log e "RetroVERSE retroverse_schema_version is missing or not an integer in the component manifest"
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
  IFS=$'\x1f' read -r store_schema blob_source < <(jq -r '[(.retroverse_schema_version // "" | tostring), (.source_id // "")] | join("\u001f")' "$staging/retroverse.json")

  if [[ ! "$store_schema" =~ ^[0-9]+$ ]]; then
    log e "Inventory for $source_id has no valid retroverse_schema_version"
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

  prune_screenshot_cache::retroverse "$source_id"
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

get_artwork_path::retroverse() {
  # Print the path of a cached thumbnail by its artwork name from an item entry
  # Returns 1 if the name is empty or unsafe, or the file is not in the cache
  # USAGE: get_artwork_path::retroverse "$source_id" "$artwork_name"

  local source_id="$1"
  local name="$2"

  if [[ -z "$name" || "$name" == "null" || "$name" == */* || "$name" == .* ]]; then
    return 1
  fi

  local path="$retroverse_data/store/$source_id/artwork/$name"
  [[ -f "$path" ]] || return 1
  printf '%s' "$path"
}

fetch_screenshots::retroverse() {
  # Make an item's screenshots available locally and print the directory holding them
  # Returns 1 if the item has no screenshots or they cannot be fetched
  # USAGE: fetch_screenshots::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"
  local url sha name
  IFS=$'\x1f' read -r url sha name < <(get_item_records::retroverse "$source_id" "$item_id" \
    | jq -r '[.screenshots_url, .screenshots_sha256, (.name | gsub("[\t\n\u001f]"; " "))] | join("\u001f")')

  if [[ -z "$url" || ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    log e "$source_id/$item_id has no screenshots to fetch"
    return 1
  fi

  local item_cache="$retroverse_data/screenshots/$source_id/$item_id"
  local cache_dir="$item_cache/$sha"
  if [[ -d "$cache_dir" ]]; then
    printf '%s' "$cache_dir"
    return 0
  fi

  local workdir
  workdir=$(make_workdir::retroverse) || return 1

  local rc=0
  download_file "$url" "$workdir/screenshots.tar.gz" "$name screenshots"
  if ! verify_hash::retroverse "$workdir/screenshots.tar.gz" "$sha"; then
    log e "Checksum verification failed for $url"
    rc=1
  elif ! mkdir -p "$workdir/screenshots" || ! tar -xzf "$workdir/screenshots.tar.gz" -C "$workdir/screenshots"; then
    log e "Could not extract screenshots for $source_id/$item_id"
    rc=1
  elif ! mkdir -p "$item_cache" || ! mv -- "$workdir/screenshots" "$cache_dir"; then
    log e "Could not cache screenshots for $source_id/$item_id"
    rc=1
  fi
  rm -rf -- "$workdir"
  [[ "$rc" -eq 0 ]] || return 1

  local old
  for old in "$item_cache"/*/; do
    old="${old%/}"
    [[ "$old" == "$cache_dir" ]] || rm -rf -- "$old"
  done

  log i "Fetched screenshots for $source_id/$item_id"
  printf '%s' "$cache_dir"
}

prune_screenshot_cache::retroverse() {
  # Remove cached screenshot sets the current inventory no longer references
  # USAGE: prune_screenshot_cache::retroverse "$source_id"

  local source_id="$1"
  local cache_root="$retroverse_data/screenshots/$source_id"
  local inventory="$retroverse_data/store/$source_id/retroverse.json"
  [[ -d "$cache_root" && -f "$inventory" ]] || return 0

  local -A keep=()
  local key
  while IFS= read -r key; do
    keep["$key"]=1
  done < <(jq -r '.items[] | select((.screenshots_sha256 // "") != "") | "\(.id)/\(.screenshots_sha256)"' "$inventory")

  local set_dir item_dir
  for set_dir in "$cache_root"/*/*/; do
    [[ -d "$set_dir" ]] || continue
    set_dir="${set_dir%/}"
    key="${set_dir#"$cache_root"/}"
    if [[ -z "${keep[$key]+x}" ]]; then
      rm -rf -- "$set_dir"
      log d "Removed cached screenshots $key"
    fi
  done
  for item_dir in "$cache_root"/*/; do
    [[ -d "$item_dir" ]] && rmdir -- "$item_dir" 2>/dev/null
  done
  return 0
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

retroverse_state_program='
  ($inventory[0] // {}) as $inv
  | ($inv.items // []) as $items
  | (reduce $items[] as $item ({}; .[$item.id] = $item)) as $listed
  | (reduce $cached[] as $entry ({}; .[$entry.id] = $entry)) as $cache
  | ($conf[0].retroverse_installed[$source] // {}) as $installed
  | ($external | split("\n") | map(select(. != ""))) as $ext
  | ([$manifests[0][] | .manifest | keys[]]) as $components
  | (first($manifests[0][] | .manifest.retroverse.client_schema_version | numbers) // 0) as $client

  | def is_installed($id):
      $installed[$id] != null and $cache[$id] != null
      and ($cache[$id].class != "component" or any($ext[]; . == $id));

    def requirement_parts:
      capture("^(?<type>[^:]+):(?<value>.+)$") // {type: "", value: .};

    def requirement_met:
      requirement_parts as $p
      | if $p.type == "component" then any($components[]; . == $p.value)
        elif $p.type == "item" then is_installed($p.value)
        elif $p.type == "client_schema" then (($p.value | tonumber?) // null) as $n | $n != null and $client >= $n
        else false end;

    def requirement_source:
      requirement_parts as $p
      | if ($p.type == "component" and $listed[$p.value].class == "component")
           or ($p.type == "item" and $listed[$p.value] != null) then "store" else "none" end;

    def requirement_name:
      requirement_parts as $p
      | if $p.type == "client_schema" then "a newer RetroDECK version"
        else $listed[$p.value].name
             // first($manifests[0][] | .manifest[$p.value].name // empty)
             // $p.value
        end;

    def unmet($entry):
      [ (($entry.min_client_schema // empty) | "client_schema:\(.)"), ($entry.requires // [])[]
        | select(requirement_met | not)
        | {requirement: ., source: requirement_source, name: requirement_name} ];

    def state($id):
      $listed[$id] as $store
      | if is_installed($id) then
          if $store == null then "installed_unlisted"
          elif $store.version == $installed[$id] then "installed_current"
          elif (unmet($store) | length) > 0 then "installed_update_blocked"
          else "installed_update" end
        elif $store == null then null
        else unmet($store) as $u
          | if ($u | length) > 0 then
              if any($u[]; .requirement | startswith("client_schema:")) then "requires_client"
              elif any($u[]; .source != "store") then "requires_missing"
              else "requires_store" end
            elif $store.class == "component" and any($ext[]; . == $id) then "unmanaged"
            else "available" end
        end;

    if $mode == "unmet" then
      unmet($entry)[] | [.requirement, .source] | join("\t")
    else
      ([$items[].id] + (($installed | keys) - [$items[].id]))[]
      | select($only == "" or . == $only)
      | . as $id
      | ($listed[$id] // $cache[$id]) as $entry
      | select($entry != null)
      | state($id) as $state
      | select($state != null)
      | {
          id: $id,
          class: ($entry.class // ""),
          name: ($entry.name // $id),
          description: ($entry.description // ""),
          version: ($entry.version // ""),
          upstream_version: ($entry.upstream_version // ""),
          tags: ($entry.tags // []),
          artwork: ($entry.artwork // ""),
          artwork_large: ($entry.artwork_large // ""),
          screenshots: ($entry.screenshots // []),
          screenshots_url: ($entry.screenshots_url // ""),
          screenshots_sha256: ($entry.screenshots_sha256 // ""),
          screenshots_size: ($entry.screenshots_size // null),
          payload_size: ($entry.payload_size // null),
          installed_version: ($installed[$id] // ""),
          state: $state,
          unmet: (if $listed[$id] != null then unmet($listed[$id]) else [] end)
        }
    end
'

run_state_program::retroverse() {
  # Run the state program for a source with every input it needs. Further arguments are passed to jq.
  # USAGE: run_state_program::retroverse "$source_id" "$mode" "[$jq_args...]"

  local source_id="$1"
  local mode="$2"
  shift 2

  local inventory="$retroverse_data/store/$source_id/retroverse.json"
  [[ -f "$inventory" ]] || inventory="/dev/null"

  local -a external=()
  local manifest component_dir
  for manifest in "$rd_external_components_path"/*/component_manifest.json; do
    [[ -f "$manifest" ]] || continue
    component_dir="${manifest%/component_manifest.json}"
    external+=("${component_dir##*/}")
  done

  jq -nc --arg source "$source_id" --arg mode "$mode" \
    --slurpfile inventory "$inventory" \
    --slurpfile conf "$rd_conf" \
    --slurpfile manifests "$component_manifest_cache_file" \
    --slurpfile cached <(cat -- "$retroverse_data/installed/$source_id/"*.json 2>/dev/null) \
    --arg external "$(printf '%s\n' "${external[@]}")" \
    "$@" "$retroverse_state_program"
}

get_item_records::retroverse() {
  # Print one JSON record per item in a source: every listed item, then installed items no longer listed
  # Fields: id, class, name, description, version, upstream_version, tags, artwork, artwork_large,
  #         screenshots[], screenshots_url, screenshots_sha256, screenshots_size, payload_size,
  #         installed_version, state, unmet[] ({requirement, source, name})
  # State is one of:
  #   installed_current        installed, store version matches
  #   installed_update         installed, store version differs and its requirements are met
  #   installed_update_blocked installed, store version differs but its requirements are not met
  #   installed_unlisted       installed, no longer in the inventory
  #   requires_client          not installed, needs a newer client schema
  #   requires_missing         not installed, a requirement cannot be satisfied from the store
  #   requires_store           not installed, every unmet requirement is available in the store
  #   unmanaged                component present as an external component but not installed through RetroVERSE
  #   available                can be installed
  # USAGE: get_item_records::retroverse "$source_id" "[$item_id]"

  run_state_program::retroverse "$1" "records" --arg only "${2:-}" --argjson entry null
}

get_unmet_requirements::retroverse() {
  # Print every unmet requirement of an entry, including min_client_schema, as "requirement<TAB>store|none" lines
  # Prints nothing when all requirements are met
  # USAGE: get_unmet_requirements::retroverse "$source_id" "$entry_json"

  run_state_program::retroverse "$1" "unmet" -r --arg only "" --argjson entry "$2"
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

  install_external_component "$archive" || return 1

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

#########################################
# Client actions
#########################################

install_item::retroverse() {
  # Install an item from a source's cached inventory
  # USAGE: install_item::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"

  if check_is_installed::retroverse "$source_id" "$item_id"; then
    log e "$source_id/$item_id is already installed"
    return 1
  fi

  local entry
  if ! entry=$(get_store_entry::retroverse "$source_id" "$item_id"); then
    log e "$item_id is not listed in $source_id"
    return 1
  fi
  check_gate::retroverse "$source_id" "$entry" || return 1

  local class
  class=$(jq -r '.class' <<< "$entry")

  local workdir
  workdir=$(make_workdir::retroverse) || return 1
  printf '%s\n' "$entry" > "$workdir/entry.json"

  local rc=0
  case "$class" in
    data)
      install_data::retroverse "$source_id" "$item_id" "$workdir" || rc=1
      ;;
    component)
      install_component::retroverse "$source_id" "$item_id" "$workdir" || rc=1
      ;;
    *)
      log e "Unknown item class: $class"
      rc=1
      ;;
  esac

  rm -rf -- "$workdir"
  return "$rc"
}

update_item::retroverse() {
  # Update an installed item to the version in a source's cached inventory
  # Succeeds without change if already current
  # USAGE: update_item::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"

  if ! check_is_installed::retroverse "$source_id" "$item_id"; then
    log e "$source_id/$item_id is not installed"
    return 1
  fi

  local entry
  if ! entry=$(get_store_entry::retroverse "$source_id" "$item_id"); then
    log e "$item_id is no longer listed in $source_id"
    return 1
  fi

  local installed_version store_version
  installed_version=$(get_installed_version::retroverse "$source_id" "$item_id")
  store_version=$(jq -r '.version' <<< "$entry")
  if [[ "$installed_version" == "$store_version" ]]; then
    log d "$source_id/$item_id is current at $installed_version"
    return 0
  fi

  check_gate::retroverse "$source_id" "$entry" || return 1

  local cache_file
  cache_file=$(cache_file::retroverse "$source_id" "$item_id")
  local class old_class
  class=$(jq -r '.class' <<< "$entry")
  old_class=$(jq -r '.class' "$cache_file")
  if [[ "$class" != "$old_class" ]]; then
    log e "$item_id changed class from $old_class to $class; uninstall and reinstall it"
    return 1
  fi

  local workdir
  workdir=$(make_workdir::retroverse) || return 1
  printf '%s\n' "$entry" > "$workdir/entry.json"
  cp -- "$cache_file" "$workdir/old_entry.json"

  local rc=0
  case "$class" in
    data)      update_data::retroverse "$source_id" "$item_id" "$workdir" || rc=1 ;;
    component) install_component::retroverse "$source_id" "$item_id" "$workdir" || rc=1 ;;
    *)
      log e "Unknown item class: $class"
      rc=1
      ;;
  esac

  rm -rf -- "$workdir"
  return "$rc"
}

uninstall_item::retroverse() {
  # Uninstall an item using its cached manifest
  # USAGE: uninstall_item::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"
  local cache_file
  cache_file=$(cache_file::retroverse "$source_id" "$item_id")

  if [[ ! -f "$cache_file" ]]; then
    if get_installed_version::retroverse "$source_id" "$item_id" > /dev/null; then
      log w "$source_id/$item_id has a version record but no cached manifest, clearing the record"
      remove_installed_version::retroverse "$source_id" "$item_id"
      return 0
    fi
    log e "$source_id/$item_id is not installed"
    return 1
  fi

  local class
  class=$(jq -r '.class' "$cache_file")

  local rc=0
  case "$class" in
    data)
      local workdir
      workdir=$(make_workdir::retroverse) || return 1
      uninstall_data::retroverse "$source_id" "$item_id" "$workdir" || rc=1
      rm -rf -- "$workdir"
      ;;
    component)
      uninstall_component::retroverse "$source_id" "$item_id" || rc=1
      ;;
    *)
      log e "Unknown item class in cached manifest: $class"
      rc=1
      ;;
  esac
  return "$rc"
}

#########################################
# Client UI functions
#########################################

escape_markup::retroverse() {
  # Print a string with the characters Pango markup treats as special escaped
  # USAGE: escape_markup::retroverse "$text"

  local text="$1"
  local amp='&amp;' lt='&lt;' gt='&gt;'
  text="${text//&/"$amp"}"
  text="${text//</"$lt"}"
  text="${text//>/"$gt"}"
  printf '%s' "$text"
}

format_size::retroverse() {
  # Convert a specific byte-count to a human-readable form
  # USAGE: format_size::retroverse "$bytes"

  [[ "$1" =~ ^[0-9]+$ ]] || return 0
  awk -v b="$1" 'BEGIN {
    split("B KB MB GB TB", unit, " "); i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    printf (i == 1 ? "%d %s" : "%.1f %s"), b, unit[i]
  }'
}

show_message::retroverse() {
  # Show an information or error dialog; error dialogs point to the log
  # USAGE: show_message::retroverse "info|error" "$markup_text"

  local kind="$1"
  local text="$2"
  local image="dialog-information"

  if [[ "$kind" == "error" ]]; then
    image="dialog-error"
    text+=$'\n\n'"Details are in the RetroDECK log at $(escape_markup::retroverse "$logs_path")."
  fi

  rd_yad --title="$retroverse_ui_title" --image="$image" --width=450 \
    --text="$text" --button="OK:0"
  return 0
}

question_dialog::retroverse() {
  # Ask the user to confirm something. Returns 0 if they confirm.
  # USAGE: question_dialog::retroverse "$markup_text" "$confirm_label"

  rd_yad --title="$retroverse_ui_title" --image="dialog-question" --width=450 \
    --text="$1" --button="Cancel:1" --button="$2:0"
}

progress_dialog::retroverse() {
  # USAGE: progress_dialog::retroverse "$markup_text" "$command" "[$args...]"

  local text="$1"
  shift

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_yad --progress --pulsate --auto-close --no-buttons --title="$retroverse_ui_title" \
    --width=450 --text="$text" < "$progress_pipe" &
  local yad_pid=$!

  local progress_fd
  exec {progress_fd}>"$progress_pipe"

  local rc=0
  "$@" {progress_fd}>&- || rc=$?

  exec {progress_fd}>&-
  wait "$yad_pid"
  rm -f "$progress_pipe"
  return "$rc"
}

get_status_text::retroverse() {
  # Convert item state to human-readable form
  # USAGE: get_status_text::retroverse "$state" "$unmet_all" "$unmet_store" "$unmet_none"

  local state="$1"
  case "$state" in
    installed_current)
      printf 'Installed'
      ;;
    installed_update)
      printf 'Update available'
      ;;
    installed_update_blocked)
      printf 'Installed, update requires %s' "$2"
      ;;
    installed_unlisted)
      printf 'Installed, no longer in RetroVERSE'
      ;;
    requires_client)
      printf 'Requires a newer RetroDECK version'
      ;;
    requires_missing)
      printf 'Requires %s' "$4"
      ;;
    requires_store)
      printf 'Requires %s, available in RetroVERSE' "$3"
      ;;
    unmanaged)
      printf 'Installed manually'
      ;;
    available)
      printf 'Available'
      ;;
  esac
}

#########################################
# UI screens
#########################################

build_item_rows::retroverse() {
  # Print the rows of an item list: artwork, name, version, status, item id
  # Views are "data" and "component" (by class) or "installed" (everything installed through RetroVERSE); an optional tag narrows the view
  # USAGE: build_item_rows::retroverse "$source_id" "$view" "[$tag]"

  local source_id="$1"
  local view="$2"
  local tag="$3"
  local sort_key item_id state artwork name version installed_version unmet_all unmet_store unmet_none
  local version_text status artwork_path

  while IFS=$'\x1f' read -r sort_key item_id state artwork name version installed_version unmet_all unmet_store unmet_none; do
    [[ -z "$item_id" ]] && continue

    version_text="$version"
    if [[ "$state" == installed_* ]]; then
      version_text="$installed_version"
      [[ "$state" == "installed_update" ]] && version_text="$installed_version → $version"
    fi
    status=$(get_status_text::retroverse "$state" "$unmet_all" "$unmet_store" "$unmet_none")
    artwork_path=$(get_artwork_path::retroverse "$source_id" "$artwork") || artwork_path=""

    case "$state" in
      requires_*)
        name="<span foreground='gray'>$name</span>"
        version_text="<span foreground='gray'>$version_text</span>"
        status="<span foreground='gray'>$status</span>"
        ;;
      installed_update)
        status="<b>$status</b>"
        ;;
    esac

    printf '%s\n' "$artwork_path" "$name" "$version_text" "$status" "$item_id"
  done < <(get_item_records::retroverse "$source_id" | jq -r --arg view "$view" --arg tag "$tag" "$retroverse_ui_jq_defs"'
      select(if $view == "installed" then (.state | startswith("installed_")) else .class == $view end)
      | select($tag == "" or any(.tags[]; . == $tag))
      | [ (.name | ascii_downcase | line), .id, .state, (.artwork | tostring | line),
          (.name | line | esc), (.version | line | esc), (.installed_version | line | esc),
          ([.unmet[].name] | join(", ") | line | esc),
          ([.unmet[] | select(.source == "store") | .name] | join(", ") | line | esc),
          ([.unmet[] | select(.source != "store") | .name] | join(", ") | line | esc) ]
      | join("\u001f")' | LC_ALL=C sort -t $'\x1f' -k1,1)
}

list_updatable::retroverse() {
  # Print "item_id<TAB>name" for every installed item with an update that can be applied
  # USAGE: list_updatable::retroverse "$source_id"

  get_item_records::retroverse "$1" | jq -r "$retroverse_ui_jq_defs"'select(.state == "installed_update") | [.id, (.name | line)] | join("\t")'
}

select_tag::retroverse() {
  # Ask the user for a tag to filter a class view by, printing the tag, or nothing for all items
  # Returns 1 if the user cancels, leaving the current filter in place
  # USAGE: select_tag::retroverse "$source_id" "$class"

  local inventory="$retroverse_data/store/$1/retroverse.json"
  local class="$2"
  local -a tags=()
  mapfile -t tags < <(jq -r --arg class "$class" '[.items[] | select(.class == $class) | (.tags // [])[]] | unique[]' "$inventory")

  local choice
  choice=$(printf '%s\n' "All items" "${tags[@]}" | rd_yad --list --title="$retroverse_ui_title" \
    --text="Show only items tagged:" --width=400 --height=450 --no-headers --no-markup \
    --column="Tag" --separator="" --button="Back:1" --button="Filter:0") || return 1
  [[ -z "$choice" ]] && return 1

  if [[ "$choice" != "All items" ]]; then
    printf '%s' "$choice"
  fi
}

perform_action::retroverse() {
  # Confirm where needed, run an install, update or removal with a progress dialog, and report the result
  # "manage" installs the store version of a component the user installed manually
  # Returns 1 if the user cancelled or the action failed
  # USAGE: perform_action::retroverse "install|update|remove|manage" "$source_id" "$item_id"

  local action="$1"
  local source_id="$2"
  local item_id="$3"

  local name class
  IFS=$'\x1f' read -r name class < <(get_item_records::retroverse "$source_id" "$item_id" \
    | jq -r "$retroverse_ui_jq_defs"'[(.name | line | esc), .class] | join("\u001f")')
  if [[ -z "$class" ]]; then
    log e "$item_id is neither installed nor listed in $source_id"
    return 1
  fi

  local progress_text done_text fail_text
  local -a command=()

  case "$action" in
    install)
      if [[ "$class" == "component" ]] && check_component_conflict::retroverse "$item_id" \
         && ! check_external_component_present::retroverse "$item_id"; then
        question_dialog::retroverse "<b>$name</b> is included with RetroDECK.\n\nInstalling it from RetroVERSE replaces the included version with this one. Your current settings for it are kept.\n\nInstall it anyway?" "Install" || return 1
      fi
      command=(install_item::retroverse "$source_id" "$item_id")
      progress_text="Installing <b>$name</b>..."
      done_text="<b>$name</b> was installed."
      fail_text="<b>$name</b> could not be installed. Nothing was changed."
      ;;
    manage)
      question_dialog::retroverse "<b>$name</b> was installed manually.\n\nRetroVERSE will install its own version over it as an update and look after future updates. Your current settings for it are kept.\n\nContinue?" "Continue" || return 1
      command=(install_item::retroverse "$source_id" "$item_id")
      progress_text="Installing <b>$name</b>..."
      done_text="<b>$name</b> is now managed by RetroVERSE."
      fail_text="<b>$name</b> could not be installed."
      ;;
    update)
      command=(update_item::retroverse "$source_id" "$item_id")
      progress_text="Updating <b>$name</b>..."
      done_text="<b>$name</b> was updated."
      fail_text="<b>$name</b> could not be updated. The previous version is still installed."
      ;;
    remove)
      if [[ "$class" == "component" ]]; then
        question_dialog::retroverse "Remove <b>$name</b>?\n\nThe component and its settings will be removed." "Remove" || return 1
      else
        question_dialog::retroverse "Remove <b>$name</b>?\n\nEvery file it installed will be deleted, including any you have changed." "Remove" || return 1
      fi
      command=(uninstall_item::retroverse "$source_id" "$item_id")
      progress_text="Removing <b>$name</b>..."
      done_text="<b>$name</b> was removed."
      fail_text="<b>$name</b> could not be removed completely."
      ;;
    *)
      log e "Unknown RetroVERSE action: $action"
      return 1
      ;;
  esac

  if progress_dialog::retroverse "$progress_text" "${command[@]}"; then
    show_message::retroverse info "$done_text"
    return 0
  fi
  show_message::retroverse error "$fail_text"
  return 1
}

item_details::retroverse() {
  # Show an item's details with the actions its state allows, and run the chosen action
  # USAGE: item_details::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"

  local state name description version upstream installed_version tags size artwork artwork_large screenshot_count
  local unmet_all unmet_store unmet_none
  IFS=$'\x1f' read -r state name description version upstream installed_version tags size artwork artwork_large screenshot_count \
    unmet_all unmet_store unmet_none < <(
    get_item_records::retroverse "$source_id" "$item_id" | jq -r "$retroverse_ui_jq_defs"'
      [ .state, (.name | line | esc), (.description | gsub("\n"; "\\n") | line | esc),
        (.version | line | esc), (.upstream_version | line | esc), (.installed_version | line | esc),
        (.tags | join(", ") | line | esc), (.payload_size // "" | tostring),
        (.artwork | tostring | line), (.artwork_large | tostring | line),
        (if .screenshots_url != "" then (.screenshots | length) else 0 end | tostring),
        ([.unmet[].name] | join(", ") | line | esc),
        ([.unmet[] | select(.source == "store") | .name] | join(", ") | line | esc),
        ([.unmet[] | select(.source != "store") | .name] | join(", ") | line | esc) ]
      | join("\u001f")')
  if [[ -z "$state" ]]; then
    log e "$item_id is neither installed nor listed in $source_id"
    return 1
  fi

  local text="<big><b>$name</b></big>"
  [[ -n "$description" ]] && text+="\n\n$description"
  text+="\n"
  if [[ "$state" == installed_* ]]; then
    text+="\n<b>Installed version:</b> $installed_version"
    [[ "$state" != "installed_unlisted" ]] && text+="\n<b>Store version:</b> $version"
  else
    text+="\n<b>Version:</b> $version"
  fi
  [[ -n "$upstream" ]] && text+="\n<b>Upstream version:</b> $upstream"
  [[ -n "$size" ]] && text+="\n<b>Download size:</b> $(format_size::retroverse "$size")"
  [[ -n "$tags" ]] && text+="\n<b>Tags:</b> $tags"
  text+="\n<b>Status:</b> $(get_status_text::retroverse "$state" "$unmet_all" "$unmet_store" "$unmet_none")"

  local -a buttons=()
  [[ "$screenshot_count" -gt 0 ]] && buttons+=(--button="Screenshots ($screenshot_count):14")
  case "$state" in
    available)        buttons+=(--button="Install:10") ;;
    installed_update) buttons+=(--button="Remove:12" --button="Update:11") ;;
    installed_*)      buttons+=(--button="Remove:12") ;;
    unmanaged)        buttons+=(--button="Manage with RetroVERSE:13") ;;
  esac

  local -a image=()
  local artwork_path
  if artwork_path=$(get_artwork_path::retroverse "$source_id" "$artwork_large") \
     || artwork_path=$(get_artwork_path::retroverse "$source_id" "$artwork"); then
    image=(--image="$artwork_path")
  fi

  while true; do
    local rc=0
    rd_yad --title="$retroverse_ui_title" "${image[@]}" --width=750 \
      --text="$text" --button="Back:1" "${buttons[@]}" || rc=$?

    case "$rc" in
      10)
        perform_action::retroverse install "$source_id" "$item_id"
        ;;
      11)
        perform_action::retroverse update "$source_id" "$item_id"
        ;;
      12)
        perform_action::retroverse remove "$source_id" "$item_id"
        ;;
      13)
        perform_action::retroverse manage "$source_id" "$item_id"
        ;;
      14)
        view_screenshots::retroverse "$source_id" "$item_id"
        continue
        ;;
    esac
    return 0
  done
}

view_screenshots::retroverse() {
  # Fetch an item's screenshots if needed and show them
  # USAGE: view_screenshots::retroverse "$source_id" "$item_id"

  local source_id="$1"
  local item_id="$2"

  local name
  name=$(get_item_records::retroverse "$source_id" "$item_id" | jq -r "$retroverse_ui_jq_defs"'.name | line | esc')

  local shot_dir
  if ! shot_dir=$(fetch_screenshots::retroverse "$source_id" "$item_id"); then
    show_message::retroverse error "The screenshots for <b>$name</b> could not be downloaded."
    return 1
  fi

  local -a shots=()
  local shot
  while IFS= read -r shot; do
    [[ -z "$shot" || "$shot" == */* || "$shot" == .* ]] && continue
    [[ -f "$shot_dir/$shot" ]] && shots+=("$shot")
  done < <(get_item_records::retroverse "$source_id" "$item_id" | jq -r '.screenshots[]')

  if [[ ${#shots[@]} -eq 0 ]]; then
    show_message::retroverse error "The screenshots for <b>$name</b> are missing from the download."
    return 1
  fi

  local count=${#shots[@]}
  local index=0
  while true; do
    local -a buttons=(--button="Back:1")
    [[ "$index" -gt 0 ]] && buttons+=(--button="Previous:2")
    [[ "$index" -lt $((count - 1)) ]] && buttons+=(--button="Next:3")

    local rc=0
    rd_yad --picture --title="$retroverse_ui_title" --filename="$shot_dir/${shots[$index]}" --size=fit \
      --width="$retroverse_ui_width" --height="$retroverse_ui_height" \
      --text="<b>$name</b>  Screenshot $((index + 1)) of $count" "${buttons[@]}" || rc=$?

    case "$rc" in
      2)
        index=$((index - 1))
        ;;
      3)
        index=$((index + 1))
        ;;
      *)
        return 0
        ;;
    esac
  done
}

update_all::retroverse() {
  # Apply every available update then summarise any failures
  # USAGE: update_all::retroverse "$source_id"

  local source_id="$1"
  local -a ids=()
  local -a names=()
  local item_id name

  while IFS=$'\t' read -r item_id name; do
    [[ -z "$item_id" ]] && continue
    ids+=("$item_id")
    names+=("$(escape_markup::retroverse "$name")")
  done < <(list_updatable::retroverse "$source_id")

  if [[ ${#ids[@]} -eq 0 ]]; then
    show_message::retroverse info "Everything installed from RetroVERSE is up to date."
    return 0
  fi

  local list
  list=$(printf '\\n- %s' "${names[@]}")
  question_dialog::retroverse "Update ${#ids[@]} item(s)?\n$list" "Update all" || return 1

  local -a failed=()
  local i=0
  while [[ "$i" -lt "${#ids[@]}" ]]; do
    if ! progress_dialog::retroverse "Updating <b>${names[$i]}</b> ($((i + 1)) of ${#ids[@]})..." \
         update_item::retroverse "$source_id" "${ids[$i]}"; then
      failed+=("${names[$i]}")
    fi
    i=$((i + 1))
  done

  if [[ ${#failed[@]} -eq 0 ]]; then
    show_message::retroverse info "All updates were installed."
    return 0
  fi
  list=$(printf '\\n- %s' "${failed[@]}")
  show_message::retroverse error "These items could not be updated and are still at their previous version:\n$list"
  return 1
}

item_list::retroverse() {
  # Show the item list for a view
  # USAGE: item_list::retroverse "$source_id" "data|component|installed"

  local source_id="$1"
  local view="$2"
  local tag=""
  local heading
  case "$view" in
    data)
      heading="Content"
      ;;
    component)
      heading="Components"
      ;;
    installed)
      heading="Installed from RetroVERSE"
      ;;
  esac

  while true; do
    local rows
    rows=$(build_item_rows::retroverse "$source_id" "$view" "$tag")

    if [[ -z "$rows" ]]; then
      if [[ -n "$tag" ]]; then
        tag=""
        continue
      fi
      if [[ "$view" == "installed" ]]; then
        show_message::retroverse info "Nothing has been installed from RetroVERSE yet."
      else
        show_message::retroverse info "There is nothing in this section of RetroVERSE yet."
      fi
      return 0
    fi

    local text="<b>$heading</b>"
    [[ -n "$tag" ]] && text+=", tagged <i>$(escape_markup::retroverse "$tag")</i>"

    local -a buttons=(--button="Back:1")
    if [[ "$view" == "installed" ]]; then
      [[ -n "$(list_updatable::retroverse "$source_id")" ]] && buttons+=(--button="Update all:3")
    else
      buttons+=(--button="Filter by tag:2")
    fi
    buttons+=(--button="Details:0")

    local selection
    local rc=0
    selection=$(rd_yad --list --title="$retroverse_ui_title" --text="$text" \
      --width="$retroverse_ui_width" --height="$retroverse_ui_height" \
      --column=":IMG" --column="Name" --column="RetroVERSE Version" --column="Status" --column="ID" \
      --hide-column=5 --print-column=5 --separator="" "${buttons[@]}" <<< "$rows") || rc=$?

    case "$rc" in
      0)
        [[ -n "$selection" ]] && item_details::retroverse "$source_id" "$selection"
        ;;
      2)
        local new_tag
        if new_tag=$(select_tag::retroverse "$source_id" "$view"); then
          tag="$new_tag"
        fi
        ;;
      3)
        update_all::retroverse "$source_id"
        ;;
      *)
        return 0
        ;;
    esac
  done
}

settings_menu::retroverse() {
  # Let the user switch between the stable and beta store channels, warning before switching to beta
  # USAGE: settings_menu::retroverse "$source_id"

  local source_id="$1"
  local current
  current=$(get_component_option "retroverse" "channel")
  current="${current:-stable}"

  local stable_label="Stable"
  local beta_label="Beta"
  [[ "$current" == "stable" ]] && stable_label+=" (current)"
  [[ "$current" == "beta" ]] && beta_label+=" (current)"

  local choice
  choice=$(printf '%s\n' "stable" "$stable_label" "Tested content (recommended)" \
                         "beta" "$beta_label" "Early access to new and updated content, which may not work correctly" \
    | rd_yad --list --title="$retroverse_ui_title" --text="<b>Store channel</b>" --width=650 --height=300 \
      --column="ID" --column="Channel" --column="Description" --hide-column=1 --print-column=1 --separator="" \
      --button="Back:1" --button="Select:0") || return 0

  if [[ -z "$choice" || "$choice" == "$current" ]]; then
    return 0
  fi

  if [[ "$choice" == "beta" ]]; then
    question_dialog::retroverse "<b>Switch to the beta channel?</b>\n\nBeta content has not been fully tested and may not work correctly. Items you install or update from it stay installed if you switch back to stable." "Switch to beta" || return 0
  fi

  if ! set_component_option "retroverse" "channel" "$choice"; then
    show_message::retroverse error "The store channel could not be changed."
    return 1
  fi

  if ! progress_dialog::retroverse "Loading the $choice store..." refresh_store::retroverse "$source_id"; then
    show_message::retroverse error "The $choice store could not be loaded. The previously loaded store is still shown."
    return 1
  fi
  return 0
}

main_menu::retroverse() {
  # USAGE: main_menu::retroverse "$source_id"

  local source_id="$1"

  while true; do
    local channel updates installed_label text
    channel=$(get_component_option "retroverse" "channel")
    updates=$(list_updatable::retroverse "$source_id" | grep -c .)

    installed_label="Everything you have installed from RetroVERSE"
    if [[ "$updates" -eq 1 ]]; then
      installed_label="1 update available"
    elif [[ "$updates" -gt 1 ]]; then
      installed_label="$updates updates available"
    fi

    text="<b>Welcome to RetroVERSE</b>"
    [[ "$channel" == "beta" ]] && text+="\nYou are using the <b>beta</b> channel. Content may not be fully tested."

    local choice
    choice=$(printf '%s\n' "data" "Content" "Games, artwork and other content" \
                           "component" "Components" "Additional emulators and tools" \
                           "installed" "Installed" "$installed_label" \
                           "settings" "Settings" "Choose between the stable and beta store" \
      | rd_yad --list --title="$retroverse_ui_title" --text="$text" --width=650 --height=400 \
        --column="ID" --column="Section" --column="Description" --hide-column=1 --print-column=1 --separator="" \
        --button="Close:1" --button="Open:0") || return 0

    case "$choice" in
      data|component|installed)
        item_list::retroverse "$source_id" "$choice"
        ;;
      settings)
        settings_menu::retroverse "$source_id"
        ;;
    esac
  done
}

launch_client::retroverse() {
  # Refresh the store, then show the main menu
  # If the store cannot be refreshed but a previous copy is cached, that copy is shown with a notice
  # USAGE: launch_client::retroverse "[$source_id]"

  local source_id="${1:-official}"
  local refreshed=0

  progress_dialog::retroverse "Checking RetroVERSE for new content..." refresh_store::retroverse "$source_id" || refreshed=1

  if [[ ! -f "$retroverse_data/store/$source_id/retroverse.json" ]]; then
    show_message::retroverse error "The RetroVERSE store could not be loaded. Check your internet connection and try again."
    return 1
  fi
  if [[ "$refreshed" -ne 0 ]]; then
    show_message::retroverse info "The RetroVERSE store could not be updated, so the copy loaded last time is shown."
  fi

  main_menu::retroverse "$source_id"
}
