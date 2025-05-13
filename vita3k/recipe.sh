#!/bin/bash

wget "https://github.com/Vita3K/Vita3K/releases/download/continuous/Vita3K-x86_64.AppImage"

chmod +x "Vita3K-x86_64.AppImage"

$(realpath "Vita3K-x86_64.AppImage") --appimage-extract

mkdir -p vita3k

mv squashfs-root/usr/* vita3k/
rm -rf squashfs-root

cp component_launcher.sh manifest.json functions.sh prepare_component.sh vita3k/
chmod +x vita3k/component_launcher.sh

tar -czf "vita3k-artifact.tar.gz" "vita3k"

rm -rf vita3k
