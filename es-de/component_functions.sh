#!/bin/bash

es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"

start_esde(){
  log d "Starting ES-DE"
  /bin/bash /app/retrodeck/components/es-de/component_launcher.sh "$@"
}
