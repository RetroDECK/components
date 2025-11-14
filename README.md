# RetroDECK Components

This repository contains the components and automation tools for building and managing RetroDECK components.

## Creating a New Component

Follow these steps to create a new emulator or tool component for RetroDECK:

### 1. Plan Your Component

- **Choose a name**: Use lowercase, no spaces (e.g., `myemulator`)
- **Identify the source**: GitHub releases, direct downloads, Flatpak, etc. We always prefer Flatpak as main source if it's updated. We always prefer Flatpak as main source if it's updated.
- **Determine requirements**: Libraries, configurations, presets needed
- **Check existing components**: Look at similar components for reference

### 2. Create Component Directory Structure

Create a new directory for your component:

```bash
mkdir myemulator
cd myemulator
mkdir -p assets/rd_config
```

### 3. Add Version to Desired Versions

Edit `automation-tools/alchemist/desired_versions.sh` and add your component's desired version:

```bash
# MyEmulator – Description
export MYEMULATOR_DESIRED_VERSION="latest"
```

### 4. Create Component Recipe

Create `component_recipe.json` based on the source type. Use templates from `automation-tools/alchemist/templates/`:

**For GitHub releases:**
```json
{
  "myemulator": [
    {
      "source_url": "https://github.com/developer/myemulator/releases/download/{VERSION}/*.AppImage",
      "source_type": "github-release",
      "version": "$MYEMULATOR_DESIRED_VERSION",
      "extraction_type": "appimage",
      "assets": [
        {
          "type": "dir",
          "source": "usr/bin",
          "dest": "bin"
        },
        {
          "type": "dir",
          "source": "$REPO_ROOT/$COMPONENT_NAME/assets/rd_config",
          "dest": "rd_config"
        }
      ],
      "libs": [
        {
          "library": "libQt6Widgets.so.6",
          "runtime_name": "org.kde.Platform",
          "runtime_version": "$DESIRED_QT6_RUNTIME_VERSION",
          "dest": "shared-libs"
        }
      ]
    }
  ]
}
```

**For direct downloads:**
```json
{
  "myemulator": [
    {
      "source_url": "https://example.com/myemulator-{VERSION}-linux.tar.gz",
      "source_type": "http",
      "version": "1.0.0",
      "extraction_type": "archive",
      "assets": [
        {
          "type": "dir",
          "source": "myemulator/bin",
          "dest": "bin"
        },
        {
          "type": "dir",
          "source": "$REPO_ROOT/$COMPONENT_NAME/assets/rd_config",
          "dest": "rd_config"
        }
      ]
    }
  ]
}
```

**For Flatpak:**
```json
{
  "myemulator": [
    {
      "source_url": "org.example.MyEmulator",
      "source_type": "flatpak_id",
      "version": "$MYEMULATOR_DESIRED_VERSION",
      "extraction_type": "flatpak",
      "assets": [
        {
          "type": "dir",
          "source": "bin",
          "dest": "bin"
        },
        {
          "type": "dir",
          "source": "$REPO_ROOT/$COMPONENT_NAME/assets/rd_config",
          "dest": "rd_config"
        }
      ]
    }
  ]
}
```

### 5. Create Component Manifest

Create `component_manifest.json` with metadata and configuration presets. The RetroDECK configurator automatically parses this file to provide preset options to users:

```json
{
  "myemulator": {
    "name": "MyEmulator",
    "url_rdwiki": "https://retrodeck.readthedocs.io/en/latest/wiki_emulator_guides/myemulator/myemulator-guide/",
    "url_webpage": "https://example.com/myemulator",
    "url_source": "https://github.com/developer/myemulator",
    "description": "MyEmulator is an awesome emulator for System X.",
    "system_friendly_name": "System X",
    "system": "systemx",
    "compatible_presets": {
      "ask_to_exit": ["false", "true"]
    },
    "preset_actions": {
      "config_file_format": "ini",
      "ask_to_exit": {
        "confirm_exit": {
          "action": "change",
          "new_setting_value": "true",
          "section": "General",
          "target_file": "$myemulator_config",
          "defaults_file": "$config/myemulator/config.ini"
        }
      }
    }
  }
}
```

**Note**: The `preset_actions` are automatically handled by the RetroDECK configurator - you don't need to implement preset logic in your component scripts.

### 6. Create Component Functions

Create `component_functions.sh` to define configuration paths and helper functions:

```bash
#!/bin/bash

# Configuration file paths
myemulator_config="$XDG_CONFIG_HOME/myemulator/config.ini"
myemulator_data="$XDG_DATA_HOME/myemulator"

# Add any component-specific functions here
myemulator_special_function() {
    # Function implementation
    echo "Special function for MyEmulator"
}
```

