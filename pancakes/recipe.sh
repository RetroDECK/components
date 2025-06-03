#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/RetroDECK/Pancakes-bin/releases/latest/download/pancakes-Release-linux_x64.tar.gz"
rm -rf pancakes.tar.gz

# Move the files from publish folder to work directory
cp -rL "$component/artifacts/publish/"* "$component/artifacts/" || {
        echo "ERROR: Failed to copy files from publish/"
        exit 1
    }
rm -rf "$component/artifacts/publish"

finalize