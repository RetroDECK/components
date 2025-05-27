#!/bin/bash

source "automation-tools/utils.sh"

grab generic "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/retrodeck.portmaster.zip"

finalize

# TODO: we need to adapt this to the new NEO format

#   - name: PortMaster
#     buildsystem: simple
#     build-commands:
#       - mkdir -p "${FLATPAK_DEST}/retrodeck/PortMaster/"
#       - install -Dm755 "PortMaster" "${FLATPAK_DEST}/bin/PortMaster"
#       - install -Dm755 "harbourmaster" "${FLATPAK_DEST}/bin/harbourmaster"
#       - cp PortMaster.zip "${FLATPAK_DEST}/retrodeck/PortMaster.zip"
#     sources:
#       - type: file
#         url: 
#         sha256: PORTMASTERLATESTSHA
#         dest-filename: PortMaster.zip
#       - type: script
#         commands:
#           - |
#             "/var/data/PortMaster/PortMaster.sh" "$@"
#         dest-filename: PortMaster
#       - type: script
#         commands:
#           - |
#             "/var/data/PortMaster/harbourmaster" "$@"
#         dest-filename: harbourmaster