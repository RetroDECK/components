# Alchemist User Guide

The Alchemist is a tool for building component artifacts from JSON recipes. It downloads sources, extracts them, gathers assets, libraries, and extras, and packages everything into a compressed artifact.

## Overview

Alchemist recipes are JSON files that define how to build a component. Each recipe contains sources (downloads), assets (files to gather), libraries (dependencies), and extras (additional files or operations).

## Asset Handlers

Asset handlers process different types of assets and extras in recipes. Each handler supports specific types and performs operations like copying files, creating archives, or running scripts.

### Available Asset Handlers

#### 1. `local` Handler
**Supported Types:** `dir`, `file`, `merge`, `file-rename`

Handles local file operations - copying directories, files, merging directories, and renaming files.

**Examples:**

```json
{
  "assets": [
    {
      "type": "dir",
      "source": "usr/bin",
      "dest": "bin"
    },
    {
      "type": "file",
      "source": "config/app.ini",
      "dest": "config.ini"
    },
    {
      "type": "merge",
      "source": "share/icons",
      "dest": "icons"
    },
    {
      "type": "file-rename",
      "source": "oldname.txt",
      "dest": "newname.txt"
    }
  ]
}
```

- `dir`: Copies entire directory from source to dest
- `file`: Copies single file from source to dest (basename added automatically)
- `merge`: Merges source directory contents into dest directory (non-recursive)
- `file-rename`: Moves/renames a file from source path to dest path

#### 2. `create` Handler
**Supported Types:** `create`

Creates new files, optionally with content.

**Examples:**

```json
{
  "assets": [
    {
      "type": "create",
      "dest": "version.txt",
      "contents": "Version 1.0.0"
    },
    {
      "type": "create",
      "dest": "empty_config.ini"
    }
  ]
}
```

- Creates a file at dest path
- If `contents` is provided, writes that string to the file
- If `contents` is omitted, creates an empty file

#### 3. `symlink` Handler
**Supported Types:** `symlink`

Creates symbolic links.

**Examples:**

```json
{
  "extras": [
    {
      "type": "symlink",
      "source": "config_link",
      "dest": "/app/config"
    }
  ]
}
```

- Creates a symlink at source path pointing to dest path
- Source is relative to `$COMPONENT_ARTIFACT_ROOT` if relative
- Dest should be an absolute path (for Flatpak compatibility)

#### 4. `script` Handler
**Supported Types:** `script`, `source`, `execute`

Runs scripts or sources shell files.

**Examples:**

```json
{
  "extras": [
    {
      "type": "source",
      "source": "setup.sh"
    },
    {
      "type": "execute",
      "source": "build.sh",
      "contents": "--verbose"
    }
  ]
}
```

- `source`: Sources (runs in current shell) the script at source path
- `execute`: Executes the script at source path with optional arguments from contents
- Source path is relative to `$EXTRACTED_PATH` if relative

#### 5. `archive` Handler
**Supported Types:** `archive`, `7z`, `zip`, `tar.gz`, `tgz`, `tar.bz2`, `tbz2`, `tar.xz`, `txz`, `tar`

Creates compressed archives from directories.

**Examples:**

```json
{
  "extras": [
    {
      "type": "tar.gz",
      "source": "data",
      "dest": "backup"
    },
    {
      "type": "zip",
      "source": "configs",
      "dest": "settings"
    }
  ]
}
```

- Creates an archive of the source directory
- Archive type determined by type field
- Output filename will be `dest.type` (e.g., `backup.tar.gz`)
- Supports various compression formats

## Recipe Structure

A complete recipe looks like this:

```json
{
  "component_name": [
    {
      "source_url": "https://example.com/download/v{VERSION}/app.tar.gz",
      "source_type": "http",
      "version": "1.0.0",
      "extraction_type": "archive",
      "assets": [
        {
          "type": "dir",
          "source": "bin",
          "dest": "bin"
        },
        {
          "type": "create",
          "dest": "version.txt",
          "contents": "{VERSION}"
        }
      ],
      "libs": [
        {
          "library": "libQt6Core.so.6",
          "runtime_name": "org.kde.Platform",
          "runtime_version": "6.9",
          "dest": "lib"
        }
      ],
      "extras": [
        {
          "type": "symlink",
          "source": "config",
          "dest": "/app/config"
        }
      ]
    }
  ]
}
```

## Usage

Run the alchemist from the components directory:

```bash
./automation-tools/alchemist/alchemist.sh component_recipe.json
```

The tool will:
1. Parse the recipe
2. Download sources
3. Extract archives
4. Gather assets using appropriate handlers
5. Collect libraries
6. Process extras
7. Create the final artifact archive

## Tips

- Use absolute paths for destinations when possible
- Test recipes with small examples first
- Check the `desired_versions.sh` file for version placeholders
- Use the `hunt_libraries.sh` script to find required libraries
- Archives are created in the working directory
- Symlinks should point to paths valid in the target environment (e.g., Flatpak)