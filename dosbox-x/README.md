
# DOSBox‑X Windows 98/3.1 Launcher — Current Design & Usage

This component contains `winplay.sh` — the DOSBox‑X based Windows 9x launcher used by RetroDECK. The README below documents the current, tested implementation and recommended workflows.

Summary of the current approach
- The launcher uses DOSBox‑X's cvhdmake tooling to create *linked differencing children* in the guest runtime (recommended) for per-game write layers. Base image creation / formatting (mkfs) still uses DOSBox‑X's imgmake where required.
- The launcher builds a temporary config file (TMP_CONF) **per run** which is passed last to DOSBox‑X so it overrides the base config when needed.
- Filenames used for per-game layers and saves are sanitized to avoid spaces and problematic characters.

Why this README changed
- Previous flows attempted `vhdmake -diff` for differencing children inside DOSBox‑X; that exposed instabilities in some DOSBox‑X builds (double-free / mount failures). The current, supported runtime approach is to create per-game differencing children from inside DOSBox‑X using `cvhdmake -f -l <parent> <child>` (written into the generated `[autoexec]`). Packaging on the host also uses `cvhdmake` as the single supported host-side packaging tool for differencing children. Base image creation/formatting is still done using `imgmake` / `mkfs` where appropriate.

---

Table of contents
- Key concepts
- Image layering and recommended commands
- Config merging & precedence
- Autoexec sequence created by the launcher
- Troubleshooting and common failures
- Examples

---

Key concepts
- Base image — `win98.vhd` (or `win31.vhd`) shared by all games for that OS.
 - Differencing child — a per-game image that stores only writes relative to the base. The child is created in the guest runtime using `cvhdmake -f -l <parent> <child>` as part of the autoexec; the child is then mounted as C: (so it holds both game files and savedata), keeping the base pristine.
- Save layer — optional per-game save overlay.

Image layering and recommended commands
-------------------------------------
The approach used by the launcher is layered and lightweight:

1) Base OS: `win98.vhd` created once (sparse file, preformatted). Created using `imgmake -t hd -size` (via `winplay.sh --makefs`).
2) Per-run write-layer / differencing child: created inside DOSBox‑X using `cvhdmake -f -l <parent> <child>` (written into the generated `[autoexec]`) and then mounted as C: — this keeps the base image pristine and stores all game data/saves inside the per-game child.

Inside the generated autoexec you will typically see (these lines are written to TMP_CONF — not executed by the host shell):

```
cvhdmake -f -l "/path/to/base.vhd" "/path/to/game_child.vhd"
IMGMOUNT C "/path/to/base.vhd" -b "/path/to/game_child.vhd" -t hdd
IMGMOUNT D "/path/to/game.iso" -t cdrom      # optional
BOOT -l C:
```

- Notes:
- The runtime per-game child is created with `cvhdmake -f -l <parent> <child>` inside the generated `[autoexec]`. This keeps the base image unchanged and stores all writes in the per-game child which is mounted on C: (so it contains both game files and savedata).
- Using `vhdmake -diff` in runtime autoexec is not recommended (it caused crashes in some DOSBox‑X builds) and therefore is avoided.
 - Some DOSBox‑X builds have shown instability when `cvhdmake` or other differencing creation commands run inside the guest (e.g. double‑free in CreateDifferencing). To avoid runtime crashes, `winplay.sh` will attempt to create the per‑game child on the host (using `cvhdmake` invoked from the host DOSBox‑X) before falling back to in‑guest creation. You can also explicitly pre-create the per‑game child on the host with:

```bash
./winplay.sh --package-game "GameName"
```

This is the recommended workaround when the DOSBox‑X runtime in your environment has unreliable in‑guest VHD creation support.
- The child can use any extension recognized by the DOSBox‑X binary in your runtime (`.uhd`, `.vhd`). This script historically uses `.vhd` for compatibility but `.uhd` as an extension is also used; consider consistent extension conventions if you want to change it.

Config merging & precedence
--------------------------
`winplay.sh` constructs a temporary config (`TMP_CONF`) for each run. Current logic:

