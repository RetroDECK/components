#!/bin/bash

mkdir ppsspp

git clone https://github.com/flathub/org.ppsspp.PPSSPP.git

cd org.ppsspp.PPSSPP

git submodule init

git submodule update

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=ppsspp-repo "ppsspp-build-dir" "org.ppsspp.PPSSPP.yml"

rm -rf ppsspp-build-dir/files/lib/debug

cd ..

mv org.ppsspp.PPSSPP/ppsspp-build-dir/files/bin ppsspp/
mv org.ppsspp.PPSSPP/ppsspp-build-dir/files/lib ppsspp/
mv org.ppsspp.PPSSPP/ppsspp-build-dir/files/share/ppsspp/assets ppsspp/bin/
mv org.ppsspp.PPSSPP/ppsspp-build-dir/files/share ppsspp/

rm -rf ppsspp/share/ppsspp

wget https://github.com/Saramagrean/CWCheat-Database-Plus-/blob/master/cheat.db

mv cheat.db ppsspp/

cp component_launcher.sh manifest.json functions.sh prepare_component.sh ppsspp/

chmod +x ppsspp/component_launcher.sh

tar -czf "ppsspp-artifact.tar.gz" "ppsspp"

rm -rf ppsspp
rm -rf org.ppsspp.PPSSPP
