#!/bin/bash

export es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
export es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
export es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"
export es_scripts_dir="$XDG_CONFIG_HOME/ES-DE/scripts"
export es_gamelists_dir="$XDG_CONFIG_HOME/ES-DE/gamelists"
export es_systems="$rd_components/es-de/share/es-de/resources/systems/linux/es_systems.xml"         # RetroDECK-generated ES-DE supported system list
export es_find_rules="$rd_components/es-de/share/es-de/resources/systems/linux/es_find_rules.xml"   # RetroDECK-generated ES-DE emulator find rules
export es_find_rules_official="$rd_components/es-de/rd_config/es_find_rules_official.xml"           # Official es_find_rules file from upstream ES-DE
export es_systems_official="$rd_components/es-de/rd_config/es_systems_official.xml"                 # Official es_systems file from upstream ES-DE
export splashscreen_dir="$rd_components/es-de/res/extra_splashes"                                   # The default location of extra splash screens
export current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                   # The active splash file that will be shown on boot
export default_splash_file="$rd_components/es-de/res/splash.svg"                                    # The default RetroDECK splash screen

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
      generate_es_find_rules_xml
      generate_es_systems_xml
      generate_es_de_diff_report > "$logs_path/es_de_gen_report.txt"

      create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
      log d "Preparing es_settings.xml"
      cp -f "$component_config/es_settings.xml" "$es_de_config"
      set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es-de"
      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$esde_downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$esde_themes_path" "es-de"
      dir_prep "$esde_gamelists_path" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$esde_collections_path" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$esde_scripts_path" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$esde_screensavers_path" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$esde_custom_systems_path" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
      dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
      log d "Generating roms system folders"
      start::es-de --create-system-dirs
    ;;

    postmove)
      log i "--------------------------------"
      log i "Post-moving ES-DE"
      log i "--------------------------------"

      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$esde_downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$esde_themes_path" "es-de"
      dir_prep "$esde_gamelists_path" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$esde_collections_path" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$esde_scripts_path" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$esde_screensavers_path" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$esde_custom_systems_path" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
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
    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Rebuilding Folder Iconsets In Progress" < "$progress_pipe" &
    local zenity_pid=$!

    local progress_fd
    exec {progress_fd}>"$progress_pipe"

    handle_folder_iconsets "$current_iconset"

    echo "100" >&$progress_fd

    exec {progress_fd}>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"    
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
  # The %COMPONENT_PATH% placeholder in entries is resolved to the component's install path from the cache.
  all_entries=$(jq -c '
    [.[] |
      .component_path as $component_path |
      .manifest | to_entries[] |
      .key as $component_key |
      (.value.es_de_config.es_find_rules // {}) |
      (
        (.emulators // [] | .[] | {block_type: "emulator", name: .name, description: (.description // ""), rules: .rules, component_key: $component_key}),
        (.cores // [] | .[] | {block_type: "core", name: .name, description: (.description // ""), rules: .rules, component_key: $component_key})
      ) |
      .rules |= [.[] | .entries |= [.[] | gsub("%COMPONENT_PATH%"; $component_path)]]
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
 
  # Merge systems: group by name, merge commands sorted by priority.
  # Commands without a priority field default to 999 (sort last).
  local merged_systems
  merged_systems=$(printf '%s' "$all_systems" | jq -c '
    # Generate both lowercase and uppercase for each extension, then deduplicate
    def expand_extensions: split(" ") | map(., ascii_downcase, ascii_upcase) | unique | join(" ");
 
    group_by(.name) | map(
      if length == 1 then
        # Single contributor: sort commands by priority, then clean up
        .[0] | del(.component_name, .component_key) |
        .extension |= expand_extensions |
        .commands |= (sort_by(.priority // 999) | [.[] | del(.priority)])
      else
        # Multiple contributors: first wins for metadata, merge all commands,
        # merge extension lists across contributors then expand cases,
        # and annotate only labels that conflict (same label from different contributors)
        .[0] as $first |
        [.[] | .component_name as $component_name | .commands[] | {label, command, priority: (.priority // 999), component_name: $component_name}] as $all_cmds |
        # Find labels that appear more than once
        [$all_cmds | group_by(.label) | .[] | select(length > 1) | .[0].label] as $dup_labels |
        {
          name: $first.name,
          fullname: $first.fullname,
          path: $first.path,
          extension: ([.[].extension | split(" ")[]] | unique | join(" ") | expand_extensions),
          commands: [$all_cmds | sort_by(.priority) | .[] | {
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

generate_es_de_diff_report() {
  # Compare generated es_find_rules.xml and es_systems.xml against official
  # upstream ES-DE files and produce a report of additions and differences.
  # USAGE: generate_es_de_diff_report
 
  local report=""
  local section_count=0
 
  # es_find_rules.xml: report upstream names missing from generated 
  if [[ -f "$es_find_rules" && -f "$es_find_rules_official" ]]; then
    local -a gen_emulators off_emulators gen_cores off_cores missing_names=()
 
    mapfile -t gen_emulators < <(xmlstarlet sel -t -m '//emulator' -v '@name' -n "$es_find_rules" 2>/dev/null)
    mapfile -t off_emulators < <(xmlstarlet sel -t -m '//emulator' -v '@name' -n "$es_find_rules_official" 2>/dev/null)
    mapfile -t gen_cores < <(xmlstarlet sel -t -m '//core' -v '@name' -n "$es_find_rules" 2>/dev/null)
    mapfile -t off_cores < <(xmlstarlet sel -t -m '//core' -v '@name' -n "$es_find_rules_official" 2>/dev/null)
 
    for emu_name in "${off_emulators[@]}"; do
      [[ -z "$emu_name" ]] && continue
      if ! printf '%s\n' "${gen_emulators[@]}" | grep -qxF "$emu_name"; then
        missing_names+=("emulator: $emu_name")
      fi
    done
 
    for core_name in "${off_cores[@]}"; do
      [[ -z "$core_name" ]] && continue
      if ! printf '%s\n' "${gen_cores[@]}" | grep -qxF "$core_name"; then
        missing_names+=("core: $core_name")
      fi
    done
 
    if [[ ${#missing_names[@]} -gt 0 ]]; then
      report+=$'\n'"=========================================="$'\n'
      report+="es_find_rules.xml: upstream names not in generated file (${#missing_names[@]})"$'\n'
      report+="=========================================="$'\n'
      for missing in "${missing_names[@]}"; do
        report+="  $missing"$'\n'
      done
      section_count=$((section_count + ${#missing_names[@]}))
    fi
  else
    log w "Skipping es_find_rules.xml comparison: generated or official file not found"
  fi
 
  # es_systems.xml: detailed per-system comparison 
  if [[ -f "$es_systems" && -f "$es_systems_official" && -f "$es_find_rules" ]]; then
    local sys_header="false"
 
    # Build set of known emulator names from the generated find_rules for command filtering
    local -a known_emulators
    mapfile -t known_emulators < <(xmlstarlet sel -t -m '//emulator' -v '@name' -n "$es_find_rules" 2>/dev/null)
 
    local -a gen_systems off_systems
    mapfile -t gen_systems < <(xmlstarlet sel -t -m '//system/name' -v '.' -n "$es_systems" 2>/dev/null)
    mapfile -t off_systems < <(xmlstarlet sel -t -m '//system/name' -v '.' -n "$es_systems_official" 2>/dev/null)
 
    for sys_name in "${gen_systems[@]}"; do
      [[ -z "$sys_name" ]] && continue
      local sys_issues=""
 
      if ! printf '%s\n' "${off_systems[@]}" | grep -qxF "$sys_name"; then
        # System only in generated file
        if [[ "$sys_header" == "false" ]]; then
          report+=$'\n'"=========================================="$'\n'
          report+="es_systems.xml differences"$'\n'
          report+="=========================================="$'\n'
          sys_header="true"
        fi
        report+=$'\n'"ADDITIONAL system: $sys_name (not in official file)"$'\n'
        section_count=$((section_count + 1))
        continue
      fi
 
      # Extension comparison
      # Normalize both to sorted lowercase sets for comparison
      local gen_ext off_ext gen_ext_norm off_ext_norm
      gen_ext=$(xmlstarlet sel -t -v "//system[name='$sys_name']/extension" "$es_systems" 2>/dev/null)
      off_ext=$(xmlstarlet sel -t -v "//system[name='$sys_name']/extension" "$es_systems_official" 2>/dev/null)
      gen_ext_norm=$(printf '%s' "$gen_ext" | tr ' ' '\n' | awk '{print tolower($0)}' | sort -u)
      off_ext_norm=$(printf '%s' "$off_ext" | tr ' ' '\n' | awk '{print tolower($0)}' | sort -u)
 
      local ext_missing ext_extra
      ext_missing=$(comm -23 <(echo "$off_ext_norm") <(echo "$gen_ext_norm") | tr '\n' ' ' | sed 's/ $//')
      ext_extra=$(comm -13 <(echo "$off_ext_norm") <(echo "$gen_ext_norm") | tr '\n' ' ' | sed 's/ $//')
 
      if [[ -n "$ext_missing" ]]; then
        sys_issues+="  Extensions in official but not generated: $ext_missing"$'\n'
      fi
      if [[ -n "$ext_extra" ]]; then
        sys_issues+="  Extensions in generated but not official: $ext_extra"$'\n'
      fi
 
      # Command comparison
      # Extract labels and commands from both files for this system
      local -a gen_labels gen_commands off_labels off_commands
      mapfile -t gen_labels < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '@label' -n "$es_systems" 2>/dev/null)
      mapfile -t gen_commands < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '.' -n "$es_systems" 2>/dev/null)
      mapfile -t off_labels < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '@label' -n "$es_systems_official" 2>/dev/null)
      mapfile -t off_commands < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '.' -n "$es_systems_official" 2>/dev/null)
 
      # Check each official command against generated
      local oi
      for oi in "${!off_labels[@]}"; do
        local off_label="${off_labels[$oi]}"
        local off_cmd="${off_commands[$oi]}"
        [[ -z "$off_label" ]] && continue
 
        # Extract emulator name from the command
        local cmd_emu=""
        if [[ "$off_cmd" =~ %EMULATOR_([^%]+)% ]]; then
          cmd_emu="${BASH_REMATCH[1]}"
        fi
 
        # Skip commands referencing emulators not in our generated find_rules
        if [[ -n "$cmd_emu" ]] && ! printf '%s\n' "${known_emulators[@]}" | grep -qxF "$cmd_emu"; then
          continue
        fi
 
        # Check if this label exists in the generated file
        local found_match="false"
        local gen_index
        for gen_index in "${!gen_labels[@]}"; do
          if [[ "${gen_labels[$gen_index]}" == "$off_label" ]]; then
            found_match="true"
            # Label matches: compare command content
            if [[ "${gen_commands[$gen_index]}" != "$off_cmd" ]]; then
              sys_issues+="  Command label \"$off_label\" differs:"$'\n'
              sys_issues+="    official:  $off_cmd"$'\n'
              sys_issues+="    generated: ${gen_commands[$gen_index]}"$'\n'
            fi
            break
          fi
        done
 
        if [[ "$found_match" == "false" ]]; then
          sys_issues+="  Missing command: \"$off_label\""$'\n'
          sys_issues+="    $off_cmd"$'\n'
        fi
      done
 
      # Report if any issues were found for this system
      if [[ -n "$sys_issues" ]]; then
        if [[ "$sys_header" == "false" ]]; then
          report+=$'\n'"=========================================="$'\n'
          report+="es_systems.xml differences"$'\n'
          report+="=========================================="$'\n'
          sys_header="true"
        fi
        report+=$'\n'"System: $sys_name"$'\n'
        report+="$sys_issues"
        section_count=$((section_count + 1))
      fi
    done
  else
    log w "Skipping es_systems.xml comparison: generated or official file not found"
  fi
 
  if [[ $section_count -gt 0 ]]; then
    log i "ES-DE diff report: $section_count item(s) found"
    printf '%s' "$report"
  else
    log i "ES-DE diff report: no differences found"
  fi
 
  return 0
}

check_duplicate_gamelist_entry() {
  # Checks if a <game> entry with a matching <path> already exists in the target gamelist.xml
  # USAGE: check_gamelist_entry "$component" "$entry_key"
  
  local component="$1"
  local entry_key="$2"

  local entry_data
  entry_data=$(jq -r --arg component "$component" --arg entry_key "$entry_key" \
    '.[] | .manifest | select(has($component)) | .[$component].es_de_gamelist_entries.entries[$entry_key]' \
    "$component_manifest_cache_file")

  if [[ -z "$entry_data" || "$entry_data" == "null" ]]; then
    log e "Gamelist entry \"$entry_key\" not found in manifest for component \"$component\""
    return 1
  fi

  local system
  system=$(jq -r '.system' <<< "$entry_data")
  local path
  path=$(jq -r '.gamelist_data.path' <<< "$entry_data")

  [[ "$path" != ./* ]] && path="./$path"

  local gamelist_file="$esde_gamelists_dir/$system/gamelist.xml"

  if [[ ! -f "$gamelist_file" ]]; then
    return 1
  fi

  local match_count
  match_count=$(xmlstarlet sel -t -v "count(/gameList/game[path='$path'])" "$gamelist_file")

  if [[ "$match_count" -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

create_gamelist_entry() {
  # Creates a <game> entry in the target gamelist.xml using data from the component manifest
  # Creates the gamelist.xml file and parent directory if they do not exist
  # Handles file creation (create_file), file copying (source_file/dest_file), and media deployment (image_root) from optional manifest data
  # USAGE: create_gamelist_entry "$component" "$entry_key"

  local component="$1"
  local entry_key="$2"

  local gamelist_block
  gamelist_block=$(jq -r --arg component "$component" \
  '.[] | .manifest | select(has($component)) | .[$component].es_de_gamelist_entries' \
  "$component_manifest_cache_file")

  if [[ -z "$gamelist_block" || "$gamelist_block" == "null" ]]; then
    log e "No es_de_gamelist_entries found in manifest for component \"$component\""
    return 1
  fi

  local entry_data
  entry_data=$(jq -r --arg component "$component" --arg entry_key "$entry_key" \
    '.[] | .manifest | select(has($component)) | .[$component].es_de_gamelist_entries.entries[$entry_key]' \
    "$component_manifest_cache_file")

  if [[ -z "$entry_data" || "$entry_data" == "null" ]]; then
    log e "Gamelist entry \"$entry_key\" not found in manifest for component \"$component\""
    return 1
  fi

  local system
  system=$(jq -r '.system' <<< "$entry_data")

  if ! check_duplicate_gamelist_entry "$component" "$entry_key"; then

    local gamelist_dir="$esde_gamelists_dir/$system"
    local gamelist_file="$gamelist_dir/gamelist.xml"

    mkdir -p "$gamelist_dir"

    if [[ ! -f "$gamelist_file" ]]; then
      printf '<?xml version="1.0"?>\n<gameList>\n</gameList>\n' > "$gamelist_file"
    fi

    local -a xml_args=("-L" "-s" "/gameList" "-t" "elem" "-n" "game" "-v" "")

    while IFS=$'\t' read -r key value; do
      if [[ "$key" == "path" && "$value" != ./* ]]; then
        value="./$value"
      fi
      xml_args+=("-s" "/gameList/game[last()]" "-t" "elem" "-n" "$key" "-v" "$value")
    done < <(jq -r '.gamelist_data | to_entries[] | "\(.key)\t\(.value)"' <<< "$entry_data")

    xmlstarlet ed "${xml_args[@]}" "$gamelist_file"
    xmlstarlet fo -t "$gamelist_file" > "${gamelist_file}.tmp" && mv "${gamelist_file}.tmp" "$gamelist_file"

    log i "Created gamelist entry \"$entry_key\" in $gamelist_file"

    # Handle file creation
    local create_file_path
    create_file_path=$(jq -r '.create_file // empty' <<< "$entry_data")

    if [[ -n "$create_file_path" ]]; then
      local resolved_create_path
      if resolved_create_path=$(resolve_path "$component" "$create_file_path"); then
        mkdir -p "$(dirname "$resolved_create_path")"
        if touch "$resolved_create_path"; then
          log i "Created file: $resolved_create_path"
        else
          log e "Failed to create file at $resolved_create_path"
          return 1
        fi
      else
        log e "Failed to resolve create_file path for entry \"$entry_key\""
        return 1
      fi
    fi

    # Handle file copying
    local source_file_path
    source_file_path=$(jq -r '.source_file // empty' <<< "$entry_data")
    local dest_file_path
    dest_file_path=$(jq -r '.dest_file // empty' <<< "$entry_data")

    if [[ -n "$source_file_path" && -n "$dest_file_path" ]]; then
      local resolved_source_path resolved_dest_path
      if resolved_source_path=$(resolve_path "$component" "$source_file_path") && \
        resolved_dest_path=$(resolve_path "$component" "$dest_file_path"); then
        if [[ -f "$resolved_source_path" ]]; then
          mkdir -p "$(dirname "$resolved_dest_path")"
          if cp "$resolved_source_path" "$resolved_dest_path"; then
            log i "Copied file: $resolved_source_path to $resolved_dest_path"
          else
            log e "Could not copy $resolved_source_path to $resolved_dest_path"
          fi
        else
          log e "Source file not found: $resolved_source_path"
          return 1
        fi
      else
        log e "Failed to resolve source_file/dest_file paths for entry \"$entry_key\""
        return 1
      fi
    fi

    # Handle media deployment
    local image_root
    image_root=$(jq -r '.image_root // empty' <<< "$gamelist_block")

    if [[ -n "$image_root" ]]; then
      local resolved_image_root
      if resolved_image_root=$(resolve_path "$component" "$image_root"); then
        local path_value
        path_value=$(jq -r '.gamelist_data.path' <<< "$entry_data")
        [[ "$path_value" == ./* ]] && path_value="${path_value#./}"

        local source_media_dir="$resolved_image_root/$entry_key"

        if [[ -d "$source_media_dir" ]]; then
          while IFS= read -r source_file; do
            local relative_path="${source_file#"$source_media_dir"/}"
            local dest_dir="$esde_downloaded_media_path/$system/$(dirname "$relative_path")"
            mkdir -p "$dest_dir"
            rsync -a "$source_file" "$dest_dir/"
            log i "Deployed media: $source_file -> $dest_dir/$path_value"
          done < <(find "$source_media_dir" -type f -name "$path_value")
        else
          log w "Media source directory not found: $source_media_dir"
        fi
      else
        log e "Failed to resolve image_root path for component \"$component\""
      fi
    fi
  else
    log e "Cannot create gamelist entry for \"$entry_key\" because it already exists in the $system gamelist."
  fi
}

remove_gamelist_entry() {
  # Removes a <game> entry from the target gamelist.xml matching the <path> from the component manifest
  # Removes associated files and media created by create_gamelist_entry
  # Removes the gamelist.xml file and parent directory if no content remains
  # USAGE: remove_gamelist_entry "$component" "$entry_key"

  local component="$1"
  local entry_key="$2"

  local gamelist_block
  gamelist_block=$(jq -r --arg component "$component" \
    '.[] | .manifest | select(has($component)) | .[$component].es_de_gamelist_entries' \
    "$component_manifest_cache_file")

  if [[ -z "$gamelist_block" || "$gamelist_block" == "null" ]]; then
    log e "No es_de_gamelist_entries found in manifest for component \"$component\""
    return 1
  fi

  local entry_data
  entry_data=$(jq -r --arg component "$component" --arg entry_key "$entry_key" \
    '.[] | .manifest | select(has($component)) | .[$component].es_de_gamelist_entries.entries[$entry_key]' \
    "$component_manifest_cache_file")

  if [[ -z "$entry_data" || "$entry_data" == "null" ]]; then
    log e "Gamelist entry \"$entry_key\" not found in manifest for component \"$component\""
    return 1
  fi

  local system
  system=$(jq -r '.system' <<< "$entry_data")
  local path
  path=$(jq -r '.gamelist_data.path' <<< "$entry_data")
  [[ "$path" != ./* ]] && path="./$path"

  local gamelist_dir="$esde_gamelists_dir/$system"
  local gamelist_file="$gamelist_dir/gamelist.xml"

  if [[ ! -f "$gamelist_file" ]]; then
    log w "Gamelist file not found: $gamelist_file"
    return 1
  fi

  xmlstarlet ed -L -d "/gameList/game[path='$path']" "$gamelist_file"
  xmlstarlet fo -t "$gamelist_file" > "${gamelist_file}.tmp" && mv "${gamelist_file}.tmp" "$gamelist_file"

  log i "Removed gamelist entry \"$entry_key\" from $gamelist_file"

  # Remove associated created file
  local create_file_path
  create_file_path=$(jq -r '.create_file // empty' <<< "$entry_data")

  if [[ -n "$create_file_path" ]]; then
    local resolved_create_path
    if resolved_create_path=$(resolve_path "$component" "$create_file_path"); then
      if [[ -f "$resolved_create_path" ]]; then
        rm -f "$resolved_create_path"
        log i "Removed created file: $resolved_create_path"
      fi
    fi
  fi

  # Remove associated copied file
  local dest_file_path
  dest_file_path=$(jq -r '.dest_file // empty' <<< "$entry_data")

  if [[ -n "$dest_file_path" ]]; then
    local resolved_dest_path
    if resolved_dest_path=$(resolve_path "$component" "$dest_file_path"); then
      if [[ -f "$resolved_dest_path" ]]; then
        rm -f "$resolved_dest_path"
        log i "Removed copied file: $resolved_dest_path"
      fi
    fi
  fi

  # Remove associated media files
  local image_root
  image_root=$(jq -r '.image_root // empty' <<< "$gamelist_block")

  if [[ -n "$image_root" ]]; then
    local resolved_image_root
    if resolved_image_root=$(resolve_path "$component" "$image_root"); then
      local path_value="$path"
      [[ "$path_value" == ./* ]] && path_value="${path_value#./}"

      local source_media_dir="$resolved_image_root/$entry_key"

      if [[ -d "$source_media_dir" ]]; then
        while IFS= read -r source_file; do
          local relative_path="${source_file#"$source_media_dir"/}"
          local dest_file="$esde_downloaded_media_path/$system/$relative_path"

          if [[ -f "$dest_file" ]]; then
            rm -f "$dest_file"
            log i "Removed media file: $dest_file"

            local parent_dir
            parent_dir=$(dirname "$dest_file")
            prune_empty_parents "$parent_dir" "$esde_downloaded_media_path/$system"
          fi
        done < <(find "$source_media_dir" -type f -name "$path_value")
      fi
    fi
  fi

  # Check if gamelist.xml should be cleaned up
  local child_count
  child_count=$(xmlstarlet sel -t -v "count(/gameList/*)" "$gamelist_file")

  if [[ "$child_count" -eq 0 ]]; then
    local text_content
    text_content=$(xmlstarlet sel -t -v "normalize-space(/gameList)" "$gamelist_file")

    if [[ -z "$text_content" ]]; then
      rm -f "$gamelist_file"
      rmdir "$gamelist_dir" 2>/dev/null || true
      log i "Removed empty gamelist file and directory: $gamelist_dir"
    fi
  fi
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
    set_setting_value "$es_settings" "UserThemeDirectory" "$esde_themes_path" "es-de"
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