- If `os_configs/$WIN_VERSION.conf` exists (eg `os_configs/win98.conf`), `TMP_CONF` is created from that file. Otherwise it is created by copying the base config (`$dosbox_x_config`).
- The launcher then removes comments and rewrites an empty `[autoexec]` section in `TMP_CONF` ready to be populated.
- DOSBox‑X is invoked with multiple `-conf` arguments. Order matters — later config files override earlier ones: 

  `dosbox-x -conf /path/to/dosbox-x.conf -conf /path/to/winplay.conf`

Where `winplay.conf` (TMP_CONF) is the last config — its settings will win in case of duplicates.

Autoexec generation and content
------------------------------
`generate_autoexec()` in the script writes a fresh `[autoexec]` block into `TMP_CONF`. The launcher writes the differencing `cvhdmake -f -l <parent> <child>` call into `[autoexec]` and the IMGMOUNT command that mounts the per-game child on C:. The per-game child references the base image internally so the base does not require an explicit drive letter; the launcher then copies the BAT (AutoRun), mounts extra devices (CDs, floppies) and finally writes `BOOT -l C:`. All these commands are written into the config (not run by the host shell).

Filename sanitization
---------------------
To avoid issues caused by spaces and special characters when creating or referencing VHDs, `winplay.sh` sanitizes filenames used for per-game layers and save files. Sanitisation replaces path separators and runs of non-alphanumeric characters with underscores and falls back to `unnamed` if the input is empty.

Troubleshooting
---------------
 - double-free / crash during `vhdmake -diff` — do not use `vhdmake -diff` inside autoexec; create differencing children with `cvhdmake -f -l <parent> <child>` instead. The runtime and packaging flows use `cvhdmake` as the single supported path for differencing children.
- IMGMOUNT cannot create drive from file / sanity check failure — verify the image was created with `imgmake` and that the boot sector and partition table are valid.
- If DOSBox‑X cannot open a logfile or complains about missing logs it may be due to file path variables inside the environment or sandboxing (Flatpak). Not critical for launch but helpful to investigate for debugging.

Examples & quick checks
-----------------------
Example local test to validate config merging (no DOSBox launch required):

```bash
export dosbox_x_config=/tmp/base.conf
export OS_CONFIG_DIR=/tmp/os_configs
export WIN_VERSION=win98
export XDG_CACHE_HOME=/tmp/winplay-test
mkdir -p $XDG_CACHE_HOME/dosbox-x /tmp/os_configs
printf 'dynamic=false
cpu=auto
' > /tmp/base.conf
printf 'dynamic=true
' > /tmp/os_configs/win98.conf
# Launch with a dummy game to trigger config creation (script will write TMP_CONF)
bash ./winplay.sh --game Dummy
# Inspect the generated TMP_CONF; it should contain 'dynamic=true' (OS override wins)
sed -n '1,200p' /tmp/winplay-test/dosbox-x/winplay.conf
```

Contributing & maintainers
--------------------------
If you intend to modify the runtime VHD creation behaviour or change the layering approach, keep these points in mind:

- Prefer `cvhdmake -f -l` for runtime and packaging differencing children. `vhdmake -diff` remains problematic on some DOSBox‑X builds.
- Any change to TMP_CONF construction will impact how runtime overrides behave — ordering of `-conf` is important.
- Keep filename sanitisation behaviour consistent if you add alternate storage locations or extensions.

---

If you want, I can add a diagram showing the final `-conf` order, the `[autoexec]` sequence and an example of how C:/ D:/ E:/ get assigned. Want that as an additional section? 
# DOSBox-X Windows 98/3.1 Game Launcher Setup Guide

This directory contains tools and scripts to set up Windows 98/3.1 environments for DOS gaming in DOSBox-X within RetroDECK.

## VHD Disk Images

### Automatic VHD Creation

VHD disk images are created automatically on first use as **sparse files** in the `$bios_path` folder:
- `$bios_path/win98.vhd` (4GB fixed, FAT32, ~8MB on disk initially)
- `$bios_path/win31.vhd` (512MB fixed, FAT16, ~280KB on disk initially)

**The VHD images are created on-demand** - they don't need to be pre-created or manually placed.

**IMPORTANT - Sparse Files Explained:**
- Your **file manager will show 4GB and 512MB** respectively
- Your **actual disk usage is only ~8.3MB** for both files combined initially
- The empty space is not allocated to disk - DOSBox-X sees the full size, but no space is actually used
- As Windows writes data during installation, the files will grow on disk, but only actual data consumes space

### Disk Size Specifications

