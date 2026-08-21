#!/bin/bash

scummvm_config="$XDG_CONFIG_HOME/scummvm/scummvm.ini"

_prepare_component::scummvm() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting ScummVM"
      log i "----------------------"

        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/scummvm/"

        create_dir -d "$screenshots_path/scummvm"
        
        create_dir -d "$saves_path/scummvm/scummvm-sa"

        create_dir -d "$storage_path/scummvm/extra"
        create_dir -d "$storage_path/scummvm/themes"
        create_dir -d "$storage_path/scummvm/icons"
        create_dir -d "$storage_path/scummvm/cloud_root"

        dir_prep "$logs_path/scummvm" "$XDG_CACHE_HOME/scummvm/logs"

        sed -i "s|^screenshotpath=.*|screenshotpath=$screenshots_path/scummvm|" $scummvm_config
        sed -i "s|^savepath=.*|savepath=$saves_path/scummvm/scummvm-sa|" $scummvm_config

        sed -i "s|^extrapath=.*|extrapath=$storage_path/scummvm/extra|" $scummvm_config
        sed -i "s|^themepath=.*|themepath=$storage_path/scummvm/themes|" $scummvm_config
        sed -i "s|^iconspath=.*|iconspath=$storage_path/scummvm/icons|" $scummvm_config
        sed -i "s|^rootpath=.*|rootpath=$storage_path/scummvm/cloud_root|" $scummvm_config
      
        sed -i "s|^browser_lastpath=.*|browser_lastpath=$roms_path/scummvm|" $scummvm_config

      
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving ScummVM"
      log i "----------------------"

        dir_prep "$logs_path/scummvm" "$XDG_CACHE_HOME/scummvm/logs"
        
        sed -i "s|^screenshotpath=.*|screenshotpath=$screenshots_path/scummvm|" $scummvm_config
        sed -i "s|^savepath=.*|savepath=$saves_path/scummvm/scummvm-sa|" $scummvm_config

        sed -i "s|^extrapath=.*|extrapath=$storage_path/scummvm/extra|" $scummvm_config
        sed -i "s|^themepath=.*|themepath=$storage_path/scummvm/themes|" $scummvm_config
        sed -i "s|^iconspath=.*|iconspath=$storage_path/scummvm/icons|" $scummvm_config
        sed -i "s|^rootpath=.*|rootpath=$storage_path/scummvm/cloud_root|" $scummvm_config
      
        sed -i "s|^browser_lastpath=.*|browser_lastpath=$roms_path/scummvm|" $scummvm_config
    ;;
    
  esac
}

_set_setting_value::scummvm() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"'=^s^\^'"$name"'=.*^'"$name"'='"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"'=.*^'"$name"'='"$value"'^' "$file"
  fi
}

_get_setting_value::scummvm() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key "=") == 1 {
         print substr($0, index($0,"=")+1); exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"] }
       index($0, key "=") == 1 {
         print substr($0, index($0,"=")+1); exit
       }' "$file"
  fi
}
