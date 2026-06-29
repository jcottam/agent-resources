#!/usr/bin/env bash
# Shared Azure DevOps PR helpers for ship scripts.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/azure-pr.sh"
#   fetch_pr_json_for_branch "$branch"

fetch_pr_json_for_branch() {
  local branch="$1"

  if ! command -v az >/dev/null 2>&1; then
    echo "null"
    return 0
  fi

  local raw
  raw=$(az repos pr list \
    --source-branch "$branch" \
    --status active \
    --top 1 \
    --include-links \
    --detect true \
    -o json 2>/dev/null || echo "[]")

  if [[ -z "$raw" || "$raw" == "[]" || "$raw" == "null" ]]; then
    echo "null"
    return 0
  fi

  echo "$raw" | jq '
    if type == "array" and length > 0 then
      .[0] | {
        id: .pullRequestId,
        number: .pullRequestId,
        title: .title,
        url: (._links.web.href // empty)
      }
    else
      null
    end
  '
}
