#!/bin/bash

# Extract emulator data from es_find_rules.xml and all related system/command
# data from es_systems.xml, then generate the corresponding es_de_config
# manifest JSON block for that emulator component.

# USAGE: es_de_manifest_helper.sh <emulator_name> [es_find_rules.xml] [es_systems.xml]
#   emulator_name:     The emulator to extract (e.g. "RETROARCH", "PCSX2", "MAME")
#   es_find_rules.xml: Path to the ES-DE find rules file (default: ./es_find_rules.xml)
#   es_systems.xml:    Path to the ES-DE systems file (default: ./es_systems.xml)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <emulator_name> [es_find_rules.xml] [es_systems.xml]" >&2
  exit 1
fi

emulator_name=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
find_rules_file="${2:-./es_find_rules.xml}"
systems_file="${3:-./es_systems.xml}"

if [[ ! -f "$find_rules_file" ]]; then
  echo "Error: Find rules file not found: $find_rules_file" >&2
  exit 1
fi

if [[ ! -f "$systems_file" ]]; then
  echo "Error: Systems file not found: $systems_file" >&2
  exit 1
fi

echo "Starting manifest data creation, please wait..."
echo ""

# Extract emulator block from es_find_rules.xml
emu_exists=$(xmlstarlet sel -t -v "count(//emulator[@name='$emulator_name'])" "$find_rules_file" 2>/dev/null)

if [[ "$emu_exists" == "0" ]]; then
  echo "Error: Emulator '$emulator_name' not found in $find_rules_file" >&2
  exit 1
fi

echo "Found entries for emulator $emulator_name"

component_key=$(printf '%s' "$emulator_name" | tr '[:upper:]' '[:lower:]')

# Extract description from the XML comment inside the emulator block
emu_description=$(xmlstarlet sel -t -m "//emulator[@name='$emulator_name']/comment()" -v '.' "$find_rules_file" 2>/dev/null | sed 's/^ *//;s/ *$//' | head -1 || true)

# Build a single staticpath rule with the default component launcher path.
emu_rules_json=$(jq -nc --arg component_key "$component_key" \
  '[{type: "staticpath", entries: ["$rd_components/\($component_key)/component_launcher.sh"]}]')

emulators_json=$(jq -nc \
  --arg name "$emulator_name" \
  --arg desc "$emu_description" \
  --argjson rules "$emu_rules_json" \
  '[{name: $name, description: $desc, rules: $rules}]')

# Check for a matching core block
core_exists=$(xmlstarlet sel -t -v "count(//core[@name='$emulator_name'])" "$find_rules_file" 2>/dev/null)

cores_json="[]"
if [[ "$core_exists" != "0" ]]; then
  core_description=$(xmlstarlet sel -t -m "//core[@name='$emulator_name']/comment()" -v '.' "$find_rules_file" 2>/dev/null | sed 's/^ *//;s/ *$//' | head -1 || true)

  # Build a single corepath rule with a placeholder value.
  core_rules_json='[{"type": "corepath", "entries": ["REPLACE WITH CORE PATH"]}]'

  cores_json=$(jq -nc \
    --arg name "$emulator_name" \
    --arg desc "$core_description" \
    --argjson rules "$core_rules_json" \
    '[{name: $name, description: $desc, rules: $rules}]')
fi

# Build es_find_rules block
find_rules_block=$(jq -nc --argjson emulators "$emulators_json" '{emulators: $emulators}')
if [[ $(printf '%s' "$cores_json" | jq 'length') -gt 0 ]]; then
  find_rules_block=$(printf '%s' "$find_rules_block" | jq -c --argjson cores "$cores_json" '.cores = $cores')
fi

emu_placeholder="%EMULATOR_${emulator_name}%"

mapfile -t all_systems < <(xmlstarlet sel -t -m '//system/name' -v '.' -n "$systems_file" 2>/dev/null)

systems_json="[]"
matching_systems=()

for sys_name in "${all_systems[@]}"; do
  [[ -z "$sys_name" ]] && continue

  # Get all commands for this system
  mapfile -t cmd_labels < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '@label' -n "$systems_file" 2>/dev/null)
  mapfile -t cmd_values < <(xmlstarlet sel -t -m "//system[name='$sys_name']/command" -v '.' -n "$systems_file" 2>/dev/null)

  # Filter to only commands referencing this emulator
  matched_cmds_json="[]"
  has_match="false"

  for i in "${!cmd_values[@]}"; do
    if [[ "${cmd_values[$i]}" == *"$emu_placeholder"* ]]; then
      has_match="true"
      # Priority based on global position in the original XML
      priority=$(( (i + 1) * 10 ))
      matched_cmds_json=$(printf '%s' "$matched_cmds_json" | jq -c \
        --arg label "${cmd_labels[$i]}" \
        --arg command "${cmd_values[$i]}" \
        --argjson priority "$priority" \
        '. + [{label: $label, command: $command, priority: $priority}]')

      echo "Emulator $emulator_name has a command line in system $sys_name"
    fi
  done

  if [[ "$has_match" == "false" ]]; then
    continue
  fi

  matching_systems+=("$sys_name")

  # Extract system metadata
  fullname=$(xmlstarlet sel -t -v "//system[name='$sys_name']/fullname" "$systems_file" 2>/dev/null)
  sys_path=$(xmlstarlet sel -t -v "//system[name='$sys_name']/path" "$systems_file" 2>/dev/null)
  extensions_raw=$(xmlstarlet sel -t -v "//system[name='$sys_name']/extension" "$systems_file" 2>/dev/null)
  platform=$(xmlstarlet sel -t -v "//system[name='$sys_name']/platform" "$systems_file" 2>/dev/null)
  theme=$(xmlstarlet sel -t -v "//system[name='$sys_name']/theme" "$systems_file" 2>/dev/null)

  # Deduplicate extensions to lowercase only
  extensions_deduped=$(printf '%s' "$extensions_raw" | tr ' ' '\n' | awk '{print tolower($0)}' | sort -u | tr '\n' ' ' | sed 's/ $//')

  systems_json=$(printf '%s' "$systems_json" | jq -c \
    --arg name "$sys_name" \
    --arg fullname "$fullname" \
    --arg path "$sys_path" \
    --arg extension "$extensions_deduped" \
    --argjson commands "$matched_cmds_json" \
    --arg platform "$platform" \
    --arg theme "$theme" \
    '. + [{name: $name, fullname: $fullname, path: $path, extension: $extension, commands: $commands, platform: $platform, theme: $theme}]')
done

# Assemble the final es_de_config block
es_de_config=$(jq -nc \
  --argjson find_rules "$find_rules_block" \
  --argjson systems "$systems_json" \
  '{
    es_de_config: {
      es_find_rules: $find_rules,
      es_systems: $systems
    }
  }')

sys_count=$(printf '%s' "$systems_json" | jq 'length')
sys_list="${matching_systems[*]:-none}"

echo "es_de_config manifest block for emulator: $emulator_name"
echo " Matching systems ($sys_count): $sys_list"
echo " Core block included: $(if [[ "$core_exists" != "0" ]]; then echo "yes"; else echo "no"; fi)"
echo " NOTE: staticpath entries default to \$rd_components/$component_key/component_launcher.sh"
echo ""
printf '%s' "$es_de_config" | jq .
