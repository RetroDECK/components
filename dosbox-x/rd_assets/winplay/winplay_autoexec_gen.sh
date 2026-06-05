#!/bin/bash

# This script is used to generate autoexec sections for DosBox-X

if [ "$CALL_SOURCE" != "WINPLAY" ]; then
    log e "This script is not meant to be called directly. Please use winplay.sh to run this script."
    exit 1
fi

generate_autoexec_headers() {
# Mount the OS image as a hard disk (VHD) for installation
log d "Generating autoexec headers"
log d "Mounting \"$OS_IMAGE\" as OS image."
cat <<EOF >> "$dosbox_x_generated_conf"
IMGMOUNT C "$OS_IMAGE" -t hdd
EOF
    
# Mount any additional media (floppy, CD-ROM) if specified, and build up the MOUNT_MAP for later inclusion in the config
log d "Appending generated MOUNT_MAP for autoexec:"
log d "$MOUNT_MAP"
cat <<EOF >> "$dosbox_x_generated_conf"
${MOUNT_MAP}
EOF

}

generate_autoexec_install_os() {

generate_autoexec_headers

# Copy drivers from the CD to the Windows system directory to reduce prompts during installation.
cat <<EOF >> "$dosbox_x_generated_conf"
REM Copy as many files as possible from the CD to C:\WINDOWS\SYSTEM
IF NOT EXIST C:\WINDOWS\SYSTEM MD C:\WINDOWS\SYSTEM
REM Copy full $PRETTY_SYSTEM_NAME and DRIVERS directories (recursive copy where available)
IF EXIST D:\${SYSTEM} XCOPY D:\${SYSTEM} C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
IF EXIST D:\DRIVERS XCOPY D:\DRIVERS C:\WINDOWS\SYSTEM /E /Y >NUL 2>NUL
REM Also copy any root-level device files that might be directly requested
IF EXIST D:\*.VXD COPY /Y D:\*.VXD C:\WINDOWS\SYSTEM >NUL 2>NUL
IF EXIST D:\*.DRV COPY /Y D:\*.DRV C:\WINDOWS\SYSTEM >NUL 2>NUL
D:
SETUP.EXE /D /ID /IE /IF /IM /IS /NR /IW
GOTO END_INSTALL
:WINDOWS_FOUND
ECHO Windows installation detected, booting it
BOOT C:
:END_INSTALL
C:
RUNDLL32.EXE USER.EXE,ExitWindows
EOF

}

generate_autoexec_os_run() {
generate_autoexec_headers
cat <<EOF >> "$dosbox_x_generated_conf"
C:
CD WINDOWS
WIN
EOF 
}

generate_autoexec_game_install() {
    generate_autoexec_headers
}

generate_autoexec_game_run() {

generate_autoexec_headers

cat > "$dosbox_x_generated_conf" << EOF

IMGMOUNT D "$GAME_PATH" -t hdd

@ECHO OFF
CLS
COLOR 1F

REM -----------------------------------------------------------------
REM WINPLAY
REM -----------------------------------------------------------------

IF EXIST D:\\WINPLAY.CFG GOTO LOADCFG

SET TARGET=${GAME_NAME}.EXE
GOTO FIND_DEFAULT

:LOADCFG

FOR /F "tokens=1,* delims==" %%A IN (D:\WINPLAY.CFG) DO SET EXEC_PATH=%%B

IF EXIST "%EXEC_PATH%" (
    START /WAIT "" "%EXEC_PATH%"
    GOTO END
)

:FIND_DEFAULT

SET FOUND=

FOR /R D:\ %%F IN (%TARGET%) DO (
    SET FOUND=%%F
)

IF NOT "%FOUND%"=="" (
    START /WAIT "" "%FOUND%"
    GOTO END
)

:NOT_FOUND

CLS
COLOR 1F

ECHO.
ECHO ============================================================
ECHO                           WINPLAY
ECHO ============================================================
ECHO.
ECHO Could not determine which executable to launch.
ECHO.
ECHO WinPlay searched for:
ECHO.
ECHO     %TARGET%
ECHO.
ECHO To fix this, either:
ECHO.
ECHO  1. Rename the VHD file so that its name matches the EXE
ECHO.
ECHO     Example:
ECHO         OMF.VHD searches for OMF.EXE
ECHO.
ECHO  2. Create D:\WINPLAY.CFG containing:
ECHO.
ECHO     EXEC=D:\PATH\TO\GAME.EXE
ECHO.
ECHO Press any key to exit.
ECHO.
ECHO ============================================================

PAUSE >NUL
GOTO END

:END
RUNDLL32.EXE USER.EXE,ExitWindows
EOF
}

clear_autoexec(){

    log d "Clearing autoexec section of generated config file at \"$dosbox_x_generated_conf\""

    local conf_file="${1:-$dosbox_x_generated_conf}"

    # Clear the autoexec section of the generated config file
    sed -i '/^\[autoexec\]$/,$d' "$dosbox_x_generated_conf"

    # Replace it with the system defult one
    sed -n '/^\[autoexec\]$/,$p' "$dosbox_x_os_configs_dir/${SYSTEM}.conf" >> "$dosbox_x_generated_conf"
}