#!/bin/bash

wget "https://github.com/RetroDECK/Duckstation/releases/download/preview/DuckStation-x64.AppImage"

chmod +x "DuckStation-x64.AppImage"

$(realpath "DuckStation-x64.AppImage") --appimage-extract

mkdir -p duckstation

mv squashfs-root/apprun-hooks duckstation/
mv squashfs-root/usr/* duckstation/
rm -rf squashfs-root

cp component_launcher.sh manifest.json functions.sh prepare_component.sh duckstation/
chmod +x duckstation/component_launcher.sh

tar -czf "duckstation-artifact.tar.gz" "duckstation"

rm -rf duckstation