### 7. Create Component Launcher

Create `component_launcher.sh` to launch the emulator with proper environment:

```bash
#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set up library paths
export LD_LIBRARY_PATH="$component_path/lib:$ffmpeg_path/25.08:$rd_shared_libs:${LD_LIBRARY_PATH}"

# Set up Qt paths if needed
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

# Launch the emulator
exec "$component_path/bin/myemulator" "$@"
```

### 8. Create Component Prepare Script

Create `component_prepare.sh` for configuration setup and directory creation. This script handles the `retrodeck --reset mycomponent` command:

```bash
#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  # Create config directory
  create_dir -d "$XDG_CONFIG_HOME/myemulator/"

  # Copy default config
  cp -fT "$component_config/config.ini" "$myemulator_config"

  # Set up directories
  set_setting_value "$myemulator_config" "roms_path" "$roms_path/systemx" "myemulator"
  set_setting_value "$myemulator_config" "saves_path" "$saves_path/systemx/myemulator" "myemulator"
  set_setting_value "$myemulator_config" "screenshots_path" "$screenshots_path/systemx/myemulator" "myemulator"

  # Create necessary directories
  create_dir "$saves_path/systemx/myemulator"
  create_dir "$screenshots_path/systemx/myemulator"
fi
```

### 9. Add Default Configuration

Create default configuration files in `assets/rd_config/` directory. These should be "RetroDECK defaults" - configure the component to best fit RetroDECK usage by:

- Removing personal paths (home directories, user-specific locations)
- Setting appropriate default settings for RetroDECK environment
- Configuring paths to use RetroDECK variables ($roms_path, $saves_path, etc.)
- Setting up any RetroDECK-specific presets

```bash
mkdir -p assets/rd_config
# Create default config files with RetroDECK-optimized settings
# Example: config.ini, qt-config.ini, etc.
```

### 9.5. Check and Configure Libraries

To determine which libraries your component needs:

1. **Enter Flatpak shell**:
   ```bash
   flatpak run --command=sh net.retrodeck.retrodeck
   ```

2. **Temporarily modify the launcher** to check libraries:
   - Edit `component_launcher.sh`
   - Change `exec "$component_path/bin/myemulator" "$@"`
   - To: `ldd "$component_path/bin/myemulator" | grep "not found"`

3. **Clean environment for testing**:
   - Delete other components and shared libraries temporarily
   - Each component should be self-contained
   - This prevents `ldd` from finding libraries from other components

4. **Run the modified launcher** to see missing libraries:
   ```bash
   flatpak run --command=sh net.retrodeck.retrodeck
   retrodeck --open mycomponent
   ```

5. **Add missing libraries** to your `component_recipe.json` in the `libs` section

**Tip**: You can edit files directly in the Flatpak location (e.g., `/home/$USER/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files/components/mycomponent`) and save in place to test changes without rebuilding everything.

### 10. Build and Test

Use the Alchemist to build your component:

```bash
cd /path/to/components
./automation-tools/alchemist/alchemist.sh myemulator/component_recipe.json
```

Check the `artifacts/` directory for the built component. For testing, extract the component to the Flatpak components directory:

```bash
# Extract the built artifact to Flatpak components directory for testing
tar -xzf artifacts/myemulator-artifact.tar.gz -C /home/$USER/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files/components/mycomponent
```

### 11. Test Integration

- Test launching the component within Flatpak:
  ```bash
  flatpak run --command=sh net.retrodeck.retrodeck
  retrodeck --open mycomponent
  ```
- Verify that `retrodeck --reset mycomponent` works correctly
- Verify configurations are applied correctly
- Test preset actions through the RetroDECK configurator (presets are automatically handled)
- Ensure paths are set up properly

### 12. Update Framework

If needed, update the RetroDECK framework to recognize your new component by adding entries to:
- Component lists
- System mappings
- Menu configurations

### Additional Tips

- **Use existing components as templates**: Copy and modify similar components
- **Test with small changes**: Build and test incrementally
- **Check the HOWTO**: Read `automation-tools/alchemist/templates/HOWTO.txt` for detailed recipe information
- **Use the hunt_libraries script**: Run `automation-tools/hunt_libraries.sh` to find required libraries
- **Follow naming conventions**: Use consistent naming throughout all files
- **Document your component**: Update the RetroDECK wiki with usage instructions
- **Self-contained components**: Each component should be self-contained with its own libraries to avoid conflicts

## Documentation

Please visit the [The RetroDECK Wiki](https://retrodeck.readthedocs.io/) and go to the RetroDECK Development 🧪 section.

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch for your changes.
3. Submit a pull request.

## License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

