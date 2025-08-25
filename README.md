# RetroDECK Components

This repository contains the and automation tools for building and managing RetroDECK components.

### Why?
This repo is generating artifacts and publish them in new releases.
`main` are labeled as `latest` while `cooker` (dev branch) ones will be not as they are intended for the cooker builds, hence the development channel.

## Component folders structure

Each component directory contains:
- `recipe.sh`: Script to fetch and prepare the component.
- `manifest.json`: A manifest with all the features of the emulator to be read by the RetroDECK Framework
- `artifacts/`: Directory for storing downloaded or built artifacts, this directory is gitignored and cannot be pushed due to the big amount of data it will contain. The products of this folder are available as releases.

## Automation Tools

The `automation-tools/` directory contains scripts to automate tasks such as:
- Fetching the latest releases of components.
- Managing artifacts.
- Building Flatpak packages.

### Key Scripts

- `assembler.sh`: Contains utility functions for managing components. Supports various flags:
  - `--force`: Force download even if version is the same
  - `--dry-run`: Show what would be done without executing
  - `--even <path>`: Include additional directories/files in the artifact (can be used multiple times)
- `grab_releases.sh`: Automates the process of fetching and updating components.

## CI/CD Workflows

The `.github/workflows/` directory contains GitHub Actions workflows for:
- Building RetroDECK.
- Running automated tests.
- Publishing releases.

## How to Use
**NOTE:** during the process the recipes with type `flatpak_id` will actually install flatpaks and then they should remove them, but if something error happens those might not be uninstalled. Be aware of this before runningthe script: in some circumistances the installed flatpak will be retained on your system, and the ones already present will be updated.

### Fetch Latest Releases

Run the following command to fetch the latest releases for all components:

```bash
bash ./automation_tools/grab_releases.sh
```

### Add a New Component

1. Create a new directory for the component.
2. Add a `recipe.sh` script to define how to fetch and prepare the component.
   - Use `assemble <type> <url>` to download and process the component
   - Supported types: `flatpak_id`, `flatpak_artifacts`, `appimage`, `generic`, `local`, `gh_latest_release`
   - Optional flags: `--force`, `--dry-run`, `--even <path>` (to include extra files/directories)
   - Example: `assemble flatpak_id "org.ppsspp.PPSSPP" --even /usr/share/artifacts`
3. Add a `manifest.json` file with metadata for the component.

## Creating a Component - Step by Step Guide

### 1. Directory Structure
Create a new directory with the component name (e.g., `mycomponent/`):
```
mycomponent/
├── recipe.sh                    # Required: Build script
├── component_manifest.json      # Required: Component metadata
├── component_launcher.sh        # Optional: Custom launcher script
├── component_prepare.sh         # Optional: Preparation/configuration script
├── component_functions.sh       # Optional: Component-specific functions
├── required_libraries.txt       # Optional: Additional required libraries
└── rd_config/                   # Optional: Default configuration files
    ├── config.yml
    └── other_configs...
```

### 2. Create recipe.sh
This is the main build script that fetches and prepares the component:

```bash
#!/bin/bash

source "automation-tools/assembler.sh"

# Download and process the component
assemble <type> "<url>" [flags]

# Optional: Add custom commands here
# cp additional_files/* artifacts/

# Finalize the component
finalize
```

**Assembly Types:**
- `flatpak_id`: Extract from installed Flatpak (e.g., `"org.ppsspp.PPSSPP"`)
- `flatpak_artifacts`: Download pre-built Flatpak artifacts
- `appimage`: Extract and process AppImage files
- `generic`: Extract archives (tar.gz, zip, 7z, etc.)
- `local`: Use local files/archives
- `gh_latest_release`: Download from GitHub releases

**Example recipes:**
```bash
# Flatpak component
assemble flatpak_id "org.ppsspp.PPSSPP"

# AppImage with extra files
assemble appimage "https://github.com/example/app/releases/latest/download/App.AppImage" --even /usr/share/extra

# GitHub release with pattern matching
assemble gh_latest_release "owner/repo/*linux*.tar.gz"
```

### 3. Create component_manifest.json
Define component metadata for the RetroDECK framework:

```json
{
  "component_name": {
    "name": "Component Display Name",
    "url_rdwiki": "https://retrodeck.readthedocs.io/path/to/docs/",
    "url_webpage": "https://component-website.com/",
    "url_source": "https://github.com/component/source/",
    "description": "Brief description of the component",
    "system_friendly_name": "System Name",
    "system": "system_id"
  }
}
```

### 4. Optional: component_launcher.sh
Custom launcher script executed when the component is run:

```bash
#!/bin/bash

# Setting component name and path
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set library paths
export LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"

# For Qt applications
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.7/lib/plugins:${QT_PLUGIN_PATH}"

# Launch the component
exec "$component_path/bin/executable_name" "$@"
```

### 5. Optional: component_prepare.sh
Setup script for initial configuration and file preparation:

```bash
#!/bin/bash

component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then
  log i "Preparing $component_name"
  
  # Create config directories
  create_dir "$XDG_CONFIG_HOME/$component_name"
  
  # Copy default configs
  cp -fv "$component_config/config.yml" "$XDG_CONFIG_HOME/$component_name/"
  
  # Setup other initialization tasks
fi
```

### 6. Testing Your Component
1. Make recipe.sh executable: `chmod +x mycomponent/recipe.sh`
2. Run the recipe: `cd mycomponent && ./recipe.sh`
3. Check artifacts: `ls -la artifacts/`
4. Test the generated archive works in RetroDECK

