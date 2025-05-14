#!/bin/bash

# This script will take a "to_dedupe" directory and a "reference" directory and remove any files (determined by name) that exist in both locations from the "to_dedupe" directory.
# The intention of this tool is to remove any libraries that may be packaged with an AppImage that already exist in the RetroDECK core runtime, so save on space.
# This approach does not validate files based on file hashes so making sure the component still runs after having duplicate libraries removed should always be validated manually!

to_dedupe="$1"
reference="$2"

declare -A reference_names
while IFS= read -r -d '' file; do
  name=$(basename "$file")
  reference_names["$name"]=1
done < <(find "$reference" \( -type f -o -type l \) -print0)

while IFS= read -r -d '' file; do
  name=$(basename "$file")
  if [[ ${reference_names["$name"]+_} ]]; then
    echo "Removing duplicate: $file"
    rm "$file"
  fi
done < <(find "$to_dedupe" \( -type f -o -type l \) -print0)
