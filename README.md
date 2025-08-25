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

### Build RetroDECK Components

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