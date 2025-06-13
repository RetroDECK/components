#!/bin/bash

# This is out of standard so utils are not used here, maybe we can refactor this later

source "automation-tools/assembler.sh"

WORK_DIR=$(mktemp -d)
component="shared-libs"
version=""                  # Needed for finalize function

rm -rf "$component/artifacts"
mkdir -p "$component/artifacts"

echo "Using WORK_DIR: $WORK_DIR"
echo "Artifacts will be stored in: $component/artifacts"

mkdir -p "$component/artifacts/qt-5.15/lib"
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$WORK_DIR/shared-libs-5.15-repo --state-dir="$WORK_DIR/.flatpak-builder" "$WORK_DIR/shared-libs-5.15-build-dir" "$component/shared-libs.5.15.yml"
echo "Listing /lib folder:"
ls -lah $WORK_DIR/shared-libs-5.15-build-dir/files/lib # DEBUG
echo "Listing /usr/lib/plugins folder:"
ls -lah $WORK_DIR/shared-libs-5.15-build-dir/files/usr/lib/plugins # DEBUG
cp -rL $WORK_DIR/shared-libs-5.15-build-dir/files/lib/* $component/artifacts/qt-5.15/lib
cp -rL $WORK_DIR/shared-libs-5.15-build-dir/files/usr/lib/plugins $component/artifacts/qt-5.15/lib/
version="5.15"

mkdir -p "$component/artifacts/qt-6.7/lib"
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$WORK_DIR/shared-libs-6.7-repo --state-dir="$WORK_DIR/.flatpak-builder" "$WORK_DIR/shared-libs-6.7-build-dir" "$component/shared-libs.6.7.yml"
echo "Listing /lib folder:"
ls -lah $WORK_DIR/shared-libs-6.7-build-dir/files/lib # DEBUG
echo "Listing /usr/lib/plugins folder:"
ls -lah $WORK_DIR/shared-libs-6.7-build-dir/files/usr/lib/plugins # DEBUG
cp -rL $WORK_DIR/shared-libs-6.7-build-dir/files/lib/* $component/artifacts/qt-6.7/lib
cp -rL $WORK_DIR/shared-libs-6.7-build-dir/files/usr/lib/plugins $component/artifacts/qt-6.7/lib/
version="$version, 6.7"

mkdir -p "$component/artifacts/qt-6.8/lib"
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$WORK_DIR/shared-libs-6.8-repo --state-dir="$WORK_DIR/.flatpak-builder" "$WORK_DIR/shared-libs-6.8-build-dir" "$component/shared-libs.6.8.yml"
echo "Listing /lib folder:"
ls -lah $WORK_DIR/shared-libs-6.8-build-dir/files/lib # DEBUG
echo "Listing /usr/lib/plugins folder:"
ls -lah $WORK_DIR/shared-libs-6.8-build-dir/files/usr/lib/plugins # DEBUG
cp -rL $WORK_DIR/shared-libs-6.8-build-dir/files/lib/* $component/artifacts/qt-6.8/lib
cp -rL $WORK_DIR/shared-libs-6.8-build-dir/files/usr/lib/plugins $component/artifacts/qt-6.8/lib/
version="$version, 6.8"

finalize