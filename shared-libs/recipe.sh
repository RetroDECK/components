#!/bin/bash

# This is out of standard so utils are not used here, maybe we can refactor this later

source "automation-tools/assembler.sh"

WORK_DIR=$(mktemp -d)
component="shared-libs"
version=""                  # Needed for finalize function

mkdir -p $WORK_DIR/artifacts/qt-67
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-67-repo "$component/shared-libs-67-build-dir" "$component/retrodeck.shared-libs.67.yml"
mv $component/shared-libs-67-build-dir/files/lib/* $WORK_DIR/artifacts/qt-67/
rm -rf $component/shared-libs-67-build-dir $WORK_DIR/shared-libs-67-repo
version="6.7"

mkdir -p $WORK_DIR/artifacts/qt-68
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-68-repo "$component/shared-libs-68-build-dir" "$component/retrodeck.shared-libs.68.yml"
mv $component/shared-libs-68-build-dir/files/lib/* $WORK_DIR/artifacts/qt-68/
rm -rf $component/shared-libs-68-build-dir $WORK_DIR/shared-libs-68-repo
version="$version, 6.8"

finalize