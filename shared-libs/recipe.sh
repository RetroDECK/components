#!/bin/bash

# Recipe for shared-libs component
# This script installs Qt runtime plugins from Flatpak runtimes and their extensions
# Configuration is read from component_libs.json
# Uses gather_plugins.sh to extract plugin directories

set -e

# Architecture
ARCH="x86_64"

# Import logger if not already available
if [[ ! -f ".tmpfunc/logger.sh" ]]; then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

# Ensure logfile is set and exported for all log calls
if [ -z "$logfile" ]; then
    export logfile="$(realpath -m assemble.log)"
else
    export logfile
fi

export rd_logging_level="debug"
export logging_level="$rd_logging_level"
export rd_logs_folder="$(dirname "$logfile")"

# Source logger functions
source ".tmpfunc/logger.sh"

# Source gather_plugins function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$SCRIPT_DIR/../automation-tools"
COMPONENT_LIBS_JSON="$SCRIPT_DIR/component_libs.json"

if [[ -f "$AUTOMATION_DIR/gather_plugins.sh" ]]; then
    source "$AUTOMATION_DIR/gather_plugins.sh"
    log d "gather_plugins.sh sourced successfully" "$logfile"
else
    log e "gather_plugins.sh not found at $AUTOMATION_DIR/gather_plugins.sh" "$logfile"
    exit 1
fi

# Check if component_libs.json exists
if [[ ! -f "$COMPONENT_LIBS_JSON" ]]; then
    log e "component_libs.json not found at $COMPONENT_LIBS_JSON" "$logfile"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    log e "jq is required but not installed. Please install jq." "$logfile"
    exit 1
fi

log i "Starting shared-libs recipe for Qt runtime plugins" "$logfile"

# Create working directory for temporary files
export WORK_DIR=$(mktemp -d)
log d "Created working directory: $WORK_DIR" "$logfile"

