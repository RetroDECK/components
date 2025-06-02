#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://buildbot.libretro.com/stable/*/linux/x86_64/RetroArch.7z"

# Custom Commands

artifacts_dir="$component/artifacts"

# Unfortunately this is a one off as we need to extract even the assets from the same appimage
wget "$url" -O "$WORK_DIR/RetroArch.7z"
7z x "$WORK_DIR/RetroArch.7z" -o"$WORK_DIR"
"$WORK_DIR/RetroArch-Linux-x86_64.AppImage" --appimage-extract
mv "$WORK_DIR/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/"* "$artifacts_dir/"

# Citra Libretro Core
# Citra is removed from the LibretroCores but is still available in Libretro 
log i "Downloading Citra Libretro core..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/citra_libretro.so.zip" -O "$WORK_DIR/citra_libretro.so.zip"
unzip -o "$WORK_DIR/citra_libretro.so.zip" -d "$artifacts_dir/cores/"

# Sameduck Libretro Core
# Sameduck is removed from the LibretroCores but is still available in Libretro
log i "Downloading Sameduck Libretro core..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/sameduck_libretro.so.zip" -O "$WORK_DIR/sameduck_libretro.so.zip"
unzip -o "$WORK_DIR/sameduck_libretro.so.zip" -d "$artifacts_dir/cores/"

# Nightly Cores
# As some comres are not available in the stable version, we need to download the nightly cores
# must be earlier than retroarch-cores as it will overwrite this cores with the stable ones
log i "Downloading RetroArch nightly cores..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch_cores.7z" -O "$WORK_DIR/RetroArch_cores_nightly.7z"
7z x "$WORK_DIR/RetroArch_cores_nightly.7z" -o"$WORK_DIR/cores_nightly"
# Without overwriting the existent cores
cp -rn "$WORK_DIR/cores_nightly/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores/"* "$artifacts_dir/cores/"

# RetroArch Cheats
log i "Downloading RetroArch cheats..." "$logfile"
git clone --depth 1 "https://github.com/libretro/libretro-database.git" "$WORK_DIR/libretro-database"
mkdir -p "$artifacts_dir/cht"
cp -rf "$WORK_DIR/libretro-database/cht"/* "$artifacts_dir/cht/"

# MSX BIOS
log i "Downloading MSX BIOS..." "$logfile"
wget "http://bluemsx.msxblue.com/rel_download/blueMSXv282full.zip" -O "$WORK_DIR/bluemsx.zip"
unzip -o "$WORK_DIR/bluemsx.zip" -d "$WORK_DIR/bluemsx"
mkdir -p "$artifacts_dir/$EXTRAS/MSX"
cp -rf "$WORK_DIR/bluemsx/Machines" "$artifacts_dir/$EXTRAS/MSX/"
cp -rf "$WORK_DIR/bluemsx/Databases" "$artifacts_dir/$EXTRAS/MSX/"

# Amiga BIOS
log i "Downloading Amiga BIOS..." "$logfile"
wget "https://github.com/rsn8887/capsimg/releases/download/1.1/Capsimg_for_Retroarch.zip" -O "$WORK_DIR/capsimg.zip"
unzip -o "$WORK_DIR/capsimg.zip" -d "$WORK_DIR/capsimg"
mkdir -p "$artifacts_dir/$EXTRAS/Amiga"
cp -r "$WORK_DIR/capsimg/Linux/x86-64/capsimg.so" "$artifacts_dir/$EXTRAS/Amiga/capsimg.so"

finalize
