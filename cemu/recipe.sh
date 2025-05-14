#!/bin/bash

wget "https://github.com/cemu-project/Cemu/releases/download/v2.6/Cemu-2.6-x86_64.AppImage"

chmod +x "Cemu-2.6-x86_64.AppImage"

$(realpath "Cemu-2.6-x86_64.AppImage") --appimage-extract

mkdir -p cemu

mv squashfs-root/apprun-hooks cemu/
mv squashfs-root/usr/* cemu/
rm -rf squashfs-root

# This component appears to run fine with only this library included, so removing all others to save on space
find cemu/lib/ -not -name 'libGLU.so.1' -delete

cp component_launcher.sh manifest.json functions.sh prepare_component.sh cemu/
chmod +x cemu/component_launcher.sh

tar -czf "cemu-artifact.tar.gz" "cemu"

rm -rf cemu
