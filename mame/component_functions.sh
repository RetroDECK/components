#!/bin/bash

mame_config="$XDG_CONFIG_HOME/mame/ini/mame.ini"
mame_config_ui="$XDG_CONFIG_HOME/mame/ini/ui.ini"
mame_config_default="$XDG_CONFIG_HOME/mame/cfg/default.cfg"

compress_chd() {
  case "$1" in # Check platform-specific compression options
    "psp" )
      log d "Compressing PSP game $2 into $3"
      /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createdvd --hunksize 2048 -i "$2" -o "$3".chd -c zstd
    ;;
    "ps2" )
      if [[ "$filename_extension" == "cue" ]]; then
        /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createcd -i "$2" -o "$3".chd
      else
        /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createdvd -i "$2" -o "$3".chd -c zstd
      fi
    ;;
    * )
      /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createcd -i "$2" -o "$3".chd
    ;;
  esac
}