### 7. Managing Required Libraries

Some components may require additional shared libraries that are not included in the standard freedesktop runtime or shared-libs. These libraries need to be manually identified, documented, and included in your component.

#### Required Libraries Documentation
Create a `required_libraries.txt` file in your component directory to document additional libraries needed by your component:

```plaintext
# This file lists libraries required by this component that are not in the freedesktop runtime
# Some are symlinks back to the base library file, but all should be included for compatibility

# For this component, these files can be grabbed from the org.kde.Platform version 6.8 runtime

libicudata.so.73
libicudata.so.73.2
libicui18n.so.73
libicui18n.so.73.2
libQt6Core.so
libQt6Core.so.6
libQt6Core.so.6.7.3

# Qt plugins (directory structure)
plugins/imageformats
libqgif.so
libqico.so
libqjpeg.so

plugins/platforms  
libqxcb.so
```

**Important:** This file is primarily for documentation purposes. The libraries must be manually copied to your component during the build process.

#### Manual Library Management Process
1. **Identify Missing Libraries**: Use tools like `ldd` on the main executable to identify required shared libraries
2. **Check Shared Libraries**: See if the library is already available in the `shared-libs` component (check `shared-libs/shared-libs-6.8.txt`)
3. **Document in Required Libraries**: Add the library name to `required_libraries.txt` for documentation
4. **Manual Copy in Recipe**: Add commands in your `recipe.sh` to manually copy required libraries to `artifacts/lib/`
5. **Include Plugin Directories**: For Qt applications, manually copy necessary plugin directories

#### Manual Library Integration in Recipe
Update your `recipe.sh` to manually copy required libraries:

```bash
#!/bin/bash

source "automation-tools/assembler.sh"

# Download and process the component
assemble flatpak_id "org.example.Component"

# Custom Commands - Manual library copying
log i "Copying required libraries..."

# Create lib directory in artifacts
mkdir -p "$component/artifacts/lib"

# Copy specific required libraries (example paths)
# These paths depend on your build environment
cp /usr/lib/x86_64-linux-gnu/libicudata.so.73* "$component/artifacts/lib/"
cp /usr/lib/x86_64-linux-gnu/libQt6Core.so* "$component/artifacts/lib/"

# Copy Qt plugins if needed
mkdir -p "$component/artifacts/lib/plugins"
cp -r /usr/lib/plugins/imageformats "$component/artifacts/lib/plugins/"
cp -r /usr/lib/plugins/platforms "$component/artifacts/lib/plugins/"

finalize
```

#### Library Integration in Launcher
Update your `component_launcher.sh` to properly set library paths:

```bash
#!/bin/bash

component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set library paths for component-specific libraries
export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs/qt-6.7/lib:${LD_LIBRARY_PATH}"

# For Qt applications, set plugin paths
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.7/lib/plugins:$component_path/lib/plugins:${QT_PLUGIN_PATH}"

# Launch the component
exec "$component_path/bin/executable_name" "$@"
```

#### Using search_libs.sh Tool
You can use the automation tool `search_libs.sh` to help copy libraries:

```bash
#!/bin/bash

source "automation-tools/assembler.sh"
source "automation-tools/search_libs.sh"

# Download and process the component
assemble flatpak_id "org.example.Component"

# Use search_libs to copy libraries from required_libraries.txt
if [[ -f "$component/required_libraries.txt" ]]; then
    export FLATPAK_DEST="$component/artifacts"
    search_libs "$component/required_libraries.txt"
fi

finalize
```

#### Notes
- The `required_libraries.txt` file is primarily for documentation - libraries are NOT automatically copied
- You must manually implement library copying in your `recipe.sh`
- Always include both the base library and its versioned symlinks for maximum compatibility
- Test your component thoroughly to ensure all required libraries are properly included
- The `search_libs.sh` tool can help but must be explicitly called in your recipe

### 8. Best Practices
- Use `log i "message"` for informational logging
- Handle version detection properly in your sources
- Test with both `--force` and `--dry-run` flags
- Include only necessary files to keep artifacts small
- Document any special requirements in comments
- Use `--even` to include additional required files/directories

### Component Libraries Management

RetroDECK uses a two-tier library system:

### Shared Libraries
Common libraries (like Qt frameworks) are managed centrally in the `shared-libs` component:
- `shared-libs-5.15.txt`: Qt 5.15 libraries
- `shared-libs-6.7.txt`: Qt 6.7 libraries  
- `shared-libs-6.8.txt`: Qt 6.8 libraries

These libraries are automatically available to all components through the `$rd_shared_libs` path.

### Component-Specific Libraries
Additional libraries needed by individual components are documented in `required_libraries.txt` files within each component directory. These libraries must be manually:
- Copied during the build process in the component's `recipe.sh`
- Sourced from the specified runtime (e.g., org.kde.Platform)
- Included in the component's artifact package via manual copying or using the `search_libs.sh` tool

### Library Resolution Process
1. Check if library exists in shared-libs
2. If not found, document in component's `required_libraries.txt`
3. Manually copy library from specified runtime during build in `recipe.sh`
4. Set proper `LD_LIBRARY_PATH` in component launcher

## Build RetroDECK Components

The GitHub Actions workflow automatically builds RetroDECK Components when changes are pushed to the repository. You can also trigger the workflow manually using the `workflow_dispatch` event.

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch for your changes.
3. Submit a pull request.

## License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Contact

For questions or support, please visit the [RetroDECK Documentation](https://retrodeck.readthedocs.io/).