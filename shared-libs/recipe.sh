#!/bin/bash

# This is out of standard so utils are not used here, maybe we can refactor this later

source "automation-tools/assembler.sh"

WORK_DIR=$(mktemp -d)
component="shared-libs"
version=""                  # Needed for finalize function

mkdir -p $WORK_DIR/artifacts/qt-6.7/lib
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$WORK_DIR/shared-libs-6.7-repo "$WORK_DIR/shared-libs-6.7-build-dir" "$component/retrodeck.shared-libs.6.7.yml"
mv $WORK_DIR/shared-libs-6.7-build-dir/files/lib/* $WORK_DIR/artifacts/qt-6.7/lib
version="6.7"

mkdir -p $WORK_DIR/artifacts/qt-6.8/lib
flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$WORK_DIR/shared-libs-6.8-repo "$WORK_DIR/shared-libs-6.8-build-dir" "$component/retrodeck.shared-libs.6.8.yml"
mv $WORK_DIR/shared-libs-6.8-build-dir/files/lib/* $WORK_DIR/artifacts/qt-6.8/lib
version="$version, 6.8"

finalize