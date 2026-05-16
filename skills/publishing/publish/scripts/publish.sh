#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$HOME/.publish.json"
HISTORY_FILE="$HOME/.publish-history.json"

usage() {
  echo "Usage: publish.sh <file-path> [--key <custom-key>]"
  echo ""
  echo "Upload a file to Cloudflare R2 and return a public URL."
  echo ""
  echo "Options:"
  echo "  --key <name>   Override the auto-generated object key"
  exit 1
}

# --- Parse arguments ---

FILE_PATH=""
CUSTOM_KEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)
      CUSTOM_KEY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH="$1"
      else
        echo "Error: unexpected argument '$1'" >&2
        usage
      fi
      shift
      ;;
  esac
done

if [[ -z "$FILE_PATH" ]]; then
  echo "Error: file path is required" >&2
  usage
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: file not found: $FILE_PATH" >&2
  exit 1
fi

# --- Read config ---

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config not found at $CONFIG_FILE" >&2
  echo "Run setup.sh first to configure your R2 bucket." >&2
  exit 1
fi

BUCKET=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['bucket'])" "$CONFIG_FILE" 2>/dev/null)
PUBLIC_BASE_URL=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['publicBaseUrl'])" "$CONFIG_FILE" 2>/dev/null)

if [[ -z "$BUCKET" || -z "$PUBLIC_BASE_URL" ]]; then
  echo "Error: ~/.publish.json must contain 'bucket' and 'publicBaseUrl'" >&2
  exit 1
fi

# Strip trailing slash from base URL
PUBLIC_BASE_URL="${PUBLIC_BASE_URL%/}"

# --- Detect content type ---

detect_content_type() {
  local ext="${1##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    html|htm)   echo "text/html" ;;
    css)        echo "text/css" ;;
    js|mjs)     echo "application/javascript" ;;
    json)       echo "application/json" ;;
    xml)        echo "application/xml" ;;
    svg)        echo "image/svg+xml" ;;
    png)        echo "image/png" ;;
    jpg|jpeg)   echo "image/jpeg" ;;
    gif)        echo "image/gif" ;;
    webp)       echo "image/webp" ;;
    ico)        echo "image/x-icon" ;;
    pdf)        echo "application/pdf" ;;
    zip)        echo "application/zip" ;;
    gz|gzip)    echo "application/gzip" ;;
    tar)        echo "application/x-tar" ;;
    txt)        echo "text/plain" ;;
    md)         echo "text/markdown" ;;
    csv)        echo "text/csv" ;;
    woff)       echo "font/woff" ;;
    woff2)      echo "font/woff2" ;;
    ttf)        echo "font/ttf" ;;
    otf)        echo "font/otf" ;;
    mp4)        echo "video/mp4" ;;
    webm)       echo "video/webm" ;;
    mp3)        echo "audio/mpeg" ;;
    wav)        echo "audio/wav" ;;
    ogg)        echo "audio/ogg" ;;
    *)          echo "application/octet-stream" ;;
  esac
}

# --- Generate key ---

generate_slug() {
  local filename
  filename=$(basename "$1")
  local name="${filename%.*}"
  local ext="${filename##*.}"

  # Lowercase, replace non-alphanumeric with hyphens, collapse multiples, trim edges
  local slug
  slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//')

  local today
  today=$(date +%Y-%m-%d)

  echo "${slug}-${today}.${ext}"
}

if [[ -n "$CUSTOM_KEY" ]]; then
  KEY="$CUSTOM_KEY"
else
  KEY=$(generate_slug "$FILE_PATH")
fi

CONTENT_TYPE=$(detect_content_type "$FILE_PATH")
FILE_SIZE=$(wc -c < "$FILE_PATH" | tr -d ' ')

# --- Upload ---

npx wrangler r2 object put "${BUCKET}/${KEY}" \
  --file "$FILE_PATH" \
  --content-type "$CONTENT_TYPE" >/dev/null 2>&1

PUBLIC_URL="${PUBLIC_BASE_URL}/${KEY}"

# --- Clipboard ---

copy_to_clipboard() {
  if command -v pbcopy &>/dev/null; then
    echo -n "$1" | pbcopy
    return 0
  elif command -v xclip &>/dev/null; then
    echo -n "$1" | xclip -selection clipboard
    return 0
  elif command -v xsel &>/dev/null; then
    echo -n "$1" | xsel --clipboard --input
    return 0
  fi
  return 1
}

CLIPBOARD_OK="false"
if copy_to_clipboard "$PUBLIC_URL"; then
  CLIPBOARD_OK="true"
fi

# --- History ---

PUBLISHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ABS_PATH=$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")

ENTRY=$(python3 -c "
import json, sys
print(json.dumps({
    'key': sys.argv[1],
    'localPath': sys.argv[2],
    'url': sys.argv[3],
    'contentType': sys.argv[4],
    'size': int(sys.argv[5]),
    'publishedAt': sys.argv[6]
}))
" "$KEY" "$ABS_PATH" "$PUBLIC_URL" "$CONTENT_TYPE" "$FILE_SIZE" "$PUBLISHED_AT")

if [[ -f "$HISTORY_FILE" ]]; then
  python3 -c "
import json, sys
entry = json.loads(sys.argv[1])
with open(sys.argv[2], 'r') as f:
    history = json.load(f)
history.append(entry)
with open(sys.argv[2], 'w') as f:
    json.dump(history, f, indent=2)
" "$ENTRY" "$HISTORY_FILE"
else
  python3 -c "
import json, sys
entry = json.loads(sys.argv[1])
with open(sys.argv[2], 'w') as f:
    json.dump([entry], f, indent=2)
" "$ENTRY" "$HISTORY_FILE"
fi

# --- Output ---

python3 -c "
import json, sys
print(json.dumps({
    'url': sys.argv[1],
    'key': sys.argv[2],
    'contentType': sys.argv[3],
    'size': int(sys.argv[4]),
    'publishedAt': sys.argv[5],
    'clipboard': sys.argv[6] == 'true'
}, indent=2))
" "$PUBLIC_URL" "$KEY" "$CONTENT_TYPE" "$FILE_SIZE" "$PUBLISHED_AT" "$CLIPBOARD_OK"
