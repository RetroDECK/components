#!/bin/bash

export flycast_config="$XDG_CONFIG_HOME/flycast/emu.cfg"
export flycast_rd_config_dir=$rd_components/flycast/rd_config

_prepare_component::flycast() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Flycast"
      log i "----------------------"


    create_dir -d "$XDG_CONFIG_HOME/flycast/mappings"      
    create_dir -d "$XDG_DATA_HOME/flycast/"

    cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/flycast/"

    create_dir -d "$storage_path/Flycast/boxart"
    create_dir -d "$storage_path/Flycast/TextureDump"

    create_dir -d "$cheats_path/Flycast/cheats"

    create_dir -d "$saves_path/Flycast-SA/saves"
    create_dir -d "$saves_path/Flycast-SA/VMU"

    create_dir -d "$states_path/Flycast-SA/"

    create_dir -d "$texture_path/Flycast/Textures"


    sed -i "s|^Dreamcast.BiosPath = .*|Dreamcast.BiosPath = $bios_path|" $flycast_config

    sed -i "s|^Dreamcast.BoxartPath = .*|Dreamcast.BoxartPath = $storage_path/Flycast/boxart|" $flycast_config  
    sed -i "s|^Dreamcast.TextureDumpPath = .*|Dreamcast.TextureDumpPath = $storage_path/Flycast/TextureDump|" $flycast_config

    sed -i "s|^Dreamcast.CheatPath = .*|Dreamcast.CheatPath = $cheats_path/Flycast/cheats|" $flycast_config
    
    sed -i "s|^Dreamcast.ContentPath = .*|Dreamcast.ContentPath = $roms_path/dreamcast|" $flycast_config

    sed -i "s|^Dreamcast.SavePath = .*|Dreamcast.SavePath = $saves_path/Flycast-SA/saves|" $flycast_config
    sed -i "s|^Dreamcast.VMUPath = .*|Dreamcast.VMUPath = $saves_path/Flycast-SA/VMU|" $flycast_config

    sed -i "s|^Dreamcast.SavestatePath = .*|Dreamcast.SavestatePath = $states_path/Flycast-SA/|" $flycast_config

    sed -i "s|^Dreamcast.TexturePath = .*|Dreamcast.TexturePath = $texture_packs_path/Flycast/Textures|" $flycast_config

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Flycast"
      log i "----------------------"

    sed -i "s|^Dreamcast.BiosPath = .*|Dreamcast.BiosPath = $bios_path|" $flycast_config

    sed -i "s|^Dreamcast.BoxartPath = .*|Dreamcast.BoxartPath = $storage_path/Flycast/boxart|" $flycast_config  
    sed -i "s|^Dreamcast.TextureDumpPath = .*|Dreamcast.TextureDumpPath = $storage_path/Flycast/TextureDump|" $flycast_config

    sed -i "s|^Dreamcast.CheatPath = .*|Dreamcast.CheatPath = $cheats_path/Flycast/cheats|" $flycast_config
    
    sed -i "s|^Dreamcast.ContentPath = .*|Dreamcast.ContentPath = $roms_path/dreamcast|" $flycast_config

    sed -i "s|^Dreamcast.SavePath = .*|Dreamcast.SavePath = $saves_path/Flycast-SA/saves|" $flycast_config
    sed -i "s|^Dreamcast.VMUPath = .*|Dreamcast.VMUPath = $saves_path/Flycast-SA/VMU|" $flycast_config

    sed -i "s|^Dreamcast.SavestatePath = .*|Dreamcast.SavestatePath = $states_path/Flycast-SA/|" $flycast_config

    sed -i "s|^Dreamcast.TexturePath = .*|Dreamcast.TexturePath = $texture_packs_path/Flycast/Textures|" $flycast_config

    ;;

  esac

}

_post_update::flycast() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Flycast Setup"

    prepare_component "reset" "flycast"
  fi
}

_set_setting_value::flycast() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^s^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  fi
}

_get_setting_value::flycast() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"] }
       index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  fi
}