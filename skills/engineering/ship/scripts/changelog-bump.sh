#!/usr/bin/env bash
set -euo pipefail

# Manages the project changelog: reads the current version, computes the next
# version, and prepends a new entry.  Supports both CHANGELOG.json and
# CHANGELOG.md (defaults to MD when neither exists).
#
# Usage:
#   changelog-bump.sh info                   # print current version + path
#   changelog-bump.sh bump <patch|minor|major> '<changes-json>'
#
# The changes-json argument is a JSON object like:
#   {"features":["Added X"],"fixes":["Fixed Y"]}
#
# Outputs JSON to stdout with the result of the operation.

ACTION="${1:-info}"

# --- detect changelog format --------------------------------------------------

if [[ -f "CHANGELOG.json" ]]; then
  CHANGELOG="CHANGELOG.json"
  FORMAT="json"
else
  CHANGELOG="CHANGELOG.md"
  FORMAT="md"
fi

# --- ensure file exists -------------------------------------------------------

if [[ ! -f "$CHANGELOG" ]]; then
  if [[ "$FORMAT" == "json" ]]; then
    echo "[]" > "$CHANGELOG"
  else
    printf "# Changelog\n\nAll notable changes to this project.\n" > "$CHANGELOG"
  fi
fi

# --- read current version -----------------------------------------------------

current_version() {
  if [[ "$FORMAT" == "json" ]]; then
    node -e "
      const fs = require('fs');
      const cl = JSON.parse(fs.readFileSync('./$CHANGELOG', 'utf8'));
      console.log(cl.length > 0 && cl[0].version ? cl[0].version : '0.0.0');
    "
  else
    node -e "
      const fs = require('fs');
      const md = fs.readFileSync('./$CHANGELOG', 'utf8');
      const m = md.match(/^## \[([^\]]+)\]/m);
      console.log(m ? m[1] : '0.0.0');
    "
  fi
}

# --- check if latest entry is a draft (pr: null / no PR link) ----------------

latest_is_draft() {
  if [[ "$FORMAT" == "json" ]]; then
    node -e "
      const fs = require('fs');
      const cl = JSON.parse(fs.readFileSync('./$CHANGELOG', 'utf8'));
      const draft = cl.length > 0 && cl[0].pr === null;
      console.log(draft ? 'true' : 'false');
    "
  else
    node -e "
      const fs = require('fs');
      const md = fs.readFileSync('./$CHANGELOG', 'utf8');
      const m = md.match(/^## \[([^\]]+)\](.*)/m);
      if (!m) { console.log('false'); process.exit(0); }
      const hasLink = /\(#\d+\)/.test(m[2] || '');
      console.log(hasLink ? 'false' : 'true');
    "
  fi
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
    jq -n --arg v "$CURRENT" --arg f "$CHANGELOG" --arg fmt "$FORMAT" \
      '{ currentVersion: $v, file: $f, format: $fmt }'
    ;;

  bump)
    LEVEL="${2:?Usage: changelog-bump.sh bump <patch|minor|major> '<changes-json>'}"
    CHANGES="${3:?Missing changes JSON argument}"
    CURRENT=$(current_version)
    NEXT=$(bump_version "$CURRENT" "$LEVEL")
    TODAY=$(date +%Y-%m-%d)
    IS_DRAFT=$(latest_is_draft)
    UPDATED=false

    if [[ "$FORMAT" == "json" ]]; then
      if [[ "$IS_DRAFT" == "true" ]]; then
        UPDATED=true
        node -e "
          const fs = require('fs');
          const cl = JSON.parse(fs.readFileSync('$CHANGELOG', 'utf8'));
          cl[0].version = '$NEXT';
          cl[0].date = '$TODAY';
          cl[0].changes = $CHANGES;
          fs.writeFileSync('$CHANGELOG', JSON.stringify(cl, null, 2) + '\n');
        "
      else
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
      fi
    else
      if [[ "$IS_DRAFT" == "true" ]]; then
        UPDATED=true
        node -e "
          const fs = require('fs');
          let md = fs.readFileSync('$CHANGELOG', 'utf8');
          const changes = $CHANGES;
          let section = '## [$NEXT] - $TODAY\n';
          for (const [cat, items] of Object.entries(changes)) {
            const heading = cat.charAt(0).toUpperCase() + cat.slice(1);
            section += '\n### ' + heading + '\n\n';
            for (const item of items) section += '- ' + item + '\n';
          }
          md = md.replace(/^## \[[^\]]+\][\s\S]*?(?=^## \[|\Z)/m, section + '\n');
          fs.writeFileSync('$CHANGELOG', md);
        "
      else
        node -e "
          const fs = require('fs');
          let md = fs.readFileSync('$CHANGELOG', 'utf8');
          const changes = $CHANGES;
          let section = '## [$NEXT] - $TODAY\n';
          for (const [cat, items] of Object.entries(changes)) {
            const heading = cat.charAt(0).toUpperCase() + cat.slice(1);
            section += '\n### ' + heading + '\n\n';
            for (const item of items) section += '- ' + item + '\n';
          }
          const marker = md.indexOf('## [');
          if (marker === -1) {
            md = md.trimEnd() + '\n\n' + section;
          } else {
            md = md.slice(0, marker) + section + '\n' + md.slice(marker);
          }
          fs.writeFileSync('$CHANGELOG', md);
        "
      fi
    fi

    jq -n \
      --arg prev "$CURRENT" \
      --arg next "$NEXT" \
      --arg date "$TODAY" \
      --arg fmt "$FORMAT" \
      --argjson updated "$UPDATED" \
      '{ previousVersion: $prev, newVersion: $next, date: $date, format: $fmt, updated: $updated }'
    ;;

  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
