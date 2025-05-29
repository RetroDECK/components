#!/bin/bash

# This recipe differs fomr the standard as PortMaster needs a special setup

source "automation-tools/assembler.sh"

component="portmaster"
version="stable"

wget -qc "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/retrodeck.portmaster.zip" -O "$component/artifacts/PortMaster.zip"

# Adding an additional launcher for harbourmaster
echo '#!/bin/bash' > "$component/artifacts/harbourmaster"
echo "\"/var/data/PortMaster/harbourmaster\" \"$@\"" >> "$component/artifacts/harbourmaster"
chmod +x "$component/artifacts/harbourmaster"

log d "Listing WORK_DIR ($component/artifacts)"
ls -lah "$component/artifacts"

finalize