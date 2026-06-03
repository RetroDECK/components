#!/bin/bash

# This script is used to generate autoexec sections for DosBox-X

if [ "$CALL_SOURCE" != "WINPLAY" ]; then
    log e "This script is not meant to be called directly. Please use winplay.sh to run this script."
    exit 1
fi

generate_autoexec_install_os() {

local conf_file="${1:-$dosbox_x_generated_conf}"

# Mount the OS image as a hard disk (VHD) for installation
cat <<EOF >> "$conf_file"
IMGMOUNT C "$OS_IMAGE" -t hdd
EOF
    
# Mount any additional media (floppy, CD-ROM) if specified, and build up the MOUNT_MAP for later inclusion in the config
log d "Appending generated MOUNT_MAP for autoexec:\n$MOUNT_MAP"
cat <<EOF >> "$conf_file"
${MOUNT_MAP}
EOF

# Copy drivers from the CD to the Windows system directory to reduce prompts during installation.
cat <<'EOF' >> "$conf_file"
REM Copy as many files as possible from the CD to C:\WINDOWS\SYSTEM
IF NOT EXIST C:\WINDOWS\SYSTEM MD C:\WINDOWS\SYSTEM
REM Copy full WIN98 and DRIVERS directories (recursive copy where available)
IF EXIST D:\WIN98 XCOPY D:\WIN98 C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
IF EXIST D:\DRIVERS XCOPY D:\DRIVERS C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
REM Also copy any root-level device files that might be directly requested
IF EXIST D:\*.VXD COPY /Y D:\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\*.DRV COPY /Y D:\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
EOF

# Add autoexec commands to run the Windows setup from the mounted CD-ROM
# In this phase we make sure that there is no run_game.bat in the startup folders
cat <<EOF >> "$conf_file"
DIR "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
DIR "C:\\WINDOWS\\Start Menu\\Programs\\Startup\\run_game.bat"
DEL /F /Q "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat" 2>NUL
DEL /F /Q "C:\\WINDOWS\\Start Menu\\Programs\\Startup\\run_game.bat" 2>NUL
DIR "C:\\WINDOWS\\STARTM~1\\PROGRAMS\\STARTUP\\run_game.bat"
DIR "C:\\WINDOWS\\Start Menu\\Programs\\Startup\\run_game.bat"
D:
SETUP.EXE
GOTO END_INSTALL
:WINDOWS_FOUND
ECHO Windows installation detected, booting it
BOOT C:
:END_INSTALL
C:
RUNDLL32.EXE USER.EXE,ExitWindows
EOF

log i "Setup: VHD mounted, ready for installation"

}