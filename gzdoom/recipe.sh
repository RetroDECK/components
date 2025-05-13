#!/bin/bash

mkdir gzdoom

git clone https://github.com/flathub/org.zdoom.GZDoom.git

cd org.zdoom.GZDoom

git submodule init

git submodule update

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=gzdoom-repo "gzdoom-build-dir" "org.zdoom.GZDoom.yaml"

rm -rf gzdoom-build-dir/files/lib/debug

cd ..

mv org.zdoom.GZDoom/gzdoom-build-dir/files/bin gzdoom/
mv org.zdoom.GZDoom/gzdoom-build-dir/files/include gzdoom/
mv org.zdoom.GZDoom/gzdoom-build-dir/files/lib gzdoom/
mv org.zdoom.GZDoom/gzdoom-build-dir/files/share gzdoom/

cp component_launcher.sh manifest.json functions.sh prepare_component.sh pcsx2/

chmod +x gzdoom/component_launcher.sh

tar -czf "gzdoom-artifact.tar.gz" "gzdoom"

rm -rf gzdoom
rm -rf org.zdoom.GZDoom
