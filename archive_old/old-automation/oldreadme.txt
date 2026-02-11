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

## Shared Libraries Component

RetroDECK uses a centralized `shared-libs` component to manage common runtime dependencies like Qt frameworks and platform extensions. This component automatically installs and extracts plugins from Flatpak runtimes.

### Configuration

The `shared-libs` component is configured via `component_libs.json` which defines:

1. **Plugins**: Flatpak runtime platforms to install and extract plugins from (e.g., Qt runtimes)
2. **Extensions**: Additional Flatpak runtime extensions (like ffmpeg, codecs, etc.)

### component_libs.json Structure

```json
{
  "plugins": [
    {
      "name": "org.kde.Platform",
      "major_version": "5",
      "minor_version": "latest"
    },
    {
      "name": "org.kde.Platform",
      "major_version": "6",
      "minor_version": "latest"
    }
  ],
  "extensions": [
    {
      "name": "org.freedesktop.Platform.ffmpeg-full",
      "major_version": "24",
      "minor_version": "latest"
    }
  ]
}
```

#### Plugins Section

Each plugin entry requires:
- **name**: Flatpak runtime name (e.g., "org.kde.Platform", "org.gnome.Platform")
- **major_version**: Major version number (e.g., "5", "6") or "latest" for absolute latest
- **minor_version**: Minor version number (e.g., "15", "9") or "latest" to auto-resolve the latest minor version, or omit entirely (defaults to "latest")

The script automatically resolves version numbers:
- If `major_version` is "latest" or omitted: finds the absolute latest version
- If `minor_version` is "latest" or omitted: finds the latest minor version for the specified major version
- If both are specified: uses the exact version

**Examples:**
```json
// Latest Qt 6.x (will find 6.9, 6.10, etc.)
{"name": "org.kde.Platform", "major_version": "6", "minor_version": "latest"}

// Specific version Qt 5.15
{"name": "org.kde.Platform", "major_version": "5", "minor_version": "15"}

// Absolute latest available
{"name": "org.kde.Platform", "major_version": "latest"}

// Omit minor_version (same as "latest")
{"name": "org.kde.Platform", "major_version": "6"}
```

#### Extensions Section

Each extension entry requires:
- **name**: Full Flatpak extension name
- **major_version**: Major version number or "latest"
- **minor_version**: Minor version number or "latest" (can be omitted)

Extensions are independent from runtimes and have their own versioning system.

**Examples:**
```json
// Latest 24.x version
{"name": "org.freedesktop.Platform.ffmpeg-full", "major_version": "24", "minor_version": "latest"}

// Specific version
{"name": "org.freedesktop.Platform.ffmpeg-full", "major_version": "24", "minor_version": "08"}

// Absolute latest
{"name": "org.freedesktop.Platform.ffmpeg-full", "major_version": "latest"}
```

### Finding Available Runtimes and Extensions

To discover available runtimes and extensions on your system, use these Flatpak commands:

**List all available Qt runtimes (for plugins):**
```bash
flatpak remote-ls --runtime flathub | grep -i "org.kde.Platform"
```

**List all available extensions:**
```bash
flatpak remote-ls --runtime flathub | grep -i "extension\|ffmpeg\|codec"
```

**Get detailed information about a specific runtime/extension:**
```bash
flatpak info --user org.kde.Platform/x86_64/6.9
flatpak info --user org.freedesktop.Platform.ffmpeg-full/x86_64/24.08
```

**List installed runtimes on your system:**
```bash
flatpak list --runtime --user
flatpak list --runtime --system
```

### Adding Custom Plugins or Extensions

To add a new plugin or extension to shared-libs:

1. **For a new plugin runtime**, add to the `plugins` array:
```json
{
  "name": "org.kde.Platform",
  "major_version": "7",
  "minor_version": "latest"
}
```

Or with a specific version:
```json
{
  "name": "org.gnome.Platform",
  "major_version": "46",
  "minor_version": "2"
}
```

2. **For a new extension**, add to the `extensions` array:
```json
{
  "name": "org.freedesktop.Platform.GL.mesa-git",
  "major_version": "latest"
}
```

Or with specific versions:
```json
{
  "name": "org.freedesktop.Platform.GL.nvidia",
  "major_version": "24",
  "minor_version": "08"
}
```

### How It Works

