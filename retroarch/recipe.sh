#!/bin/bash

source "automation-tools/utils.sh"

grab appimage "https://buildbot.libretro.com/stable/*/linux/x86_64/RetroArch.7z"

# custom commands goes here

# Nightly Cores
# As some comres are not available in the stable version, we need to download the nightly cores
# must be earlier than retroarch-cores as it will overwrite this cores with the stable ones
wget "https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch_cores.7z" -O "$WORK_DIR/RetroArch_cores_nightly.7z"
7z x "$WORK_DIR/RetroArch_cores_nightly.7z" -o"$WORK_DIR/cores_nightly"
cp -rf "$WORK_DIR/cores_nightly/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores/"* "$WORK_DIR/cores/"
rm -f "$WORK_DIR/RetroArch_cores_nightly.7z"
rm -rf "$WORK_DIR/cores_nightly"

# Citra Libretro Core
# Citra is removed from the LibretroCores but is still available in Libretro 
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/citra_libretro.so.zip" -O "$WORK_DIR/citra_libretro.so.zip"
unzip -o "$WORK_DIR/citra_libretro.so.zip" -d "$WORK_DIR/cores/"
rm -f "$WORK_DIR/citra_libretro.so.zip"

# Sameduck Libretro Core
# Sameduck is removed from the LibretroCores but is still available in Libretro
wget "https://buildbot.libretro.com/nightly/linux/x86_64/latest/sameduck_libretro.so.zip" -O "$WORK_DIR/sameduck_libretro.so.zip"
unzip -o "$WORK_DIR/sameduck_libretro.so.zip" -d "$WORK_DIR/cores/"
rm -f "$WORK_DIR/sameduck_libretro.so.zip"

# Retroarch Cores
wget "https://buildbot.libretro.com/stable/1.20.0/linux/x86_64/RetroArch_cores.7z" -O $WORK_DIR/RetroArch_cores.7z
7z x $WORK_DIR/RetroArch_cores.7z -o"$WORK_DIR/cores/"
rm -f $WORK_DIR/RetroArch_cores.7z

# RetroArch Cheats
git clone --depth 1 "https://github.com/libretro/libretro-database.git" "$WORK_DIR/libretro-database"
mkdir -p "$WORK_DIR/cht"
cp -rf "$WORK_DIR/libretro-database/cht"/* "$WORK_DIR/cht/"
rm -rf "$WORK_DIR/libretro-database"

finalize