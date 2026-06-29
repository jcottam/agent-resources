#!/usr/bin/env bash
# Shared PR helpers for ship scripts. GitHub is primary; Azure DevOps is secondary.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/pr.sh"
#   detect_pr_provider
#   fetch_pr_json_for_branch "$branch"

fetch_github_pr_for_branch() {
  local branch="$1"

  if ! command -v gh >/dev/null 2>&1; then
    echo "null"
    return 0
  fi

  local raw
  raw=$(gh pr view "$branch" --json url,number,title 2>/dev/null \
    || gh pr view --json url,number,title 2>/dev/null \
    || echo "")

  if [[ -z "$raw" ]]; then
    echo "null"
    return 0
  fi

  echo "$raw" | jq '{
    provider: "github",
    id: .number,
    number: .number,
    title: .title,
    url: .url
  }'
}

fetch_azure_pr_for_branch() {
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
        provider: "azure",
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

detect_pr_provider() {
  local url
  url=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ "$url" =~ github\.com ]] || [[ "$url" =~ git@github: ]]; then
    echo "github"
  elif [[ "$url" =~ dev\.azure\.com ]] || [[ "$url" =~ visualstudio\.com ]] || [[ "$url" =~ ssh\.dev\.azure\.com ]] || [[ "$url" =~ vs-ssh\.visualstudio\.com ]]; then
    echo "azure"
  else
    echo "unknown"
  fi
}

fetch_pr_json_for_branch() {
  local branch="$1"
  local provider
  provider=$(detect_pr_provider)

  local result="null"

  case "$provider" in
    github)
      result=$(fetch_github_pr_for_branch "$branch")
      ;;
    azure)
      result=$(fetch_azure_pr_for_branch "$branch")
      ;;
    unknown)
      result=$(fetch_github_pr_for_branch "$branch")
      if [[ "$result" == "null" ]]; then
        result=$(fetch_azure_pr_for_branch "$branch")
      fi
      ;;
  esac

  echo "$result"
}

resolve_pr_provider_for_repo() {
  local provider
  provider=$(detect_pr_provider)

  if [[ "$provider" != "unknown" ]]; then
    echo "$provider"
    return 0
  fi

  local branch="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}"
  local pr
  pr=$(fetch_github_pr_for_branch "$branch")
  if [[ "$pr" != "null" ]]; then
    echo "github"
    return 0
  fi

  pr=$(fetch_azure_pr_for_branch "$branch")
  if [[ "$pr" != "null" ]]; then
    echo "azure"
    return 0
  fi

  echo "github"
}
