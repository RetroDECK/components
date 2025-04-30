#!/bin/bash

source "automation-tools/utils.sh"

# curl -s "https://raw.githubusercontent.com/RetroDECK/components-template/refs/heads/main/automation_tools/install_dependencies.sh" | /bin/bash

# Loop through all recipe.sh files in the first-level subdirectories
for recipe in */recipe.sh; do
    bash "$recipe"
done

write_components_version