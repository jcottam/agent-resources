#!/usr/bin/env bash
set -euo pipefail

# Back-fills the PR metadata into the changelog file, creates a new commit,
# and pushes.
#
# Usage:  backfill-pr.sh
#
# Reads PR info from GitHub (primary) or Azure DevOps (secondary) for the
# current branch. Run after the PR is created. Supports CHANGELOG.json and
# CHANGELOG.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/pr.sh
source "$SCRIPT_DIR/lib/pr.sh"

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
  echo '{"error": "No active PR found for current branch (checked GitHub and Azure DevOps)"}' >&2
  exit 1
fi

PR_ID=$(echo "$PR_DATA" | jq -r '.id')
PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number')
PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_URL=$(echo "$PR_DATA" | jq -r '.url')
PR_PROVIDER=$(echo "$PR_DATA" | jq -r '.provider')

if [[ -z "$PR_URL" || "$PR_URL" == "null" ]]; then
  echo '{"error": "PR found but web URL is missing — confirm gh/az auth for the detected provider"}' >&2
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
      provider: $(echo "$PR_PROVIDER" | jq -R '.'),
      id: $PR_ID,
      number: $PR_NUMBER,
      title: $(echo "$PR_TITLE" | jq -R '.'),
      url: $(echo "$PR_URL" | jq -R '.')
    };
    fs.writeFileSync('$CHANGELOG', JSON.stringify(cl, null, 2) + '\n');
  "
else
  node -e "
    const fs = require('fs');
    let md = fs.readFileSync('$CHANGELOG', 'utf8');
    const prLink = '([#$PR_NUMBER]($PR_URL))';
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
  --arg provider "$PR_PROVIDER" \
  --argjson id "$PR_ID" \
  --argjson number "$PR_NUMBER" \
  --arg title "$PR_TITLE" \
  --arg url "$PR_URL" \
  '{ backfilled: true, pr: { provider: $provider, id: $id, number: $number, title: $title, url: $url } }'
