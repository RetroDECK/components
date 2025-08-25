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

Some components may require additional shared libraries that are not included in the standard freedesktop runtime or shared-libs. These libraries are now automatically processed during the build.

#### Required Libraries File
Create a `required_libraries.txt` file in your component directory to specify additional libraries needed by your component. The file supports multiple formats:

**Format 1: Manual Library List**
```plaintext
# This file lists libraries required by this component
# Comments starting with # are ignored

# Qt6 libraries
libQt6Core.so.6
libQt6Gui.so.6
libQt6Widgets.so.6
libQt6Network.so.6
libQt6Multimedia.so.6

# Other required libraries
libslirp.so.0
libSDL2-2.0.so.0

# Qt plugins (directory structure)
plugins/imageformats
plugins/platforms
plugins/xcbglintegrations
```

**Format 2: LDD Output (Recommended)**
You can directly paste the output of `ldd` command - all libraries will be processed:
```plaintext
# Output from: ldd /app/retrodeck/components/melonds/bin/melonDS
	linux-vdso.so.1 (0x00007562e4576000)
	libX11.so.6 => /usr/lib/x86_64-linux-gnu/libX11.so.6 (0x00007562dccb4000)
	libEGL.so.1 => /usr/lib/x86_64-linux-gnu/libEGL.so.1 (0x00007562e4553000)
	libQt6Multimedia.so.6 => not found
	libSDL2-2.0.so.0 => /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0 (0x00007562dcad2000)
	/lib64/ld-linux-x86-64.so.2 (0x00007562e4578000)
	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007562dc600000)
```
*Note: Supports both standard format (`name => path`) and dynamic linker format (`/path`)*

#### Automatic Library Processing
Libraries are now automatically processed during the build:

1. **Detection**: The build system automatically detects `required_libraries.txt` in your component directory
2. **Parsing**: Supports both manual lists and `ldd` output formats
3. **Processing**: Extracts all library names from the file (no filtering applied)
4. **Resolution**: Uses `search_libs.sh` to find and copy libraries from available runtimes
5. **Integration**: Libraries are automatically included in the component artifact

#### Library Management Process
1. **Identify Missing Libraries**: Run `ldd` on your main executable to identify missing libraries
2. **Check Shared Libraries**: Verify if libraries are available in `shared-libs` component
3. **Create Required Libraries File**: Add either the `ldd` output or manual library list to `required_libraries.txt`
4. **Automatic Processing**: Libraries are automatically copied during build via `finalize()` function

#### Example Component with Libraries
```bash
#!/bin/bash

source "automation-tools/assembler.sh"

# Download and process the component
assemble flatpak_id "org.example.Component"

# Custom Commands (optional)
# Any additional processing...

# Finalize - this automatically processes required_libraries.txt
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

#### Advanced Usage
For more control over library processing, you can still manually handle libraries in your recipe:

```bash
#!/bin/bash

source "automation-tools/assembler.sh"

# Download and process the component
assemble flatpak_id "org.example.Component"

# Optional: Manual library handling before automatic processing
mkdir -p "$component/artifacts/lib"
cp /custom/path/special_library.so "$component/artifacts/lib/"

# Finalize automatically processes required_libraries.txt
finalize
```

#### Notes
- Libraries in `required_libraries.txt` are **automatically processed** during `finalize()`
- Both manual library lists and `ldd` output formats are supported
- Comments starting with `#` are ignored in the file
- Plugin directories can be specified with `plugins/` prefix
- **All libraries from ldd output are processed** (no filtering for "not found")
- The system automatically searches standard library paths for libraries
- Deduplication occurs at the repository level, so all libraries are processed locally
- Manual library copying can still be done before calling `finalize()` for special cases
- Test your component thoroughly to ensure all required libraries are properly included

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
Additional libraries needed by individual components are specified in `required_libraries.txt` files within each component directory. These libraries are now:
- **Automatically processed** during the build process via the `finalize()` function
- Sourced from available runtime environments (searches /app, /usr/lib, /usr/lib64, etc.)
- Included in the component's artifact package automatically
- Support both manual library lists and `ldd` command output formats

### Library Resolution Process
1. Check if library exists in shared-libs
2. If not found, create/update component's `required_libraries.txt`
3. **Automatic library copying** during build when `finalize()` is called
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