#!/bin/bash

es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"
es_systems="/app/retrodeck/components/es-de/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list
es_find_rules="/app/retrodeck/components/es-de/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules

start_esde(){
  log d "Starting ES-DE"
  /bin/bash /app/retrodeck/components/es-de/component_launcher.sh "$@"
}

_set_setting_value::es-de() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")

  sed -i 's^'"$name"'" value=".*"^'"$name"'" value="'"$value"'"^' "$file"
}

_get_setting_value::es-de() {
  local file="$1" name="$2"
  sed -n 's^.*name="'"$(sed_escape_pattern "$name")"'" value="\(.*\)".*^\1^p' "$file"
}
