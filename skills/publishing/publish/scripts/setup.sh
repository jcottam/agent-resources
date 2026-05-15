#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$HOME/.publish.json"

echo "=== Publish Skill Setup ==="
echo ""

if [[ -f "$CONFIG_FILE" ]]; then
  echo "Existing config found at $CONFIG_FILE:"
  cat "$CONFIG_FILE"
  echo ""
  read -rp "Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
  fi
  echo ""
fi

# --- Bucket name ---

read -rp "R2 bucket name: " BUCKET
if [[ -z "$BUCKET" ]]; then
  echo "Error: bucket name is required" >&2
  exit 1
fi

# --- Public base URL ---

echo ""
echo "Enter the public base URL for your bucket."
echo "This is the URL prefix used to construct shareable links."
echo ""
echo "Examples:"
echo "  https://pub-abc123.r2.dev          (R2 public bucket URL)"
echo "  https://assets.yourdomain.com      (custom domain)"
echo ""

read -rp "Public base URL: " PUBLIC_BASE_URL
if [[ -z "$PUBLIC_BASE_URL" ]]; then
  echo "Error: public base URL is required" >&2
  exit 1
fi

# Strip trailing slash
PUBLIC_BASE_URL="${PUBLIC_BASE_URL%/}"

# --- Write config ---

python3 -c "
import json, sys
config = {
    'bucket': sys.argv[1],
    'publicBaseUrl': sys.argv[2]
}
with open(sys.argv[3], 'w') as f:
    json.dump(config, f, indent=2)
print()
print('Config written to ' + sys.argv[3])
" "$BUCKET" "$PUBLIC_BASE_URL" "$CONFIG_FILE"

echo ""

# --- Check wrangler auth ---

echo "Checking wrangler authentication..."
if npx wrangler whoami &>/dev/null 2>&1; then
  echo "Wrangler is authenticated."
else
  echo ""
  echo "Wrangler is not authenticated. You have two options:"
  echo ""
  echo "  1. Run: npx wrangler login"
  echo "     (Interactive OAuth -- opens your browser)"
  echo ""
  echo "  2. Set the CLOUDFLARE_API_TOKEN environment variable"
  echo "     (Create a token at https://dash.cloudflare.com/profile/api-tokens)"
  echo ""
fi

echo ""
echo "Setup complete. You can now use 'publish' to upload files."