| OS | Image | Size | File System | On-Disk Size | Notes |
|---|---|---|---|---|---|
| Windows 98 | win98.vhd | 4GB | FAT32 | ~8MB (sparse) | Maximum era-appropriate for Windows 98 |
| Windows 3.1 | win31.vhd | 512MB | FAT16 | ~280KB (sparse) | FAT16 more reliable than FAT12 for larger disks |

** IMPORTANT - Sparse Files:**

| What You See | What's Real |
|---|---|
| File manager: 4GB + 512MB = 4.5GB total | Actual disk: ~8.3MB total (grows as needed) |
| DOSBox-X sees: Full 4GB + 512MB drives | Filesystem usage: only what's written |

These are **sparse files** - they appear as full size to DOSBox-X but only use actual disk space as Windows writes data to them. Don't be alarmed if your file manager shows 4GB - that's normal for sparse files.

### Manual VHD Creation

To manually create or recreate VHD images, use the `--makefs` argument with `winplay.sh`:

```bash
# Create Windows 98 base image (4GB FAT32)
./winplay.sh --makefs win98

# Create Windows 3.1 base image (512MB FAT16)
./winplay.sh --makefs win31
```

These commands:
1. Create sparse VHD images using `mkfs.fat` with `--mbr=y` flag
   - File manager will show 4GB and 512MB
   - Actual disk usage: only ~8-280KB initially
2. Use proper FAT formatting tool (`mkfs.fat`) for reliability
3. Create proper MBR partition table automatically
4. Create images in `$bios_path/` for use by RetroDECK

The result is a pre-formatted disk image that DOSBox-X recognizes immediately.

**Automatic Creation:**

VHD images are created automatically during first use. Simply run:
```bash
./winplay.sh --install win98 --cd-rom /path/to/WIN98SE.iso
```

If the base VHD doesn't exist, it will be created automatically before installation begins.

**Requirements:** 
- `mkfs.fat` binary available at `$component_path/bin/mkfs.fat` (inside flatpak)
- Or system-wide at `/usr/sbin/mkfs.fat` (for testing outside flatpak)

## Quick Start

### 1. Create Windows 98 Base (Optional)

The base VHD will be created automatically, but you can pre-create it:

```bash
./winplay.sh --makefs win98
```

This creates a 4GB FAT32 sparse VHD at `$bios_path/win98.vhd`

### 2. Install Windows 98

Using the `winplay.sh` script:

```bash
./winplay.sh --install win98 --cd-rom /path/to/WIN98SE.iso
```

This will:
1. Create win98.vhd automatically if it doesn't exist
2. Mount it as C: drive
3. Mount the Windows 98 CD-ROM as D: drive
4. Start Windows 98 Setup

User can now complete the installation

### 2. Install Games

Once Windows 98 is installed:

```bash
./winplay.sh --install "GameName" --cd-rom /path/to/game.iso
```

### 3. Launch Games

```bash
./winplay.sh win98 "GameName"
```

All this is integrated in the Configurator however, so the users should just use the Configurator function to install the Windows versions and then the games.

## Architecture

### VHD Layering System

The system uses a **3-layer VHD stacking architecture** for efficient storage and game isolation:

```
Layer 1 (Base OS):     win98.vhd          ← Shared by all games
                                           ← Windows 98 OS installation (read-mostly)
                                           ← Size: 4GB (sparse, ~512MB-1GB typical)
       ↓
Layer 2 (Game):        gamename.vhd       ← Game-specific layer
                                           ← Game files and settings
                                           ← Size: Variable per game
       ↓
(Two-layer model) The design uses only:
 - Base OS (win98.vhd) and
 - Per‑game child image (gamename.vhd) which holds both game files and user data
```

### How Layering Works

1. **Layer 1 (Base OS)** - `win98.vhd`
   - Contains the Windows 98 operating system
   - Pre-formatted and shared across all games
   - Mounted as read-mostly (changes are sparse)
   - Size: 4GB fixed (sparse file, minimal disk usage)

2. **Layer 2 (Game-specific)** - `gamename.vhd`
   - Contains game files and game-specific configurations
   - Created fresh for each game
   - Mounted on top of the base OS
   - Size: Variable based on game files

3. **(Removed)** - Separate save data layer is not used. Saves are stored inside the per-game VHD.

### Storage & Distribution

