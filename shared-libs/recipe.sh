#!/bin/bash

# This is out of standard so utils are not used here, maybe we can refactor this later

source "automation-tools/utils.sh"

WORK_DIR=$(mktemp -d)
component="shared-libs"

mkdir -p $WORK_DIR/qt-67
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-67-repo "$component/shared-libs-67-build-dir" "retrodeck.shared-libs.67.yml"
mv $component/shared-libs-67-build-dir/files/lib/* $WORK_DIR/qt-67/
rm -rf $component/shared-libs-67-build-dir $WORK_DIR/shared-libs-67-repo

mkdir -p $WORK_DIR/qt-68
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-68-repo "$component/shared-libs-68-build-dir" "retrodeck.shared-libs.68.yml"
mv $component/shared-libs-68-build-dir/files/lib/* $WORK_DIR/qt-68/
rm -rf $component/shared-libs-68-build-dir $WORK_DIR/shared-libs-68-repo

finalize