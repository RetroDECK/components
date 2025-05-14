#!/bin/bash

mkdir -p shared_libs/qt-67

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=shared-libs-67-repo "shared-libs-67-build-dir" "retrodeck.shared-libs.67.yml"

mv shared-libs-67-build-dir/files/lib/* shared_libs/qt-67/

rm -rf shared-libs-67-build-dir shared-libs-67-repo

mkdir -p shared_libs/qt-68

flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo=shared-libs-68-repo "shared-libs-68-build-dir" "retrodeck.shared-libs.68.yml"

mv shared-libs-68-build-dir/files/lib/* shared_libs/qt-68/

rm -rf shared-libs-68-build-dir shared-libs-68-repo

tar -czf "shared_libs-artifact.tar.gz" "shared_libs"

rm -rf shared_libs
