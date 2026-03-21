#!/bin/bash

export es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
export es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
export es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"
export es_systems="$rd_components/es-de/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list
export es_find_rules="$rd_components/es-de/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules
export splashscreen_dir="$rd_components/es-de/res/extra_splashes"                                   # The default location of extra splash screens
export current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
export default_splash_file="$rd_components/es-de/res/splash.svg"                               # The default RetroDECK splash screen

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

_prepare_component::es-de() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "--------------------------------"
      log i "Resetting ES-DE"
      log i "--------------------------------"

      rm -rf "$XDG_CONFIG_HOME/ES-DE"
      create_dir "$XDG_CONFIG_HOME/ES-DE/systems"
      cp -f "$component_config/es_import_rules.xml" "$XDG_CONFIG_HOME/ES-DE/systems/es_import_rules.xml"
      create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
      log d "Preparing es_settings.xml"
      cp -f "$component_config/es_settings.xml" "$es_de_config"
      set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es-de"
      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es-de"
      dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$rd_home_path/ES-DE/scripts" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$rd_home_path/ES-DE/screensavers" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
      dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
      log d "Generating roms system folders"
      start::es-de --create-system-dirs
    ;;

    postmove)
      log i "--------------------------------"
      log i "Post-moving ES-DE"
      log i "--------------------------------"

      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es-de"
      dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$rd_home_path/ES-DE/scripts" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$rd_home_path/ES-DE/screensavers" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
      dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
    ;;

    startup)
      log i "--------------------------------"
      log i "Starting ES-DE"
      log i "--------------------------------"
      local component_path="$(get_own_component_path)"

      splash_screen::es-de
  
      log i "Starting ES-DE"
      start::es-de "$@"
    ;;

    shutdown)
      log i "--------------------------------"
      log i "Shutting down ES-DE"
      log i "--------------------------------"

      log i "Quitting ES-DE"
      pkill -f "es-de"
    ;;

  esac
}

start::es-de(){
  log d "Starting ES-DE"

  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}

