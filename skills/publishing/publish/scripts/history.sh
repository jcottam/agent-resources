#!/usr/bin/env bash
set -euo pipefail

HISTORY_FILE="$HOME/.publish-history.json"

usage() {
  echo "Usage: history.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  list [--all]       Show recent publishes (default: last 10)"
  echo "  search <query>     Filter entries by key or local path"
  echo "  prune              Remove entries whose R2 objects no longer exist"
  echo "  clear              Delete all history"
  exit 1
}

ensure_history() {
  if [[ ! -f "$HISTORY_FILE" ]]; then
    echo "No publish history found."
    exit 0
  fi
}

CMD="${1:-}"
shift || true

case "$CMD" in
  list)
    ensure_history
    SHOW_ALL="false"
    if [[ "${1:-}" == "--all" ]]; then
      SHOW_ALL="true"
    fi
    python3 -c "
import json, sys

with open(sys.argv[1]) as f:
    history = json.load(f)

if not history:
    print('No publish history.')
    sys.exit(0)

show_all = sys.argv[2] == 'true'
entries = history if show_all else history[-10:]

if not show_all and len(history) > 10:
    print(f'Showing last 10 of {len(history)} entries (use --all to see all)\n')

for i, entry in enumerate(entries):
    size_kb = entry.get('size', 0) / 1024
    print(f\"{entry['publishedAt']}  {entry['key']}\")
    print(f\"  URL:  {entry['url']}\")
    print(f\"  Type: {entry['contentType']}  Size: {size_kb:.1f} KB\")
    if i < len(entries) - 1:
        print()
" "$HISTORY_FILE" "$SHOW_ALL"
    ;;

  search)
    ensure_history
    QUERY="${1:-}"
    if [[ -z "$QUERY" ]]; then
      echo "Error: search query is required" >&2
      echo "Usage: history.sh search <query>" >&2
      exit 1
    fi
    python3 -c "
import json, sys

query = sys.argv[2].lower()
with open(sys.argv[1]) as f:
    history = json.load(f)

matches = [e for e in history if query in e.get('key','').lower() or query in e.get('localPath','').lower() or query in e.get('url','').lower()]

if not matches:
    print(f'No entries matching \"{sys.argv[2]}\".')
    sys.exit(0)

print(f'Found {len(matches)} match(es):\n')
for i, entry in enumerate(matches):
    size_kb = entry.get('size', 0) / 1024
    print(f\"{entry['publishedAt']}  {entry['key']}\")
    print(f\"  URL:   {entry['url']}\")
    print(f\"  From:  {entry.get('localPath', 'unknown')}\")
    print(f\"  Type:  {entry['contentType']}  Size: {size_kb:.1f} KB\")
    if i < len(matches) - 1:
        print()
" "$HISTORY_FILE" "$QUERY"
    ;;

  prune)
    ensure_history
    echo "Reading config for bucket name..."

    CONFIG_FILE="$HOME/.publish.json"
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "Error: config not found at $CONFIG_FILE" >&2
      echo "Run setup.sh first." >&2
      exit 1
    fi

    BUCKET=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['bucket'])" "$CONFIG_FILE")

    python3 -c "
import json, subprocess, sys

bucket = sys.argv[2]
with open(sys.argv[1]) as f:
    history = json.load(f)

if not history:
    print('History is empty.')
    sys.exit(0)

print(f'Checking {len(history)} entries against R2...')
kept = []
removed = 0

for entry in history:
    key = entry['key']
    result = subprocess.run(
        ['npx', 'wrangler', 'r2', 'object', 'get', f'{bucket}/{key}', '--file', '/dev/null'],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        kept.append(entry)
    else:
        removed += 1
        print(f'  Removed: {key}')

with open(sys.argv[1], 'w') as f:
    json.dump(kept, f, indent=2)

print(f'\nPruned {removed} entries. {len(kept)} remaining.')
" "$HISTORY_FILE" "$BUCKET"
    ;;

  clear)
    ensure_history
    read -rp "Delete all publish history? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm "$HISTORY_FILE"
      echo "History cleared."
    else
      echo "Cancelled."
    fi
    ;;

  *)
    usage
    ;;
esac