# Ensure cleanup on exit
cleanup() {
    if [[ -d "$WORK_DIR" ]]; then
        log d "Cleaning up working directory: $WORK_DIR" "$logfile"
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

# Ensure flathub is added as a remote
log i "Ensuring flathub remote is configured..." "$logfile"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Function to resolve version from major and minor version
# If minor_version is "latest" or empty, finds the latest minor version
resolve_version() {
    local package_name="$1"
    local major_version="$2"
    local minor_version="$3"
    
    # If both are empty or "latest", get the absolute latest
    if [[ -z "$major_version" || "$major_version" == "latest" ]]; then
        log d "Searching for absolute latest version of ${package_name}..." "$logfile"
        local latest=$(flatpak remote-ls --user --runtime flathub --columns=ref | grep "${package_name}/${ARCH}/" | cut -d'/' -f4 | sort -V | tail -n1)
        
        if [[ -z "$latest" ]]; then
            log e "Could not find ${package_name} on flathub" "$logfile"
            return 1
        fi
        
        log i "Latest version for ${package_name}: ${latest}" "$logfile"
        echo "$latest"
        return 0
    fi
    
    # If minor_version is "latest" or empty, find the latest minor for this major
    if [[ -z "$minor_version" || "$minor_version" == "latest" ]]; then
        log d "Searching for latest minor version of ${package_name} ${major_version}..." "$logfile"
        local latest_minor=$(flatpak remote-ls --user --runtime flathub --columns=ref | grep "${package_name}/${ARCH}/" | grep "/${major_version}\." | cut -d'/' -f4 | sort -V | tail -n1)
        
        if [[ -z "$latest_minor" ]]; then
            log e "Could not find ${package_name} ${major_version}.x on flathub" "$logfile"
            return 1
        fi
        
        log i "Latest version for ${package_name} ${major_version}.x: ${latest_minor}" "$logfile"
        echo "$latest_minor"
        return 0
    fi
    
    # Both major and minor are specified
    local full_version="${major_version}.${minor_version}"
    log i "Using specified version for ${package_name}: ${full_version}" "$logfile"
    echo "$full_version"
}



# Function to manage extensions (independent from runtimes)
manage_extensions() {
    local extensions_json="$1"
    
    # Count extensions
    local ext_count=$(echo "$extensions_json" | jq 'length' 2>/dev/null || echo "0")
    
    if [[ "$ext_count" -eq 0 ]]; then
        log d "No extensions to install" "$logfile"
        return 0
    fi
    
    local artifacts_dir="$SCRIPT_DIR/artifacts"
    mkdir -p "$artifacts_dir"
    
    log i "Processing $ext_count extension(s)..." "$logfile"
    
    for ((j=0; j<ext_count; j++)); do
        local extension_name=$(echo "$extensions_json" | jq -r ".[$j].name")
        local major_version=$(echo "$extensions_json" | jq -r ".[$j].major_version // empty")
        local minor_version=$(echo "$extensions_json" | jq -r ".[$j].minor_version // empty")
        
        # Resolve version
        local extension_version=$(resolve_version "$extension_name" "$major_version" "$minor_version")
        if [[ $? -ne 0 || -z "$extension_version" ]]; then
            log e "Failed to resolve version for $extension_name, skipping..." "$logfile"
            continue
        fi
        
        log i "Processing extension: $extension_name (version: $extension_version)" "$logfile"
        
        local extension_id="${extension_name}/${ARCH}/${extension_version}"
        local was_installed="true"
        
        # Check if extension is already installed
        if ! flatpak info --user "$extension_id" > /dev/null 2>&1; then
            log i "Extension $extension_id is not installed. Proceeding with installation." "$logfile"
            was_installed="false"
        else
            log i "Extension $extension_id is already installed." "$logfile"
        fi
        
        # Install or update the extension
        log i "Installing/updating extension: $extension_id" "$logfile"
        flatpak install --user -y --or-update flathub "$extension_id" || {
            log w "Failed to install extension $extension_id, continuing..." "$logfile"
            continue
        }
        
        # Copy extension files to artifacts
        local extension_path=""
        if [ -d "/var/lib/flatpak/runtime/$extension_name/$ARCH/$extension_version/active/files/" ]; then
            extension_path="/var/lib/flatpak/runtime/$extension_name/$ARCH/$extension_version/active/files/"
        elif [ -d "$HOME/.local/share/flatpak/runtime/$extension_name/$ARCH/$extension_version/active/files/" ]; then
            extension_path="$HOME/.local/share/flatpak/runtime/$extension_name/$ARCH/$extension_version/active/files/"
        fi
        
        if [[ -n "$extension_path" && -d "$extension_path" ]]; then
            local extension_dest="$artifacts_dir/extensions/$(basename $extension_name)-${extension_version}"
            mkdir -p "$extension_dest"
            log i "Copying extension files from $extension_path to $extension_dest" "$logfile"
            cp -rL "$extension_path"/* "$extension_dest/" || log w "Failed to copy extension files" "$logfile"
        else
            log w "Extension path not found for $extension_id" "$logfile"
        fi
        
        # Uninstall the extension if it was not previously installed
        if [[ "$was_installed" == "false" ]]; then
            log i "Uninstalling extension $extension_id as it was not previously installed." "$logfile"
            flatpak uninstall --user -y "$extension_id" || log w "Failed to uninstall $extension_id" "$logfile"
        fi
    done
}

# Function to install and manage a runtime
manage_runtime() {
    local runtime_name="$1"
    local major_version="$2"
    local minor_version="$3"
    
    # Resolve version
    local runtime_version=$(resolve_version "$runtime_name" "$major_version" "$minor_version")
    
    if [[ $? -ne 0 || -z "$runtime_version" ]]; then
        log e "Failed to determine version for $runtime_name, skipping..." "$logfile"
        return 1
    fi
    
    local runtime_id="${runtime_name}/${ARCH}/${runtime_version}"
    
    log i "Managing runtime: $runtime_id" "$logfile"
    
    # Check if runtime is already installed
    local was_installed="true"
    if ! flatpak info --user "$runtime_id" > /dev/null 2>&1; then
        log i "Runtime $runtime_id is not installed. Proceeding with installation." "$logfile"
        was_installed="false"
    else
        log i "Runtime $runtime_id is already installed." "$logfile"
    fi
    
    # Install or update the runtime
    log i "Installing/updating runtime: $runtime_id" "$logfile"
    flatpak install --user -y --or-update flathub "$runtime_id" || {
        log e "Failed to install runtime $runtime_id" "$logfile"
        return 1
    }
    
    # Call gather_plugins to extract the plugins
    log i "Gathering plugins for runtime version $runtime_version..." "$logfile"
    gather_plugins "$runtime_name" "$runtime_version"
    
    # Uninstall the runtime if it was not previously installed
    if [[ "$was_installed" == "false" ]]; then
        log i "Uninstalling runtime $runtime_id as it was not previously installed." "$logfile"
        flatpak uninstall --user -y "$runtime_id" || log w "Failed to uninstall $runtime_id" "$logfile"
    fi
    
    log i "Completed processing runtime $runtime_id" "$logfile"
}

# Main processing loop - read from JSON

# Step 1: Process all plugins
log i "Reading plugins configuration from component_libs.json..." "$logfile"
plugin_count=$(jq '.plugins | length' "$COMPONENT_LIBS_JSON")

for ((i=0; i<plugin_count; i++)); do
    runtime_name=$(jq -r ".plugins[$i].name" "$COMPONENT_LIBS_JSON")
    major_version=$(jq -r ".plugins[$i].major_version // empty" "$COMPONENT_LIBS_JSON")
    minor_version=$(jq -r ".plugins[$i].minor_version // empty" "$COMPONENT_LIBS_JSON")
    
    log i "Processing plugin runtime: $runtime_name (major: ${major_version:-latest}, minor: ${minor_version:-latest})..." "$logfile"
    
    # Manage the runtime (install, extract plugins, cleanup)
    manage_runtime "$runtime_name" "$major_version" "$minor_version"
    
    if [[ $? -ne 0 ]]; then
        log e "Failed to process plugin runtime $runtime_name" "$logfile"
        continue
    fi
done

# Step 2: Process all extensions (independent from plugins)
log i "Reading extensions configuration from component_libs.json..." "$logfile"
extensions_json=$(jq -c '.extensions' "$COMPONENT_LIBS_JSON")

if [[ -n "$extensions_json" && "$extensions_json" != "null" ]]; then
    manage_extensions "$extensions_json"
else
    log d "No extensions defined in configuration" "$logfile"
fi

log i "Shared-libs recipe completed successfully" "$logfile"

source ../automation-tools/assembler.sh
finalize
