#!/usr/bin/env bash
set -euo pipefail

# Gathers git state needed by the ship skill: fetches the default branch,
# counts commits ahead, checks for an existing PR, and rebases (by default).
# Outputs a single JSON object to stdout.
#
# Usage:
#   preflight.sh              # health check + fetch + rebase (default)
#   preflight.sh --no-rebase  # health check + fetch only, skip rebase

REBASE=true
for arg in "$@"; do
  case "$arg" in
    --no-rebase) REBASE=false ;;
  esac
done

# --- default branch -----------------------------------------------------------

resolve_default_branch() {
  local ref
  ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
  if [[ -n "$ref" ]]; then
    echo "${ref#refs/remotes/origin/}"
    return
  fi
  for candidate in main master; do
    if git show-ref --verify --quiet "refs/remotes/origin/$candidate" 2>/dev/null; then
      echo "$candidate"
      return
    fi
  done
  echo "main"
}

DEFAULT_BRANCH=$(resolve_default_branch)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
ON_DEFAULT=$( [[ "$CURRENT_BRANCH" == "$DEFAULT_BRANCH" ]] && echo true || echo false )

# --- uncommitted changes ------------------------------------------------------

DIRTY_FILES=$(git status --porcelain)
if [[ -n "$DIRTY_FILES" ]]; then
  HAS_UNCOMMITTED=true
else
  HAS_UNCOMMITTED=false
fi

# --- fetch + rebase -----------------------------------------------------------

git fetch origin "$DEFAULT_BRANCH" --quiet

REBASE_STATUS="skipped"
CONFLICT_FILES="[]"

if [[ "$REBASE" == true ]]; then
  if git rebase "origin/$DEFAULT_BRANCH" --quiet 2>/dev/null; then
    REBASE_STATUS="clean"
  else
    REBASE_STATUS="conflicts"
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U | jq -R -s 'split("\n") | map(select(. != ""))')
    git rebase --abort 2>/dev/null || true
  fi
fi

# --- commits ahead (counted after fetch so the ref is current) ----------------

COMMITS_AHEAD=$(git rev-list --count "origin/$DEFAULT_BRANCH..HEAD" 2>/dev/null || echo 0)

COMMIT_LOG=""
if [[ "$COMMITS_AHEAD" -gt 0 ]]; then
  COMMIT_LOG=$(git log "origin/$DEFAULT_BRANCH..HEAD" --oneline)
fi

# --- existing PR --------------------------------------------------------------

PR_JSON=$(gh pr view --json url,number,title 2>/dev/null || echo "")
if [[ -n "$PR_JSON" ]]; then
  PR_EXISTS=true
else
  PR_EXISTS=false
  PR_JSON="null"
fi

# --- output -------------------------------------------------------------------

COMMIT_LOG_JSON=$(echo "$COMMIT_LOG" | jq -R -s '.')

cat <<ENDJSON
{
  "defaultBranch": "$DEFAULT_BRANCH",
  "currentBranch": "$CURRENT_BRANCH",
  "onDefaultBranch": $ON_DEFAULT,
  "uncommittedChanges": $HAS_UNCOMMITTED,
  "commitsAhead": $COMMITS_AHEAD,
  "commitLog": $COMMIT_LOG_JSON,
  "prExists": $PR_EXISTS,
  "pr": $PR_JSON,
  "rebaseStatus": "$REBASE_STATUS",
  "conflictFiles": $CONFLICT_FILES
}
ENDJSON
