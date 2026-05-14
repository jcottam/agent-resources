#!/usr/bin/env bash
set -euo pipefail

# Back-fills the PR metadata into the newest CHANGELOG.json entry, amends the
# last commit, and force-pushes.
#
# Usage:  backfill-pr.sh
#
# Reads PR info from `gh pr view HEAD` — must be run after the PR is created
# and the changelog commit is HEAD.

CHANGELOG="CHANGELOG.json"

if [[ ! -f "$CHANGELOG" ]]; then
  echo '{"error": "CHANGELOG.json not found"}' >&2
  exit 1
fi

# --- fetch PR metadata --------------------------------------------------------

PR_DATA=$(gh pr view HEAD --json number,title,url 2>/dev/null || echo "")

if [[ -z "$PR_DATA" ]]; then
  echo '{"error": "No PR found for HEAD"}' >&2
  exit 1
fi

PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number')
PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_URL=$(echo "$PR_DATA" | jq -r '.url')

# --- patch CHANGELOG.json ----------------------------------------------------

node -e "
  const fs = require('fs');
  const cl = JSON.parse(fs.readFileSync('$CHANGELOG', 'utf8'));
  if (cl.length === 0) {
    console.error('CHANGELOG.json is empty');
    process.exit(1);
  }
  cl[0].pr = {
    number: $PR_NUMBER,
    title: $(echo "$PR_TITLE" | jq -R '.'),
    url: $(echo "$PR_URL" | jq -R '.')
  };
  fs.writeFileSync('$CHANGELOG', JSON.stringify(cl, null, 2) + '\n');
"

# --- amend + push -------------------------------------------------------------

git add "$CHANGELOG"
git commit --amend --no-edit
git push --force-with-lease

# --- output -------------------------------------------------------------------

jq -n \
  --argjson number "$PR_NUMBER" \
  --arg title "$PR_TITLE" \
  --arg url "$PR_URL" \
  '{ backfilled: true, pr: { number: $number, title: $title, url: $url } }'
