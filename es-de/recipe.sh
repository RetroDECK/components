#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_artifacts "https://github.com/RetroDECK/ES-DE/releases/latest/download/RetroDECK-ES-DE-Artifact.tar.gz"

# Custom Commands

# Because of the NEO Pathing structure we need to move the files around a bit
# ES-DE got some harcoded paths, in fact in our case it would search the files in:
# - ~/ES-DE/resources/
# - /app/share/es-de/resources/
# - /app/retrodeck/components/es-de/bin/resources/
# So the only acceptable path would be the last one without the /bin/ subfolder
# So we had to move the es-de out of bin folder and consequently even all the resources folders as done below
# If some pathing breaks in the future might be because of this

cp -vrf "$component/artifacts/bin/"* "$component/artifacts"
rm -vrf "$component/artifacts/bin"
cp -vrf "$component/artifacts/share/es-de"/* "$component/artifacts"
rm -vrf "$component/artifacts/share/es-de"
cp -vrf "$component/artifacts/share/"* "$component/artifacts"
rm -vrf "$component/artifacts/share"
rm -vrf "$component/artifacts/applications"

# RetroDECK Theme
log i "Downloading RetroDECK theme..." "$logfile"
git clone --depth 1 "https://github.com/RetroDECK/RetroDECK-theme" "$component/artifacts/themes/RetroDECK"

finalize