| Layer | Location | Purpose | Size | Distribution |
|---|---|---|---|---|
| Base OS | `$bios_path/win98.vhd` | Shared Windows 98 OS | 4GB sparse | Included with RetroDECK |
| Game Layer | `$roms_path/<ESDE_SYSTEM_NAME>/<game>.vhd` | Game-specific files (layered VHD) | Variable | Per-game package |
| (No separate saves layer) | `N/A` | User save files live inside the per-game VHD | variable | User-specific |

### IMGMOUNT Configuration

The `winplay.sh` script uses DOSBox-X's IMGMOUNT command with geometry specification:

```bash
# During OS installation
IMGMOUNT C "$VHD_BASE_PATH" -t hdd -geometry 512 63 255 -size 512,63,255,65

# During game installation (with game layer)
IMGMOUNT C "$VHD_BASE_PATH" -b "$game_layer" -t hdd -geometry 512 63 255 -size 512,63,255,65

# During game launch (base + per-game child)
IMGMOUNT C "$VHD_BASE_PATH" -b "$game_layer" -t hdd -geometry 512 63 255 -size 512,63,255,65
```

**Parameters:**
- `-t hdd` - Mount as hard drive
- `-b` - Stack additional layers (can be repeated)
- `-geometry 512 63 255` - Explicit disk geometry (512 bytes/sector, 63 sectors/track, 255 heads)
- `-size 512,63,255,65` - Geometry specification for proper detection

## File Structure

## File Structure

```
dosbox-x/
├── assets/
│   ├── winplay.sh                        # Main launcher script (with integrated mkfs functions)
│   ├── create_formatted_vhd.sh           # Standalone script for batch VHD creation (optional)
│   └── README.md                         # This file
├── bin/
│   └── mkfs.fat                          # mkfs.fat binary (from dosfstools, bundled)
├── component_functions.sh
├── component_launcher.sh
├── component_manifest.json
├── component_prepare.sh
├── component_recipe.json
└── ...
```

## How it Works

### VHD Image Generation

The `winplay.sh` script includes integrated functions `mkfs_win98()` and `mkfs_win31()` that create pre-formatted VHD images:

1. **Creates sparse files** - Only actual data uses disk space (~8-280KB initially)
   - File manager shows full size (4GB/512MB)
   - Actual disk usage grows as Windows writes data
2. **Uses mkfs.fat** - Proper FAT formatting tool ensures reliability
   - Automatically finds mkfs.fat at `$component_path/bin/mkfs.fat` (inside flatpak)
3. **Creates MBR + FAT table** - Uses `mkfs.fat --mbr=y` for proper partition table
4. **Automatic on first use** - VHD is created automatically if missing during `--install`

The result is a pre-formatted disk image that DOSBox-X and Windows recognize immediately.

### winplay.sh Launcher

The `winplay.sh` script orchestrates the entire workflow:

**Modes of operation (how drives map):**

1. **Install OS** (`--install win98`)
   - Mounts base VHD (Layer 1) as C: for installation
   - Mounts Windows 98 CD-ROM as D: during the install
   - Runs Windows Setup
   - Creates formatted OS installation

2. **Install Game** (`--install GameName`)
   - Ensures base VHD (Layer 1) is present
   - Prepares the per-game child VHD path (Layer 2) but the actual child is created in the guest runtime when first launched
   - Mounts CD-ROM(s) on D: (or the next available drive) to run the installer inside Windows
   - Installer should be run with the per-game child mounted as C: (the child contains OS+game during runtime)

3. **Launch Game** (`win98 GameName`)
   - Runtime will ensure a per-game writeable child exists and mount that child as C: (C: holds OS+game+saves)
   - Additional hard disks and CD-ROM images supplied to the launcher will be mounted starting at D: (D, E, F ...)
   - Boots into Windows and runs the launcher BAT from C:

## Troubleshooting

### "IMGMOUNT: cannot create drive from file" with "Sanity check fail: Root directory count == 0"

**Problem:** DOSBox-X cannot recognize the VHD format because the BIOS Parameter Block (BPB) in the boot sector is invalid.

**Solution:** This issue has been fixed in the current `create_formatted_vhd.py` script. The BPB now includes:
- Proper **Root directory count**: 224 for FAT12 (not 0)
- Correct **Media descriptor**: 0xF0 for FAT12, 0xF8 for FAT32
- Valid **FAT count**: 2 (two copies for redundancy)
- Proper **32-bit total sectors** field for disks larger than 64KB

