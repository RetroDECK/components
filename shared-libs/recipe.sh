#!/bin/bash

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

# Ensure logfile is set and exported for all log calls
if [ -z "$logfile" ]; then
    export logfile="assemble.log"
else
    export logfile
fi

# This is out of standard, so utils are not used here. Maybe we can refactor this later.

source "automation-tools/assembler.sh"

WORK_DIR=$(mktemp -d)
component="shared-libs"
version=""                  # Needed for finalize function

rm -rf "$component/artifacts"
mkdir -p "$component/artifacts"

log i "Using WORK_DIR: $WORK_DIR"
log i "Artifacts will be stored in: $component/artifacts"

for yml_file in $component/shared-libs.*.yml; do
    qt_version=$(basename "$yml_file" | sed -E 's/shared-libs\.([0-9]+\.[0-9]+)\.yml/\1/')
    log i "Processing $yml_file for Qt version $qt_version"

    build_dir="$WORK_DIR/shared-libs-$qt_version-build-dir"
    repo_dir="$WORK_DIR/shared-libs-$qt_version-repo"
    artifact_dir="$component/artifacts/qt-$qt_version/lib"

    mkdir -p "$artifact_dir"
    flatpak-builder --user --force-clean --install-deps-from=flathub --install-deps-from=flathub-beta --repo="$repo_dir" --state-dir="$WORK_DIR/.flatpak-builder" "$build_dir" "$yml_file"

    log i "Listing /lib folder:"
    ls -lah "$build_dir/files/lib" # DEBUG
    log i "Listing /usr/lib/plugins folder:"
    ls -lah "$build_dir/files/usr/lib/plugins" # DEBUG

    cp -rL "$build_dir/files/lib/"* "$artifact_dir"
    cp -rL "$build_dir/files/usr/lib/plugins" "$artifact_dir/"

    version="$version, $qt_version"
done

finalize