The shared-libs recipe:
1. Reads configuration from `component_libs.json`
2. Resolves "latest" versions to actual version numbers
3. **Processes plugins**: Installs each runtime temporarily (if not already installed), extracts plugins and libraries
4. **Processes extensions**: Installs extensions and copies their files to artifacts
5. Cleans up by removing temporarily installed runtimes/extensions
6. Packages everything into the `shared-libs` artifact

### Troubleshooting

If a component is missing libraries:
1. Check which Qt version the component uses (inspect `component_launcher.sh`)
2. Ensure the corresponding runtime is listed in `shared-libs/component_libs.json` under `plugins`
3. If the component needs special extensions (like ffmpeg), add them to the extensions list
4. Rebuild the shared-libs component

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
├── component_libs.json          # Optional: Component-specific library requirements
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
"url_donation": " ", 
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

### 7. Managing Component-Specific Libraries

Most common libraries (Qt frameworks, standard system libraries) are provided by the `shared-libs` component. However, some components may require additional specific libraries.

#### Using component_libs.json

If your component needs specific library versions from Flatpak runtimes, create a `component_libs.json` file:

```json
[
  {
    "library": "libQt6Widgets.so.6",
    "qt_version": "6.9",
    "subfolder": "qt6"
  },
  {
    "library": "libevdev.so.2",
    "runtime_name": "org.gnome.Platform",
    "subfolder": "48"
  },
  {
    "library": "libusb-1.0.so.0",
    "runtime_name": "org.freedesktop.Platform",
    "subfolder": "25.08"
  },
  {
    "library": "libcustom.so.1",
    "source": "mycomponent/lib",
    "subfolder": "component-libs"
  }
]
```

**Library source types:**
- **qt_version**: Extract from Qt runtime (managed by shared-libs)
- **runtime_name**: Extract from specific Flatpak runtime
- **source**: Copy from local component directory

#### Library Integration in Launcher

Update your `component_launcher.sh` to include component-specific libraries:

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

### 8. Best Practices
- Use `log i "message"` for informational logging
- Handle version detection properly in your sources
- Test with both `--force` and `--dry-run` flags
- Include only necessary files to keep artifacts small
- Document any special requirements in comments
- Use `--even` to include additional required files/directories

### Component Libraries Management

RetroDECK uses a centralized library management system:

#### Shared Libraries
Common libraries (Qt frameworks, standard system libraries) are managed centrally in the `shared-libs` component. These libraries are automatically available to all components through the `$rd_shared_libs` path.

The shared-libs component handles:
- Qt 5 and Qt 6 runtime libraries and plugins
- Common Flatpak extensions (ffmpeg, codecs, etc.)
- Platform-specific libraries

#### Component-Specific Libraries
Individual components may require additional libraries not provided by shared-libs. These are managed through `component_libs.json` files in each component directory.

## Troubleshooting Component Library Issues

Once you have added a new component and it builds correctly, test its integration in RetroDECK by opening the shell and running:

```bash
retrodeck --open component
```

If the component fails to start, check the error message to identify missing libraries.

### Diagnosing Missing Libraries

Use `ldd` to see all libraries required by the component:

```bash
ldd /app/retrodeck/components/component_name/bin/executable_name
```

**Example output:**
```
libQt6Core.so.6 => /app/lib/libQt6Core.so.6 (0x00007f...)
libfoo.so.1 => not found
libbar.so.2 => /usr/lib/x86_64-linux-gnu/libbar.so.2 (0x00007f...)
```

Libraries marked as "not found" need to be added.

### Resolution Steps

1. **Check if library is in shared-libs**: Most Qt and common libraries are already provided
2. **For missing libraries**: Add them to your component's `component_libs.json`
3. **Rebuild the component**: Run the recipe script again
4. **Test**: Try running the component again

### Creating component_libs.json

Based on the `ldd` output, create a `component_libs.json` file:

```json
[
  {
    "library": "libQt6Core.so.6",
    "qt_version": "6.9",
    "subfolder": "qt6"
  },
  {
    "library": "libfoo.so.1",
    "runtime_name": "org.freedesktop.Platform",
    "subfolder": "24.08"
  }
]
```

### Notes

- This process may require several iterations
- Each missing library error must be resolved individually
- Once stabilized, components rarely break with updates
- Check existing component `component_libs.json` files for examples

## Build RetroDECK Components

The GitHub Actions workflow automatically builds RetroDECK Components when changes are pushed to the repository. You can also trigger the workflow manually using the `workflow_dispatch` event.