splash_screen::es-de() {
  # This function will replace the RetroDECK startup splash screen with a different image if the day and time match a listing in the JSON data.
  # USAGE: splash_screen

  current_day=$(date +"%m%d")  # Read the current date in a format that can be calculated in ranges
  current_time=$(date +"%H%M") # Read the current time in a format that can be calculated in ranges

  # Read the JSON file and extract splash screen data using jq
  splash_screen=$(jq -r --arg current_day "$current_day" --arg current_time "$current_time" \
    --slurpfile manifests "$component_manifest_cache_file" '
    $manifests[0][] | .manifest | select(has("es-de")) | .["es-de"].splash_screens |
    to_entries[] |
    select(
      ($current_day | tonumber) >= (.value.start_date | tonumber) and
      ($current_day | tonumber) <= (.value.end_date | tonumber) and
      ($current_time | tonumber) >= (.value.start_time | tonumber) and
      ($current_time | tonumber) <= (.value.end_time | tonumber)
    ) | .value.filename
  ' <<< 'null')

  # Determine the splash file to use
  if [[ -n "$splash_screen" ]]; then
    new_splash_file="$splashscreen_dir/$splash_screen"
  else
    new_splash_file="$default_splash_file"
  fi

  mkdir -p "$XDG_CONFIG_HOME/ES-DE/resources/graphics"
  cp -f "$new_splash_file" "$current_splash_file"
}

configurator_rebuild_esde_systems::es-de() {
  start::es-de --create-system-dirs
  local current_iconset=$(get_setting_value "$rd_conf" "iconset" "retrodeck" "options")
  if [[ ! "$current_iconset" == "false" ]]; then
    (
    handle_folder_iconsets "$current_iconset"
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Rebuilding Folder Iconsets In Progress"
  fi
  configurator_generic_dialog "RetroDECK Configurator - Rebuild System Folders" "<span foreground='$purple'><b>The rebuilding process is complete.</b></span>\n\nAll missing default system folders will now exist in <span foreground='$purple'><b>$roms_path</b></span>."
}

generate_es_find_rules_xml() {
  # Generate es_find_rules.xml from component manifest cache data.
  # Reads all es_de_config.es_find_rules entries, resolves bash variables in
  # entry paths, validates uniqueness of emulator and core names, and writes
  # the XML file. Duplicate names within a block type are logged as errors
  # and the duplicate entry is skipped. Blocks with entries referencing unset
  # or empty variables are skipped entirely.
  # An emulator and a core may share the same name.
  # USAGE: generate_es_find_rules_xml
 
  local output_file="$es_find_rules"
  local tmp_file="${output_file}.tmp"
 
  if [[ -f "$es_find_rules" ]]; then
    cp "$es_find_rules" "${es_find_rules}.bak"
    log i "Backed up existing file: ${es_find_rules}.bak"
  fi
 
  # Extract all emulator and core entries as a flat JSON array, preserving manifest order.
  # Each element: {block_type, name, description, rules[], component_key}
  local all_entries
  all_entries=$(jq -c '
    [.[] | .manifest | to_entries[] |
      .key as $component_key |
      (.value.es_de_config.es_find_rules // {}) |
      (
        (.emulators // [] | .[] | {block_type: "emulator", name: .name, description: (.description // ""), rules: .rules, component_key: $component_key}),
        (.cores // [] | .[] | {block_type: "core", name: .name, description: (.description // ""), rules: .rules, component_key: $component_key})
      )
    ]
  ' "$component_manifest_cache_file")

  # Resolve bash variables in entry paths (e.g. $rd_components).
  # First validate that all referenced variables are set, then resolve.
  # Blocks referencing unset or empty variables are filtered out before resolution.
  local -a bad_vars=()
  local all_var_refs
  all_var_refs=$(printf '%s' "$all_entries" | grep -oE '\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?' | sed 's/[${}]//g' | sort -u)
 
  local var_name
  for var_name in $all_var_refs; do
    if [[ -z "${!var_name:-}" ]]; then
      log e "Unset or empty variable referenced in es_find_rules entries: \$$var_name"
      bad_vars+=("\$${var_name}" "\${${var_name}}")
    fi
  done
 
  if [[ ${#bad_vars[@]} -gt 0 ]]; then
    local bad_json
    bad_json=$(printf '%s\n' "${bad_vars[@]}" | jq -Rsc 'split("\n") | map(select(. != ""))')
    local skipped_blocks
    skipped_blocks=$(printf '%s' "$all_entries" | jq -r --argjson bad "$bad_json" '
      [.[] | select([.rules[].entries[]] | any(. as $entries | $bad | any(. as $bad_entries | $entries | contains($bad_entries))))] |
      .[] | "\(.block_type) \(.name) (component: \(.component_key))"
    ')
    if [[ -n "$skipped_blocks" ]]; then
      while IFS= read -r skipped_line; do
        log e "Skipping $skipped_line due to unresolvable variable"
      done <<< "$skipped_blocks"
    fi
    all_entries=$(printf '%s' "$all_entries" | jq -c --argjson bad "$bad_json" '
      [.[] | select([.rules[].entries[]] | any(. as $entries | $bad | any(. as $bad_entries | $entries | contains($bad_entries))) | not)]
    ')
  fi
 
  all_entries=$(printf '%s' "$all_entries" | envsubst)
 
  # Detect and report duplicates (same block_type + name appearing more than once)
  local duplicate_report
  duplicate_report=$(printf '%s' "$all_entries" | jq -r '
    group_by(.block_type + ":" + .name) | .[] | select(length > 1) |
    "Duplicate \(.[0].block_type) name: \(.[0].name) (defined by: \([.[].component_key] | join(", ")))"
  ')
 
  local errors=0
  if [[ -n "$duplicate_report" ]]; then
    while IFS= read -r dup_line; do
      log e "$dup_line"
      errors=$((errors + 1))
    done <<< "$duplicate_report"
  fi
 
  # Generate XML, keeping only the first occurrence of each block_type+name pair.
  # jq handles XML escaping via custom defs and outputs the complete document line by line.
  printf '%s' "$all_entries" | jq -r '
 
    # XML escaping functions
    def xml_attr: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;") | gsub("\"";"&quot;");
    def xml_text: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
 
    # Deduplicate: group by block_type+name, keep first occurrence only
    group_by(.block_type + ":" + .name) | map(.[0]) |
 
    # Sort: emulators first, then cores, alphabetical within each group
    sort_by([(.block_type | if . == "emulator" then "0" else "1" end), .name]) |
 
    # Output XML
    "<?xml version=\"1.0\"?>",
    "<ruleList>",
    (.[] |
      "    <\(.block_type) name=\"\(.name | xml_attr)\">",
      (if .description != "" then
        "        <!-- \(.description | xml_text) -->"
      else empty end),
      (.rules[] |
        "        <rule type=\"\(.type | xml_attr)\">",
        (.entries[] | "            <entry>\(. | xml_text)</entry>"),
        "        </rule>"
      ),
      "    </\(.block_type)>"
    ),
    "</ruleList>"
 
  ' > "$tmp_file"
 
  if [[ $? -ne 0 ]]; then
    log e "Failed to generate es_find_rules.xml content"
    rm -f "$tmp_file"
    return 1
  fi
 
  # Format with xmlstarlet for consistent indentation
  if xmlstarlet fo "$tmp_file" > "${tmp_file}.fmt" 2>/dev/null; then
    mv "${tmp_file}.fmt" "$output_file"
  else
    log w "xmlstarlet formatting failed, using raw output"
    mv "$tmp_file" "$output_file"
  fi
  rm -f "$tmp_file" "${tmp_file}.fmt"
 
  if [[ $errors -gt 0 ]]; then
    log w "es_find_rules.xml generated with $errors duplicate entries skipped"
  else
    log i "es_find_rules.xml generated successfully"
  fi
 
  return 0
}

generate_es_systems_xml() {
  # Generate es_systems.xml from component manifest cache data.
  # Reads all es_de_config.es_systems entries in all manifests and writes the XML file.
  # When multiple components define the same system name:
  #   - Metadata (fullname, path, extension, platform, theme) uses the first contributor
  #   - Commands are merged from all contributors with labels annotated as "Label (ComponentName)"
  # Systems contributed by a single component retain their original labels unmodified.
  # USAGE: generate_es_systems_xml
 
  local output_file="$es_systems"
  local tmp_file="${output_file}.tmp"

  if [[ -f "$es_systems" ]]; then
    cp "$es_systems" "${es_systems}.bak"
    log i "Backed up existing file: ${es_systems}.bak"
  fi
 
  # Extract all system entries as a flat JSON array, carrying the component's human-friendly name.
  # Each element: {name, fullname, path, extension, commands[], platform, theme, component_name, component_key}
  local all_systems
  all_systems=$(jq -c '
    [.[] | .manifest | to_entries[] |
      .key as $component_key | .value.name as $component_name |
      (.value.es_de_config.es_systems // [])[] |
      . + {component_name: $component_name, component_key: $component_key}
    ]
  ' "$component_manifest_cache_file")
 
  # Merge systems: group by name, merge commands, annotate labels for multi-contributor systems.
  # The jq filter handles the entire merge logic and outputs the final merged array.
  local merged_systems
  merged_systems=$(printf '%s' "$all_systems" | jq -c '
    # Generate both lowercase and uppercase for each extension, then deduplicate
    def expand_extensions: split(" ") | map(., ascii_downcase, ascii_upcase) | unique | join(" ");
 
    group_by(.name) | map(
      if length == 1 then
        # Single contributor: use as-is, no label modification
        .[0] | del(.component_name, .component_key) |
        .extension |= expand_extensions
      else
        # Multiple contributors: first wins for metadata, merge all commands,
        # merge extension lists across contributors then expand cases,
        # and annotate only labels that conflict (same label from different contributors)
        .[0] as $first |
        [.[] | .component_name as $component_name | .commands[] | {label, command, component_name: $component_name}] as $all_cmds |
        # Find labels that appear more than once
        [$all_cmds | group_by(.label) | .[] | select(length > 1) | .[0].label] as $dup_labels |
        {
          name: $first.name,
          fullname: $first.fullname,
          path: $first.path,
          extension: ([.[].extension | split(" ")[]] | unique | join(" ") | expand_extensions),
          commands: [$all_cmds[] | {
            label: (if (.label | IN($dup_labels[])) then "\(.label) (\(.component_name))" else .label end),
            command
          }],
          platform: $first.platform,
          theme: $first.theme
        }
      end
    ) | sort_by(.name)
  ')
 
  # Generate XML from the merged systems data
  printf '%s' "$merged_systems" | jq -r '
 
    # XML escaping functions
    def xml_attr: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;") | gsub("\"";"&quot;");
    def xml_text: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
 
    "<?xml version=\"1.0\"?>",
    "<systemList>",
    (.[] |
      "    <system>",
      "        <name>\(.name | xml_text)</name>",
      "        <fullname>\(.fullname | xml_text)</fullname>",
      "        <path>\(.path | xml_text)</path>",
      "        <extension>\(.extension | xml_text)</extension>",
      (.commands[] |
        "        <command label=\"\(.label | xml_attr)\">\(.command | xml_text)</command>"
      ),
      "        <platform>\(.platform | xml_text)</platform>",
      "        <theme>\(.theme | xml_text)</theme>",
      "    </system>"
    ),
    "</systemList>"
 
  ' > "$tmp_file"
 
  if [[ $? -ne 0 ]]; then
    log e "Failed to generate es_systems.xml content"
    rm -f "$tmp_file"
    return 1
  fi
 
  # Format with xmlstarlet for consistent indentation
  if xmlstarlet fo "$tmp_file" > "${tmp_file}.fmt" 2>/dev/null; then
    mv "${tmp_file}.fmt" "$output_file"
  else
    log w "xmlstarlet formatting failed, using raw output"
    mv "$tmp_file" "$output_file"
  fi
  rm -f "$tmp_file" "${tmp_file}.fmt"
 
  log i "es_systems.xml generated successfully"
  return 0
}

_post_update::es-de() {
  local previous_version="$1"

}

_post_update_legacy::es-de() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Expose ES-DE gamelists folder to user at ~/retrodeck/gamelists
    # - Disable ESDE update checks for existing installs
    # - Set ESDE user themes folder directly

    dir_prep "$rdhome/gamelists" "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists"

    set_setting_value "$es_settings" "ApplicationUpdaterFrequency" "never" "es-de"

    rm -rf "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists/tools/"

    set_setting_value "$es_settings" "ROMDirectory" "$roms_path" "es-de"
    set_setting_value "$es_settings" "MediaDirectory" "$media_path" "es-de"
    sed -i '$ a <string name="UserThemeDirectory" value="" />' "$es_settings" # Add new default line to existing file
    set_setting_value "$es_settings" "UserThemeDirectory" "$themes_path" "es-de"
    unlink "$XDG_CONFIG_HOME/emulationstation/ROMs"
    unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/downloaded_media"
    unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/themes"
  fi

  if check_version_is_older_than "$previous_version" "0.7.3b"; then
    # In version 0.7.3b, there was a bug that prevented the correct creations of the roms/system folders, so we force recreate them.
    start::es-de --home "$XDG_CONFIG_HOME/emulationstation" --create-system-dirs
  fi

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

    # in 3.0 .emulationstation was moved into ES-DE
    log i "Renaming old \"$XDG_CONFIG_HOME/emulationstation\" folder as \"$XDG_CONFIG_HOME/ES-DE\""
    mv -f "$XDG_CONFIG_HOME/emulationstation" "$XDG_CONFIG_HOME/ES-DE"

    prepare_component "reset" "es-de"

    log i "New systems were added in this version, regenerating system folders."
    #es-de --home "$XDG_CONFIG_HOME/" --create-system-dirs
    start::es-de --create-system-dirs
  fi

  if check_version_is_older_than "$previous_version" "0.8.1b"; then
    log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- ES-DE files were moved inside the retrodeck folder, migrating to the new structure"

    log d "ES-DE files were moved inside the retrodeck folder, migrating to the new structure"
    dir_prep "$rdhome/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
    log i "Moving ES-DE collections, downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\""
    set_setting_value "$es_settings" "MediaDirectory" "$rdhome/ES-DE/downloaded_media" "es-de"
    set_setting_value "$es_settings" "UserThemeDirectory" "$rdhome/ES-DE/themes" "es-de"
    mv -f "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" in \"$rdhome/ES-DE\" folder completed"
    mv -f "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" in \"$rdhome/ES-DE\" folder completed"
    mv -f "$rdhome/gamelists/"* "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" in \"$rdhome/ES-DE\" folder completed" && rm -rf "$rdhome/gamelists"
  fi

  if check_version_is_older_than "$previous_version" "0.9.4b"; then
    # Between updates of ES-DE to 3.2, it looks like some required graphics files may not be created on an existing install
    # We will use rsync to ensure that the shipped graphics and the location ES-DE is looking in are correct
    rsync -rlD --mkpath "/app/retrodeck/graphics/" "/var/config/ES-DE/resources/graphics/"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists" # Fix broken symlink in case user had moved an ES-DE folder after they were consolidated into ~/retrodeck/ES-DE
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # With the RetroDECK Neo the theme folder is changed, so if the user set the RetroDECK Theme we need to fix the name in the config

    if [[ $(get_setting_value "$es_de_config" "Theme" "es-de") == "retrodeck" ]]; then
      log i "0.10.0b Upgrade - Postmove: ES-DE - Default RetroDECK theme is set, fixing theme name in ES-DE config"
      set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es-de"

      prepare_component "postmove" "es-de"
    fi
  fi
}
