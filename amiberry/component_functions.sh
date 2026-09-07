#!/bin/bash

export amiberry_config="$XDG_CONFIG_HOME/amiberry/amiberry.conf"
export amiberry_shaders_path="/app/retrodeck/components/amiberry/shaders"
export amiberry_ini="$XDG_CONFIG_HOME/amiberry/amiberry.ini"

_prepare_component::amiberry() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Amiberry"
      log i "----------------------"

        create_dir "$XDG_CONFIG_HOME/amiberry/"
        create_dir "$XDG_DATA_HOME/amiberry/"
        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/amiberry/"

        # Storage

        create_dir "$storage_path/Amiberry/CD-ROMs" 
        create_dir "$storage_path/Amiberry/Configurations" 
        create_dir "$storage_path/Amiberry/WHDBoot" 
        create_dir "$storage_path/Amiberry/LHA" 
        create_dir "$storage_path/Amiberry/Floppies" 
        create_dir "$storage_path/Amiberry/HardDrives" 
        create_dir "$storage_path/Amiberry/RP9" 
        create_dir "$storage_path/Amiberry/SaveImages" 
        create_dir "$storage_path/Amiberry/Ripper" 
        create_dir "$storage_path/Amiberry/NVRAM" 
        create_dir "$storage_path/Amiberry/Visuals/Themes" 
        create_dir "$storage_path/Amiberry/Controllers" 
        create_dir "$storage_path/Amiberry/InputRecordings" 

        # Core directories

        create_dir "$states_path/amiga/Amiberry"
        create_dir "$screenshots_path/Amiberry"
        create_dir "$videos_path/Amiberry"
        create_dir "$shaders_path/Amiberry/Shaders"
        create_dir "$borders_path/Amiberry/Bezels"
        create_dir "$logs_path/Amiberry"

        cp -fvr "$amiberry_shaders_path/"* "$shaders_path/Amiberry/Shaders"

        # Core Paths

        sed -i "s|^savestate_dir=.*|savestate_dir=$states_path/amiga/Amiberry|" $amiberry_config
        sed -i "s|^screenshot_dir=.*|screenshot_dir=$screenshots_path/Amiberry|" $amiberry_config
        sed -i "s|^video_dir=.*|video_dir=$videos_path/Amiberry|" $amiberry_config
        sed -i "s|^shaders_path=.*|shaders_path=$shaders_path/Amiberry/Shaders|" $amiberry_config
        sed -i "s|^bezels_path=.*|bezels_path=$borders_path/Amiberry/Bezels|" $amiberry_config
        sed -i "s|^logfile_path=.*|logfile_path=$logs_path/Amiberry/Amiberry.log|" $amiberry_config
        sed -i "s|^rom_path=.*|rom_path=$bios_path|" $amiberry_config

        # Storage

        sed -i "s|^cdrom_path=.*|cdrom_path=$storage_path/Amiberry/CD-ROMs|" $amiberry_config
        sed -i "s|^config_path=.*|cdrom_path=$storage_path/Amiberry/Configurations|" $amiberry_config
        sed -i "s|^whdboot_path=.*|whdboot_path=$storage_path/Amiberry/WHDBoot|" $amiberry_config
        sed -i "s|^whdload_arch_path=.*|whdload_arch_path=$storage_path/Amiberry/LHA|" $amiberry_config
        sed -i "s|^floppy_path=.*|floppy_path=$storage_path/Amiberry/Floppies|" $amiberry_config
        sed -i "s|^harddrive_path=.*|harddrive_path=$storage_path/Amiberry/HardDrives|" $amiberry_config
        sed -i "s|^rp9_path=.*|rp9_path=$storage_path/Amiberry/RP9|" $amiberry_config
        sed -i "s|^saveimage_dir=.*|saveimage_dir=$storage_path/Amiberry/SaveImages|" $amiberry_config
        sed -i "s|^nvram_dir=.*|nvram_dir=$storage_path/Amiberry/NVRAM|" $amiberry_config
        sed -i "s|^themes_path=.*|themes_path=$storage_path/Amiberry/Visuals/Themes|" $amiberry_config
        sed -i "s|^controllers_path=.*|controllers_path=$storage_path/Amiberry/Controllers|" $amiberry_config
        sed -i "s|^inputrecordings_dir=.*|inputrecordings_dir=$storage_path/Amiberry/InputRecordings|" $amiberry_config
        sed -i "s|^ripper_path=.*|ripper_path=$storage_path/Amiberry/Ripper|" $amiberry_config

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Amiberry"
      log i "----------------------"

        # Core Paths

        sed -i "s|^savestate_dir=.*|savestate_dir=$states_path/amiga/Amiberry|" $amiberry_config
        sed -i "s|^screenshot_dir=.*|screenshot_dir=$screenshots_path/Amiberry|" $amiberry_config
        sed -i "s|^video_dir=.*|video_dir=$videos_path/Amiberry|" $amiberry_config
        sed -i "s|^shaders_path=.*|shaders_path=$shaders_path/Amiberry/Shaders|" $amiberry_config
        sed -i "s|^bezels_path=.*|bezels_path=$borders_path/Amiberry/Bezels|" $amiberry_config
        sed -i "s|^logfile_path=.*|logfile_path=$logs_path/Amiberry/Amiberry.log|" $amiberry_config
        sed -i "s|^rom_path=.*|rom_path=$bios_path|" $amiberry_config

        # Storage


        sed -i "s|^cdrom_path=.*|cdrom_path=$storage_path/Amiberry/CD-ROMs|" $amiberry_config
        sed -i "s|^config_path=.*|cdrom_path=$storage_path/Amiberry/Configurations|" $amiberry_config
        sed -i "s|^whdboot_path=.*|whdboot_path=$storage_path/Amiberry/WHDBoot|" $amiberry_config
        sed -i "s|^whdload_arch_path=.*|whdload_arch_path=$storage_path/Amiberry/LHA|" $amiberry_config
        sed -i "s|^floppy_path=.*|floppy_path=$storage_path/Amiberry/Floppies|" $amiberry_config
        sed -i "s|^harddrive_path=.*|harddrive_path=$storage_path/Amiberry/HardDrives|" $amiberry_config
        sed -i "s|^rp9_path=.*|rp9_path=$storage_path/Amiberry/RP9|" $amiberry_config
        sed -i "s|^saveimage_dir=.*|saveimage_dir=$storage_path/Amiberry/SaveImages|" $amiberry_config
        sed -i "s|^nvram_dir=.*|nvram_dir=$storage_path/Amiberry/NVRAM|" $amiberry_config
        sed -i "s|^themes_path=.*|themes_path=$storage_path/Amiberry/Visuals/Themes|" $amiberry_config
        sed -i "s|^controllers_path=.*|controllers_path=$storage_path/Amiberry/Controllers|" $amiberry_config
        sed -i "s|^inputrecordings_dir=.*|inputrecordings_dir=$storage_path/Amiberry/InputRecordings|" $amiberry_config
        sed -i "s|^ripper_path=.*|ripper_path=$storage_path/Amiberry/Ripper|" $amiberry_config


    ;;
    
  esac
}

