#!/bin/bash

# The purpose of this script is the take an input component.json file, aquire the original package, extract it to a useable file structure, pick out the files/folders desired and re-archive it in a standard structure.
# The script requires a recipe file to read, and optionally can be given an output directory (which overrides the default $WORKDIR) and an alternative 'desired_versions.sh' file.
# ARGS:
# Required: -f <recipe file>
# Optional: -o [output directory]
# Optional: -v [desired versions file]
# USAGE: 
# alchemist.sh -f component_recipe.json [-o <dir>] [-v <version file>]


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Source tooling scripts
source "$SCRIPT_DIR/lib/defaults.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/extract.sh"
source "$SCRIPT_DIR/lib/assemble.sh"
source "$SCRIPT_DIR/lib/libs.sh"

log() {
  echo "[$1] $2" >&2
}

transmute() {
  component_recipe_file=$(realpath "$1")
  WORKDIR="${2:-$DEFAULT_WORKDIR}"
  export WORKDIR="$(realpath "$WORKDIR")"
  desired_versions="${3:-$DESIRED_VERSIONS}"

  export EXTRACTED_PATH=""

  if [[ ! -e "$desired_versions" ]]; then
    log error "Desired version file could not be found at $desired_versions, cannot continue."
    exit 1
  fi

  source "$desired_versions"

  # component_recipe.json file information extraction
  component_recipe_contents=$(jq -r '.' "$component_recipe_file")
  export COMPONENT_NAME="$(jq -r '. | keys[]' <<< $component_recipe_contents)"

  if [[ -d "$WORKDIR" ]]; then # If a workdir already exists, clear it
    rm -rf "$WORKDIR"
  fi

  export COMPONENT_ARTIFACT_ROOT="$WORKDIR/$COMPONENT_NAME-artifact" # Initialize the final destination for kept files
  mkdir -p "$COMPONENT_ARTIFACT_ROOT"

  while read -r source_obj; do
    source_type="$(jq -r '.source_type' <<< $source_obj)"
    source_url="$(jq -r '.source_url' <<< $source_obj | envsubst)"
    export SOURCE_VERSION="$(jq -r '.version' <<< $source_obj | envsubst)"
    source_dest="$(jq -r '.dest//empty' <<< $source_obj | envsubst)"
    extraction_type="$(jq -r '.extraction_type' <<< $source_obj)"

    if [[ ! -n "$source_dest" ]]; then
      source_dest="$WORKDIR"
    fi

    # Download stage for this object
    download_result=$(process_download -t "$source_type" -u "$source_url" -d "$source_dest" -v "$SOURCE_VERSION")
    downloaded_file=$(echo "$download_result" | grep "^DOWNLOADED_FILE=" | cut -d= -f2)
    downloaded_version=$(echo "$download_result" | grep "^DOWNLOADED_VERSION=" | cut -d= -f2)

    if [[ -n "${downloaded_file:-}" ]]; then
      export DOWNLOADED_FILE="$downloaded_file"
    fi

    # Some downloaders (e.g. local/http) don't emit DOWNLOADED_VERSION.
    # In that case, keep the recipe-provided SOURCE_VERSION instead of clobbering it.
    if [[ -n "${downloaded_version:-}" ]]; then
      export SOURCE_VERSION="$downloaded_version"
    fi

    # Extraction stage for this object
    extraction_result=$(process_extract -f "$DOWNLOADED_FILE" -d "$source_dest" -t "$extraction_type")
    export EXTRACTED_PATH=$(echo "$extraction_result" | grep "^EXTRACTED_PATH=" | cut -d= -f2)

    # Assemble stage for this object
    obj_assets="$(jq -r '.assets//empty' <<< $source_obj)"

    if [[ -n "$obj_assets" && ! "$obj_assets" == '[]' ]]; then
    log info "Component has listed assets, gathering..."
      while read -r asset_obj; do
        asset_type="$(jq -r '.type' <<< $asset_obj)"
        asset_source="$(jq -r '.source//empty' <<< $asset_obj | envsubst)"
        asset_dest="$(jq -r '.dest//empty' <<< $asset_obj | envsubst)"
        asset_contents="$(jq -r '.contents//empty' <<< $asset_obj | envsubst)"

        assembly_result=$(process_asset -t "$asset_type" -s "$asset_source" -d "$asset_dest" -c "$asset_contents")
      done < <(echo "$obj_assets" | jq -c '.[]')
    else
      log info "Component assets omitted or empty, skipping..."
    fi
    
    # Library gathering stage
    obj_libs=$(echo "$source_obj" | jq -c '.libs//empty')

    if [[ -n "$obj_libs" && ! "$obj_libs" == '[]' ]]; then
      log info "Component has listed libs, collecting..."

      while read -r lib_obj; do
        lib_name="$(jq -r '.library//empty' <<< $lib_obj)"
        lib_runtime_name="$(jq -r '.runtime_name//empty' <<< $lib_obj)"
        lib_runtime_version="$(jq -r '.runtime_version//empty'<<< $lib_obj | envsubst)"
        lib_source="$(jq -r '.source//empty' <<< $lib_obj | envsubst)"
        lib_dest="$(jq -r '.dest//empty' <<< $lib_obj | envsubst)"

        gather_lib_result=$(process_gather_lib -n "$lib_name" -d "$lib_dest" -rn "$lib_runtime_name" -rv "$lib_runtime_version" -s "$lib_source")
      done < <(echo "$obj_libs" | jq -c '.[]')
    else
      log info "Component libs omitted or empty, skipping..."
    fi
  done < <(echo $component_recipe_contents | jq -c --arg component_name "$COMPONENT_NAME" '.[$component_name].[]')

  # Artifact compression stage
  if [[ ! "$DRYRUN" == "true" ]]; then
    local final_artifact_dir="$REPO_ROOT/$COMPONENT_NAME/artifacts"

    if [[ ! -d "$final_artifact_dir" ]]; then
      mkdir -p "$final_artifact_dir"
    fi

    local artifact_tar_file="$final_artifact_dir/$COMPONENT_NAME.tar.gz"
    if [[ -f "$artifact_tar_file" ]]; then
      log warn "Existing $artifact_tar_file found, deleting before creating a new one."
      rm -f "$artifact_tar_file"
    fi

    local artifact_sha_file="$final_artifact_dir/$COMPONENT_NAME.tar.gz.sha"
    if [[ -f "$artifact_sha_file" ]]; then
      log warn "Existing sha file $artifact_sha_file found, deleting before creating a new one."
      rm -f "$artifact_sha_file"
    fi

    log info "Compressing artifact source $COMPONENT_ARTIFACT_ROOT into $artifact_tar_file"
    if ! tar -czf "$artifact_tar_file" -C "$COMPONENT_ARTIFACT_ROOT" .; then
      log error "Artifact tar file $artifact_tar_file could not be created."
      return 1
    fi

    sha256sum "$artifact_tar_file" | awk '{print $1}' > "$artifact_sha_file"

    if [[ -d "$WORKDIR" ]]; then
      log info "Cleaning up work dir $WORKDIR"
      rm -rf "$WORKDIR"
    fi

    log debug "Final artifact contents:"
    tar -tzf "$artifact_tar_file" | while read -r line; do
      log debug "  $line"
    done

    log info "Cleaning up artifacts directory, keeping only archive and checksum..."
    find "$final_artifact_dir" -mindepth 1 -maxdepth 1 \
            ! -name "$(basename "$artifact_tar_file")" \
            ! -name "$(basename "$artifact_sha_file")" \
            -exec rm -rf {} +
  else
    log info "--dry-run detected, skipping artifact compression and $WORKDIR cleanup"
  fi

  log info "Finalization complete for $COMPONENT_NAME"
}

parse_args() {
  local recipe=""
  local alt_workdir=""
  local alt_versions=""
  DRYRUN=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        recipe="$2"
        shift 2
        ;;
      -o|--output)
        alt_workdir="$2"
        shift 2
        ;;
      -v|--versions)
        alt_versions="$2"
        shift 2
        ;;
      --dry-run)
        export DRYRUN="true"
        shift 1
        ;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$recipe" ]]; then
    log error "Missing required arguments: -f <recipe file>"
    return 1
  fi

  transmute "$recipe" "$alt_workdir" "$alt_versions"
}

parse_args "$@"
