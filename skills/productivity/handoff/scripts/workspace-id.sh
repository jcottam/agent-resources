#!/usr/bin/env bash
set -euo pipefail

# Resolves stable workspace identity for handoff files.
# Outputs a single JSON object to stdout.
#
# Usage:
#   workspace-id.sh              # use current directory (or git root)
#   workspace-id.sh /path/to/dir # resolve from explicit path

abspath() {
  local dir="$1"
  if dir=$(cd "$dir" && pwd -P 2>/dev/null); then
    printf '%s' "$dir"
  else
    cd "$dir" && pwd
  fi
}

TARGET=$(abspath "${1:-.}")

WORKSPACE_PATH="$TARGET"
if git -C "$TARGET" rev-parse --is-inside-work-tree &>/dev/null; then
  WORKSPACE_PATH=$(abspath "$(git -C "$TARGET" rev-parse --show-toplevel)")
fi

BASENAME=$(basename "$WORKSPACE_PATH")

if command -v shasum &>/dev/null; then
  HASH=$(printf '%s' "$WORKSPACE_PATH" | shasum -a 256 | awk '{print $1}' | cut -c1-12)
elif command -v openssl &>/dev/null; then
  HASH=$(printf '%s' "$WORKSPACE_PATH" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-12)
else
  echo '{"error":"shasum or openssl required to compute workspace_id"}' >&2
  exit 1
fi

WORKSPACE_ID="${BASENAME}-${HASH}"

GIT_HEAD=""
if git -C "$WORKSPACE_PATH" rev-parse HEAD &>/dev/null; then
  GIT_HEAD=$(git -C "$WORKSPACE_PATH" rev-parse HEAD)
fi

export WORKSPACE_PATH WORKSPACE_ID GIT_HEAD
python3 - <<'PY'
import json, os

git_head = os.environ.get("GIT_HEAD") or None
if git_head == "":
    git_head = None

print(json.dumps({
    "workspace_path": os.environ["WORKSPACE_PATH"],
    "workspace_id": os.environ["WORKSPACE_ID"],
    "git_head": git_head,
}, indent=2))
PY
