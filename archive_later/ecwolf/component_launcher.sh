#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"
log d "QT QPA PLATFORM plugin path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

# Launch
log i "RetroDECK ECWolf Runner"
path="${@: -1}" # getting the last argument as game path
args="${@:1:$#-1}" # getting all the other passed args

append_wolf_data_files() {
  local folder="$1"
  local ext
  local file

  [[ -d "$folder" ]] || return 1

  for ext in wl6 wl1 sdm sod n3d; do
    shopt -s nullglob
    for file in "$folder"/*."$ext"; do
      [[ -f "$file" ]] || continue
      args="$args --file \"$file\""
    done
    shopt -u nullglob
  done
}

# Identify Wolf3D version by core files in folder
# Requests: gamemaps, maphead, vswap with an extension.
# Preference order: wl6, wl1, sdm, sod, sd1, sd2, sd3, n3d.
# Returns version name (wl6/wl1/sdm/sod/sd1/sd2/sd3/n3d) or failure.
detect_wolf3d_version() {
  local folder="$1"
  [[ -d "$folder" ]] || return 1

  local versions=(wl6 wl1 sdm sod sd1 sd2 sd3 n3d)

  for version in "${versions[@]}"; do
    local gamemaps_file
    local maphead_file
    local vswap_file

    gamemaps_file=$(find "$folder" -maxdepth 1 -type f -iname "gamemaps.$version" -print -quit 2>/dev/null)
    maphead_file=$(find "$folder" -maxdepth 1 -type f -iname "maphead.$version" -print -quit 2>/dev/null)
    vswap_file=$(find "$folder" -maxdepth 1 -type f -iname "vswap.$version" -print -quit 2>/dev/null)

    if [[ -n "$gamemaps_file" && -n "$maphead_file" && -n "$vswap_file" ]]; then
      if validate_wolf3d_version_hash "$folder" "$version"; then
        printf '%s' "$version"
        return 0
      else
        log d "Version '$version' rejected for '$folder' because hash validation failed"
      fi
    fi
  done

  return 1
}

pretty_wolf3d_version() {
  local version="${1,,}"
  case "$version" in
    wl6) echo "Wolfenstein 3D (Full)" ;;
    wl1) echo "Wolfenstein 3D (Shareware)" ;;
    sdm) echo "Spear of Destiny (Demo)" ;;
    sod) echo "Spear of Destiny (Full)" ;;
    sd1) echo "Spear of Destiny - Mission Pack 1 - Return to Danger" ;;
    sd2) echo "Spear of Destiny - Mission Pack 2 - Return to Danger" ;;
    sd3) echo "Spear of Destiny - Mission Pack 3 - Ultimate Challenge" ;;
    n3d) echo "Super 3D Noah’s Ark" ;;
    *) echo "Unknown Wolf3D version: $version" ;;
  esac
}

# Known IWAD hash fixtures for core file trio to avoid false positives in mod folders.
# (Source: ECWolf docs, checked on Wolfenstein 3D / Spear of Destiny / Noah's Ark)
declare -A wolf3d_data_hashes
wolf3d_data_hashes=(
  [wl6.gamemaps]="a4e73706e100dc0cadfb02d23de46481"
  [wl6.maphead]="b8d2a78bc7c50da7ec9ab1d94f7975e1"
  # Support both canonical and alternate WL6 vswap variants observed in field
  [wl6.vswap]="b8ff4997461bafa5ef2a94c11f9de001 a6d901dfb455dfac96db5e4705837cdb"

  [wl1.gamemaps]="30fecd7cce6bc70402651ec922d2da3d"
  [wl1.maphead]="7b6dd4e55c33c33a41d1600be5df3228"
  [wl1.vswap]="6efa079414b817c97db779cecfb081c9"

  [sdm.gamemaps]="4eb2f538aab6e4061dadbc3b73837762"
  [sdm.maphead]="40fa03caf7a1a4dbd22da4321c6e10d4"
  [sdm.vswap]="35afda760bea840b547d686a930322dc"

  [sod.gamemaps]="04f16534235b4b57fc379d5709f88f4a"
  [sod.maphead]="276c79a4a6419db6b23e7699e41cb9fa"
  [sod.vswap]="b1dac0a8786c7cdbb09331a4eba00652"

  [sd2.gamemaps]="d55508cd58e2e61076ac81b98aeb9269"
  [sd2.maphead]="25d92ac0ba012a1e9335c747eb4ab177"
  [sd2.vswap]="fa5752c5b1e25ee5c4a9ec0e9d4013a9"

  [sd3.gamemaps]="4219d83568d770b1c6ac9c2d4d1dfb9e"
  [sd3.maphead]="52fd50245a77e61dc1df91110c186195"
  [sd3.vswap]="e3e87518f51414872c454b7d72a45af6"

  [sd3-alt.gamemaps]="29860b87c31348e163e10f8aa6f19295"
  [sd3-alt.maphead]="a8b24dd3d3271e0b7fc6f2f995915f27"
  [sd3-alt.vswap]="94aeef7980ef640c448087f92be16d83"

  [n3d.gamemaps]="d35ce2257a4fb56f61529df5f7f77adb"
  [n3d.maphead]="2eaab4dd50856abeaebe75a8bcbbab42"
  [n3d.vswap]="8c61a9b3bb38a598990ccb743d2679fa"
)

expected_wolf3d_hash() {
  local version="$1" file="$2" key
  key="$version.$file"
  # support alternate sd3 variant too
  [[ -n "${wolf3d_data_hashes[$key]:-}" ]] && printf '%s' "${wolf3d_data_hashes[$key]}" && return 0
  if [[ "$version" == "sd3" ]]; then
    key="sd3-alt.$file"
    [[ -n "${wolf3d_data_hashes[$key]:-}" ]] && printf '%s' "${wolf3d_data_hashes[$key]}" && return 0
  fi
  return 1
}

validate_wolf3d_version_hash() {
  local folder="$1" version="$2"
  local md5cmd
  md5cmd=$(command -v md5sum || true)
  if [[ -z "$md5cmd" ]]; then
    log w "md5sum not found, version detection will proceed by filenames only"
    return 0
  fi

  for file in gamemaps maphead vswap; do
    # case-insensitive path resolution, because actual files may use uppercase extensions/names
    local path
    path=$(find "$folder" -maxdepth 1 -type f -iname "${file}.${version}" -print -quit 2>/dev/null)
    [[ -n "$path" ]] || return 1

    local expected
    expected=$(expected_wolf3d_hash "$version" "$file")
    if [[ -z "$expected" ]]; then
      log d "Hash not available for $file.$version, rejecting wildcard match to avoid mod false positive"
      return 1
    fi

    local actual
    actual=$($md5cmd "$path" | awk '{print tolower($1)}')

    local match=0
    for allowed in $expected; do
      if [[ "$actual" == "$allowed" ]]; then
        match=1
        break
      fi
    done

    if (( match == 0 )); then
      log d "Hash mismatch for $path ($version): expected one of [$expected], got $actual"
      return 1
    fi
  done

  # If we reached here, all three core files matched expected hashes
  return 0
}

# Normalize user-provided Wolf3D version keys from .wolf data= values.
normalize_wolf3d_version_key() {
  local input="${1,,}"
  input="${input//\"/}"
  input="${input//\'/}"
  input="${input//[[:space:]]/}"
  input="${input//[^a-z0-9]/}"

  case "$input" in
    wl6|wolfenstein3dfull|wolfensteinfull|full) echo wl6 ;;
    wl1|shareware|wolfenstein3dshareware|shareware) echo wl1 ;;
    sdm|spearofdestinydemo|speardestinydemo) echo sdm ;;
    sod|spearofdestinyfull|speardestinyfull) echo sod ;;
    sd1|missionpack1|returntodanger) echo sd1 ;;
    sd2|missionpack2|returntodanger2) echo sd2 ;;
    sd3|missionpack3|ultimatechallenge) echo sd3 ;;
    n3d|super3dnoahsark|noahsark) echo n3d ;;
    *) return 1 ;;
  esac
}

# Find a wolf3d data folder under $root, optionally enforcing a preferred version.
# Mode "default" uses legacy priority: wl6 -> wl1 -> sdm -> sod -> sd1 -> sd2 -> sd3 -> n3d.
# Mode "mod" uses mod-friendly order (full/packs first, shareware last): wl6 -> sod -> sd1 -> sd2 -> sd3 -> n3d -> sdm -> wl1.
find_wolf3d_wolf_folder() {
  local root="${1:-${roms_path}/wolf}"
  local preferred_version="${2:-}"
  local mode="${3:-default}"

  [[ -d "$root" ]] || return 1

  local -A version_rank
  if [[ "$mode" == "mod" ]]; then
    version_rank=( [wl6]=1 [sod]=2 [sd1]=3 [sd2]=4 [sd3]=5 [n3d]=6 [sdm]=7 [wl1]=8 )
  else
    version_rank=( [wl6]=1 [wl1]=2 [sdm]=3 [sod]=4 [sd1]=5 [sd2]=6 [sd3]=7 [n3d]=8 )
  fi

  local best_path="" best_rank=999

  for candidate in "$root"/*.wolf; do
    [[ -d "$candidate" ]] || continue
    if [[ -n "$preferred_version" ]]; then
      version="$(detect_wolf3d_version "$candidate")" || continue
      if [[ "$version" != "$preferred_version" ]]; then
        continue
      fi
      wolf3d_data_version="$version"
      printf '%s' "$candidate"
      return 0
    fi

    version="$(detect_wolf3d_version "$candidate")" || continue
    local rank=${version_rank[$version]:-999}
    if (( rank < best_rank )); then
      best_rank=$rank
      best_path="$candidate"
      wolf3d_data_version="$version"
    fi
  done

  if [[ -n "$best_path" ]]; then
    printf '%s' "$best_path"
    return 0
  fi

  # last chance: maybe root itself is an IWAD folder
  if version="$(detect_wolf3d_version "$root")"; then
    if [[ -z "$preferred_version" || "$version" == "$preferred_version" ]]; then
      wolf3d_data_version="$version"
      printf '%s' "$root"
      return 0
    fi
  fi

  return 1
}

# Start launcher mode selection
raw_args=( "${@:1:$#-1}" )
input_path="${@: -1}"

if [[ -z "$input_path" ]]; then
  log e "No game path argument provided"
  exit 1
fi

if [[ -f "$input_path" && "${input_path##*.}" == "wolf" ]]; then
  # mod descriptor path
  mod_wolf_file="$input_path"
  mod_folder="$(dirname "$mod_wolf_file")"
  log i "Mod descriptor provided: $mod_wolf_file"

  mod_files=()
  mod_data_override=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#${line%%[![:space:]]*}}"
    line="${line%${line##*[![:space:]]}}"
    [[ -z "$line" ]] && continue

    if [[ "${line,,}" =~ ^data[[:space:]]*=[[:space:]]*(.+)$ ]]; then
      raw_data="${BASH_REMATCH[1]}"
      if ! mod_data_override="$(normalize_wolf3d_version_key "$raw_data")"; then
        log e "Invalid data= value '$raw_data' in '$mod_wolf_file'"
        exit 1
      fi
      log i "Mod descriptor requests base IWAD '$mod_data_override'"
      continue
    fi

    mod_files+=("$line")
  done < "$mod_wolf_file"

  if [[ -n "$mod_data_override" ]]; then
    iwad_folder="$(find_wolf3d_wolf_folder "$roms_path/wolf" "$mod_data_override" "mod")" || {
      log e "Base IWAD '$mod_data_override' specified in '$mod_wolf_file' not found in $roms_path/wolf"
      exit 1
    }
  elif [[ ${#mod_files[@]} -gt 0 ]]; then
    iwad_folder="$(find_wolf3d_wolf_folder "$roms_path/wolf" "wl6" "mod")" || {
      log e "No default WL6 IWAD found for mod; mod requires at least one valid base IWAD"
      exit 1
    }
  else
    iwad_folder="$(find_wolf3d_wolf_folder "$roms_path/wolf" "" "mod")" || {
      log e "No IWAD found in $roms_path/wolf"
      exit 1
    }
  fi

  version="$(detect_wolf3d_version "$iwad_folder")"
  wolf3d_data_version_pretty="$(pretty_wolf3d_version "$version")"
  log i "Mod mode: base IWAD set to '$iwad_folder' (found $wolf3d_data_version_pretty)"

  requested_mod_files=()
  if [[ ${#mod_files[@]} -gt 0 ]]; then
    for mod_entry in "${mod_files[@]}"; do
      if [[ "$mod_entry" == /* ]]; then
        requested_mod_files+=( --file "$mod_entry" )
      else
        requested_mod_files+=( --file "$mod_folder/$mod_entry" )
      fi
    done
    launch_folder="$iwad_folder"
  else
    launch_folder="$mod_folder"
  fi

elif [[ -d "$input_path" ]]; then
  version="$(detect_wolf3d_version "$input_path")" || true
  if [[ -n "$version" ]]; then
    iwad_folder="$input_path"
    wolf3d_data_version_pretty="$(pretty_wolf3d_version "$version")"
    log i "IWAD mode: launching '$iwad_folder' (detected $wolf3d_data_version_pretty)"
    launch_folder="$iwad_folder"
  else
    # directory could be a mod container with same-name .wolf file
    candidate_mod_file="$input_path/$(basename "$input_path").wolf"
    if [[ -f "$candidate_mod_file" ]]; then
      input_path="$candidate_mod_file"
      # Re-run by calling this script recursively avoids duplication; but to keep it simple, we follow same logic inline.
      mod_wolf_file="$candidate_mod_file"
      mod_folder="$input_path"
      # fallback to using this .wolf logic path
      # no recursive here to avoid complexity; if we reach this path we can proceed as mod with input_path set
      # (this scenario should be rare in Data layout)
      # We don't re-enter the if block, continue with auto-detect using mod_wolf_file below.
    else
      log i "No IWAD detected in '$input_path', auto-detecting under $roms_path/wolf"
      iwad_folder="$(find_wolf3d_wolf_folder "$roms_path/wolf")" || {
        log e "No valid Wolf3D data folder found under $roms_path/wolf"
        exit 1
      }
      version="$(detect_wolf3d_version "$iwad_folder")"
      wolf3d_data_version_pretty="$(pretty_wolf3d_version "$version")"
      log i "Auto-detected IWAD '$iwad_folder' ($wolf3d_data_version_pretty)"
      launch_folder="$iwad_folder"
    fi
  fi
else
  log i "Input path '$input_path' not a file or directory; auto-detecting IWAD in $roms_path/wolf"
  iwad_folder="$(find_wolf3d_wolf_folder "$roms_path/wolf")" || {
    log e "No valid Wolf3D data folder found under $roms_path/wolf"
    exit 1
  }
  version="$(detect_wolf3d_version "$iwad_folder")"
  wolf3d_data_version_pretty="$(pretty_wolf3d_version "$version")"
  log i "Auto-detected IWAD '$iwad_folder' ($wolf3d_data_version_pretty)"
  launch_folder="$iwad_folder"
fi

# If we didn't set launch_folder yet (e.g. mod path without explicit file entries), use iwad_folder
launch_folder="${launch_folder:-$iwad_folder}"

if [[ -z "$launch_folder" || ! -d "$launch_folder" ]]; then
  log e "Nessuna cartella di avvio valida trovata"
  exit 1
fi

# Always use requested base options and preserved args.
args=( "${raw_args[@]}" )

if [[ ${#requested_mod_files[@]} -gt 0 ]]; then
  args+=( "${requested_mod_files[@]}" )
fi

if [[ -n "$main_game" ]]; then
  args+=( "$main_game" )
fi

# Log command line internal representation
if [[ ${#args[@]} -gt 0 ]]; then
  log i "With args: ${args[*]}"
fi

# Final command
log d "Executing: \"$component_path/bin/ecwolf\" --fullscreen --nowait --config /var/config/ecwolf/ecwolf_rd.cfg --savedir /var/data/ecwolf/saves ${args[*]}"

cd "$launch_folder" || exit 1
log i "Running from $launch_folder"
exec "$component_path/bin/ecwolf" --fullscreen --nowait --config /var/config/ecwolf/ecwolf_rd.cfg --savedir /var/data/ecwolf/saves "${args[@]}"
cd -
