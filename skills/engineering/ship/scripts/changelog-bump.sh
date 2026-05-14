#!/usr/bin/env bash
set -euo pipefail

# Manages CHANGELOG.json: reads the current version, computes the next version,
# and prepends a new entry skeleton.
#
# Usage:
#   changelog-bump.sh info                   # print current version + path
#   changelog-bump.sh bump <patch|minor|major> '<changes-json>'
#
# The changes-json argument is a JSON object like:
#   {"features":["Added X"],"fixes":["Fixed Y"]}
#
# Outputs JSON to stdout with the result of the operation.

CHANGELOG="CHANGELOG.json"
ACTION="${1:-info}"

# --- ensure file exists -------------------------------------------------------

if [[ ! -f "$CHANGELOG" ]]; then
  echo "[]" > "$CHANGELOG"
fi

# --- read current version -----------------------------------------------------

current_version() {
  node -e "
    const cl = require('./$CHANGELOG');
    console.log(cl.length > 0 && cl[0].version ? cl[0].version : '0.0.0');
  "
}

# --- bump version -------------------------------------------------------------

bump_version() {
  local current="$1" level="$2"
  node -e "
    const [major, minor, patch] = '$current'.split('.').map(Number);
    const level = '$level';
    if (level === 'major') console.log((major+1) + '.0.0');
    else if (level === 'minor') console.log(major + '.' + (minor+1) + '.0');
    else console.log(major + '.' + minor + '.' + (patch+1));
  "
}

# --- actions ------------------------------------------------------------------

case "$ACTION" in
  info)
    CURRENT=$(current_version)
    jq -n --arg v "$CURRENT" --arg f "$CHANGELOG" '{ currentVersion: $v, file: $f }'
    ;;

  bump)
    LEVEL="${2:?Usage: changelog-bump.sh bump <patch|minor|major> '<changes-json>'}"
    CHANGES="${3:?Missing changes JSON argument}"
    CURRENT=$(current_version)
    NEXT=$(bump_version "$CURRENT" "$LEVEL")
    TODAY=$(date +%Y-%m-%d)

    node -e "
      const fs = require('fs');
      const cl = JSON.parse(fs.readFileSync('$CHANGELOG', 'utf8'));
      const entry = {
        version: '$NEXT',
        date: '$TODAY',
        pr: null,
        changes: $CHANGES
      };
      cl.unshift(entry);
      fs.writeFileSync('$CHANGELOG', JSON.stringify(cl, null, 2) + '\n');
    "

    jq -n \
      --arg prev "$CURRENT" \
      --arg next "$NEXT" \
      --arg date "$TODAY" \
      '{ previousVersion: $prev, newVersion: $next, date: $date }'
    ;;

  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
