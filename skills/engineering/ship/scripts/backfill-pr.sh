#!/usr/bin/env bash
set -euo pipefail

# Back-fills the PR metadata into the changelog file, creates a new commit,
# and pushes.
#
# Usage:  backfill-pr.sh
#
# Reads PR info from Azure DevOps for the current branch — run after the PR
# is created. Supports both CHANGELOG.json and CHANGELOG.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/azure-pr.sh
source "$SCRIPT_DIR/lib/azure-pr.sh"

# --- detect changelog format --------------------------------------------------

if [[ -f "CHANGELOG.json" ]]; then
  CHANGELOG="CHANGELOG.json"
  FORMAT="json"
elif [[ -f "CHANGELOG.md" ]]; then
  CHANGELOG="CHANGELOG.md"
  FORMAT="md"
else
  echo '{"error": "No CHANGELOG.json or CHANGELOG.md found"}' >&2
  exit 1
fi

# --- fetch PR metadata --------------------------------------------------------

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PR_DATA=$(fetch_pr_json_for_branch "$CURRENT_BRANCH")

if [[ "$PR_DATA" == "null" ]]; then
  echo '{"error": "No active Azure DevOps PR found for current branch"}' >&2
  exit 1
fi

PR_ID=$(echo "$PR_DATA" | jq -r '.id')
PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_URL=$(echo "$PR_DATA" | jq -r '.url')

if [[ -z "$PR_URL" || "$PR_URL" == "null" ]]; then
  echo '{"error": "PR found but web URL is missing — re-run with az authenticated and azure-devops extension installed"}' >&2
  exit 1
fi

# --- patch changelog ----------------------------------------------------------

if [[ "$FORMAT" == "json" ]]; then
  node -e "
    const fs = require('fs');
    const cl = JSON.parse(fs.readFileSync('$CHANGELOG', 'utf8'));
    if (cl.length === 0) {
      console.error('CHANGELOG.json is empty');
      process.exit(1);
    }
    cl[0].pr = {
      id: $PR_ID,
      number: $PR_ID,
      title: $(echo "$PR_TITLE" | jq -R '.'),
      url: $(echo "$PR_URL" | jq -R '.')
    };
    fs.writeFileSync('$CHANGELOG', JSON.stringify(cl, null, 2) + '\n');
  "
else
  node -e "
    const fs = require('fs');
    let md = fs.readFileSync('$CHANGELOG', 'utf8');
    const prLink = '([#$PR_ID]($PR_URL))';
    md = md.replace(/^(## \[[^\]]+\])/m, '\$1 ' + prLink);
    fs.writeFileSync('$CHANGELOG', md);
  "
fi

# --- commit + push ------------------------------------------------------------

git add "$CHANGELOG"
git commit -m "chore: backfill PR metadata"
git push

# --- output -------------------------------------------------------------------

jq -n \
  --argjson id "$PR_ID" \
  --arg title "$PR_TITLE" \
  --arg url "$PR_URL" \
  '{ backfilled: true, pr: { id: $id, number: $id, title: $title, url: $url } }'
