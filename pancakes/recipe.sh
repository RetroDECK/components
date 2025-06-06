#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "RetroDECK/Pancakes-bin"

# Move the files from publish folder to work directory
cp -rL "$component/artifacts/publish/"* "$component/artifacts/" || {
        echo "ERROR: Failed to copy files from publish/"
        exit 1
    }
rm -rf "$component/artifacts/publish"

# Add -rdfix to the first line of component_version
if [[ -f "$component/component_version" ]]; then
    sed -i '1s/$/-rdfix/' "$component/component_version"
fi

finalize