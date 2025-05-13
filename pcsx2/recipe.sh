#!/bin/bash

wget "https://github.com/PCSX2/pcsx2/releases/download/v2.2.0/pcsx2-v2.2.0-linux-appimage-x64-Qt.AppImage"

chmod +x "pcsx2-v2.2.0-linux-appimage-x64-Qt.AppImage"

$(realpath "pcsx2-v2.2.0-linux-appimage-x64-Qt.AppImage") --appimage-extract

mkdir -p pcsx2

mv mv squashfs-root/apprun-hooks pcsx2/
mv squashfs-root/usr/* pcsx2/
rm -rf squashfs-root

cp component_launcher.sh manifest.json functions.sh prepare_component.sh pcsx2/
chmod +x pcsx2/component_launcher.sh

tar -czf "pcsx2-artifact.tar.gz" "pcsx2"

rm -rf pcsx2
