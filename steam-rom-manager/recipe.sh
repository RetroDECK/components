#!/bin/bash

source "automation-tools/utils.sh"

grab generic "https://github.com/SteamGridDB/steam-rom-manager/releases/latest/download/steam-rom-manager_*_amd64.deb"

# custom commands go here
install -D run.sh "$WORK_DIR/bin/steam-rom-manager"
bsdtar -xf srm.deb data.tar.xz
tar xf data.tar.xz
mv "$WORK_DIR/opt/Steam ROM Manager"/* "$component/artifacts"
rm -rf "$WORK_DIR/usr/share/icons/hicolor/1024x1024"
find "$WORK_DIR/usr/share/icons/hicolor" -type f -exec install -Dm644 "{}" "$component/artifacts/{}" \;

finalize