#!/bin/bash

echo "This cleans all the artifacts and component_version files, do you want to continue? (y/N): "
read -r continue

if [[ -z "$continue" || "$continue" =~ ^[Yy]$ ]]; then
    rm -rf */artifacts
    rm -f */component_version
else
    echo "Aborting cleanup."
    exit 1
fi
