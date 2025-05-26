#!/bin/bash

# This is out of standard so utils are not used here, maybe we can refactor this later

mkdir -p shared_libs/qt-67

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-67-repo "$component/shared-libs-67-build-dir" "retrodeck.shared-libs.67.yml"

mv $component/shared-libs-67-build-dir/files/lib/* shared_libs/qt-67/

rm -rf $component/shared-libs-67-build-dir $component/shared-libs-67-repo

mkdir -p shared_libs/qt-68

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=$component/shared-libs-68-repo "$component/shared-libs-68-build-dir" "retrodeck.shared-libs.68.yml"

mv $component/shared-libs-68-build-dir/files/lib/* shared_libs/qt-68/

rm -rf $component/shared-libs-68-build-dir $component/shared-libs-68-repo

tar -czf "shared_libs-artifact.tar.gz" "shared_libs"

rm -rf shared_libs
