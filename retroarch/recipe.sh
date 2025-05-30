#!/bin/bash

source "automation-tools/assembler.sh"

grab appimage "https://buildbot.libretro.com/stable/*/linux/x86_64/RetroArch.7z"

# Custom Commands

# Nightly Cores
# As some comres are not available in the stable version, we need to download the nightly cores
# must be earlier than retroarch-cores as it will overwrite this cores with the stable ones
log i "Downloading RetroArch nightly cores..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch_cores.7z" -O "$WORK_DIR/RetroArch_cores_nightly.7z"
7z x "$WORK_DIR/RetroArch_cores_nightly.7z" -o"$WORK_DIR/cores_nightly"
cp -rf "$WORK_DIR/cores_nightly/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores/"* "$WORK_DIR/cores/"
rm -f "$WORK_DIR/RetroArch_cores_nightly.7z"
rm -rf "$WORK_DIR/cores_nightly"

# Citra Libretro Core
# Citra is removed from the LibretroCores but is still available in Libretro 
log i "Downloading Citra Libretro core..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/citra_libretro.so.zip" -O "$WORK_DIR/citra_libretro.so.zip"
unzip -o "$WORK_DIR/citra_libretro.so.zip" -d "$WORK_DIR/cores/"
rm -f "$WORK_DIR/citra_libretro.so.zip"

# Sameduck Libretro Core
# Sameduck is removed from the LibretroCores but is still available in Libretro
log i "Downloading Sameduck Libretro core..." "$logfile"
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/sameduck_libretro.so.zip" -O "$WORK_DIR/sameduck_libretro.so.zip"
unzip -o "$WORK_DIR/sameduck_libretro.so.zip" -d "$WORK_DIR/cores/"
rm -f "$WORK_DIR/sameduck_libretro.so.zip"

# Retroarch Cores
log i "Downloading RetroArch cores..." "$logfile"
wget "https://buildbot.libretro.com/stable/1.20.0/linux/x86_64/RetroArch_cores.7z" -O $WORK_DIR/RetroArch_cores.7z
7z x $WORK_DIR/RetroArch_cores.7z -o"$WORK_DIR/cores/"
rm -f $WORK_DIR/RetroArch_cores.7z

# RetroArch Cheats
log i "Downloading RetroArch cheats..." "$logfile"
git clone --depth 1 "https://github.com/libretro/libretro-database.git" "$WORK_DIR/libretro-database"
mkdir -p "$WORK_DIR/cht"
cp -rf "$WORK_DIR/libretro-database/cht"/* "$WORK_DIR/cht/"
rm -rf "$WORK_DIR/libretro-database"

# MSX BIOS
log i "Downloading MSX BIOS..." "$logfile"
wget "http://bluemsx.msxblue.com/rel_download/blueMSXv282full.zip" -O "$WORK_DIR/bluemsx.zip"
unzip -o "$WORK_DIR/bluemsx.zip" -d "$WORK_DIR/bluemsx"
mkdir -p "$WORK_DIR/$EXTRAS/MSX"
cp -rf "$WORK_DIR/bluemsx/blueMSXv282full/Machines" "$WORK_DIR/$EXTRAS/MSX/"
cp -rf "$WORK_DIR/bluemsx/blueMSXv282full/Databases" "$WORK_DIR/$EXTRAS/MSX/"
rm -rf "$WORK_DIR/bluemsx/blueMSXv282full"
rm -f "$WORK_DIR/bluemsx.zip"

# Amiga BIOS
log i "Downloading Amiga BIOS..." "$logfile"
wget "https://github.com/rsn8887/capsimg/releases/download/1.1/Capsimg_for_Retroarch.zip" -O "$WORK_DIR/capsimg.zip"
unzip -o "$WORK_DIR/capsimg.zip" -d "$WORK_DIR/capsimg"
mkdir -p "$WORK_DIR/$EXTRAS/Amiga"
cp -r "$WORK_DIR/capsimg/Linux/x86-64/capsimg.so" "$WORK_DIR/$EXTRAS/Amiga/capsimg.so"
rm -rf "$WORK_DIR/capsimg"
rm -f "$WORK_DIR/capsimg.zip"

finalize