If you're still seeing this error:
1. Delete the old images: `rm vhd_images/*.vhd`
2. Regenerate them: `python3 create_formatted_vhd.py ./vhd_images/`
3. Verify the boot sector signature: `hexdump -C vhd_images/win31.vhd | head -5`
   - Should show `eb 3c 90 4d 53 44 4f 53` at offset 0x7e00 (sector 63)

### "IMGMOUNT: cannot create drive from file"

This indicates DOSBox-X cannot read the VHD format. Solutions:

1. Verify VHD signature (should start with `eb 3c 90 4d 53 44 4f 53`):
   ```bash
   hexdump -C vhd_images/win98.vhd | head -1
   ```

2. Regenerate the images:
   ```bash
   python3 create_formatted_vhd.py ./vhd_images/
   ```

3. Verify DOSBox-X version supports raw VHD images (v0.75.0+)

### "No partition in use in MBR"

The VHD's MBR partition table is invalid. Regenerate:

```bash
python3 create_formatted_vhd.py ./vhd_images/
```

### Windows 98 doesn't recognize the drive

Make sure the geometry parameters are correct in winplay.sh:

```bash
IMGMOUNT C ... -geometry 512 63 255 -size 512,63,255,65
```

These parameters help DOSBox-X properly detect the disk.

## Storage Locations in RetroDECK

| Component | Path | Purpose |
|---|---|---|
| Base OS VHD | `$bios_path/win98.vhd` | Shared Windows 98 OS |
| Game Layer | `$roms_path/<ESDE_SYSTEM_NAME>/<game>.vhd` | Game-specific files (layered VHD) |
| (No separate saves layer) | `N/A` | User save files live inside the per-game VHD |

## Technical Details

### Sparse File Format

Sparse files are a filesystem feature where unwritten sections don't consume disk space:

```
win98.vhd File Structure:
├── MBR (512 bytes) - written to disk ✓
├── Padding (63*512 bytes) - written to disk ✓
├── Boot sector (512 bytes) - written to disk ✓
├── FAT structures (~2KB) - written to disk ✓
├── [3.99 GB of empty space] - NOT written to disk ✗ ← Sparse area!
└── End marker (1 byte) - written to disk ✓
```

**Result - Dual Perspective:**

| Perspective | Size | Notes |
|---|---|---|
| **File Manager** | 4GB | Shows apparent/logical size |
| **Actual Disk** | ~40KB | Only written sections use space |
| **DOSBox-X** | 4GB | Sees the full size |
| **Growing** | Dynamic | Expands automatically as Windows writes data |

**Why This Matters:**
- You can distribute a 4GB disk image using only 40KB download
- No need to pre-allocate 4GB on your hard drive when installing
- As Windows 98 installation progresses, the file grows on disk (only using space for actual data)
- You never waste 4GB for a disk that only uses 500MB of data

### Disk Geometry

DOSBox-X needs proper disk geometry for correct operation:

| Parameter | Value | Purpose |
|---|---|---|
| Bytes per sector | 512 | Standard sector size |
| Sectors per track | 63 | CHS addressing limit |
| Heads | 255 | CHS addressing limit |
| Size spec | 512,63,255,65 | DOSBox-X geometry detection |

These values represent a standard IDE drive configuration from the Windows 98 era.

### FAT Filesystem Initialization

Each VHD includes proper FAT initialization:

**FAT32 (Windows 98):**
- Boot sector with extended BPB
- Two FAT tables for redundancy
- FSInfo sector for free space tracking
- Root directory at cluster 2

**FAT16 (Windows 3.1):**
- Boot sector with extended BPB
- Two FAT tables for redundancy
- Root directory in fixed location
- Media descriptor: 0xF8 (fixed media)
- Supports up to 2GB (512MB practical for Windows 3.1)
- Created with `mkfs.fat -F 16 --mbr=y`


## See Also

- `winplay.sh --help` - Detailed usage and examples
- RetroDECK Documentation - https://github.com/RetroDECK/RetroDECK
- DOSBox-X Documentation - https://dosbox-x.com/
- DOSBox-X GitHub Issues - https://github.com/joncampbell123/dosbox-x/issues
