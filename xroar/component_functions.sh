#!/bin/bash

export xroar_config="$XDG_CONFIG_HOME/xroar/xroar.conf"

_set_setting_value::xroar() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    local esc_section=$(sed_escape_pattern "$section")
    local sed_cmd
    sed_cmd='s^\(  '"$name"' \)".*"^\1"'"$value"'"^; t end;'
    sed_cmd+='s^\(  '"$name"' \).*^\1'"$value"'^; :end'
    sed -i '\^'"$esc_section"'$^,\^  '"$name"' ^{'"$sed_cmd"'}' "$file"
  else
    local sed_cmd
    sed_cmd='s^\(^'"$name"' \)".*"^\1"'"$value"'"^; t end;'
    sed_cmd+='s^\(^'"$name"' \).*^\1'"$value"'^; :end'
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::xroar() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^[^ ]/ { in_section=0 }
       in_section && index($0, "  " key " ") == 1 {
         val = substr($0, length("  " key " ") + 1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"] }
       index($0, key " ") == 1 {
         val = substr($0, length(key " ") + 1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  fi
}

_prepare_component::xroar() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting XROAR"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/xroar"
      cp -f "$component_config/xroar.conf" "$xroar_config" && log i "Copied default xroar.conf to $xroar_config"
      sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$xroar_config" && log i "Set ROMs directory in xroar.conf"
      sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$xroar_config" && log i "Set BIOS directory in xroar.conf"

      # XRoar does not provide a default directory for state files in the config, so you must choose a folder each time you save or load.

      create_dir "$states_path/xroar/coco/"
      create_dir "$states_path/xroar/dragon32/"
      create_dir "$states_path/xroar/tanodragon/"
    ;;

  esac
}

_post_update::xroar() {
  local previous_version="$1"

}

_post_update_legacy::xroar() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Init Xroar as it is a new emulator
    log i "0.10.0b Upgrade - Reset: XRoar"

    prepare_component "reset" "xroar"
  fi
}