_set_setting_value::amiberry() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local sed_cmd
  sed_cmd="s^\^${name} = '.*'^${name} = '${value}'^; t end;"
  sed_cmd+="s^\^${name} =.*^${name} = ${value}^; :end"
  sed -i "$sed_cmd" "$file"
}

_get_setting_value::amiberry() {
  local file="$1" name="$2"

  KEY="$name" awk -F'=' \
    'BEGIN { key=ENVIRON["KEY"] }
      index($0, key " =") == 1 {
        val = substr($0, index($0,"=")+2)
        gsub(/^'"'"'|'"'"'$/, "", val)
        print val; exit
      }' "$file"
}

amiberry_amigavision_toggle() {
  local file="$roms_path/amiga/AmigaVision.fdi"

  local response
  response=$(rd_zenity --question --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="AmigaVision" \
    --ok-label="Enable" \
    --cancel-label="Cancel" \
    --extra-button="Disable" \
    --text="<big><b>AmigaVision in ES-DE under the Commodore Amiga menu.</b></big>\n\nEnable or disable AmigaVision?")

  local rc=$?

  if [ $rc -eq 0 ]; then 
    touch "$file"
    rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title="Success" \
      --text="AmigaVision has been enabled.\n\nA restart of RetroDECK is required for the entry to appear." \
      --width=400
  elif [ "$response" = "Disable" ]; then
    [[ -f "$file" ]] && rm "$file"
    rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title="Success" \
      --text="AmigaVision has been disabled." \
      --width=400
  fi  # 
}
