#!/usr/bin/env bash
set -euo pipefail

# Detects the package manager and which quality gates are available in the
# current project.  Outputs a JSON object to stdout.
#
# Usage:  detect-gates.sh [project-root]
#   project-root defaults to the current working directory.

ROOT="${1:-.}"
PKG_JSON="$ROOT/package.json"

# --- check for package.json --------------------------------------------------

if [[ ! -f "$PKG_JSON" ]]; then
  jq -n '{ pm: null, gates: [], noPackageJson: true }'
  exit 0
fi

# --- package manager ----------------------------------------------------------

detect_pm() {
  [[ -f "$ROOT/pnpm-lock.yaml" ]]  && echo pnpm  && return
  [[ -f "$ROOT/yarn.lock" ]]       && echo yarn   && return
  [[ -f "$ROOT/bun.lockb" ]]       && echo bun    && return
  [[ -f "$ROOT/bun.lock" ]]        && echo bun    && return
  echo npm
}

PM=$(detect_pm)

# --- helpers ------------------------------------------------------------------

has_script() {
  local name="$1"
  node -e "
    const pkg = require(process.argv[1]);
    process.exit(pkg.scripts && pkg.scripts['$name'] ? 0 : 1);
  " "$PKG_JSON" 2>/dev/null
}

has_file() {
  local pattern="$1"
  compgen -G "$ROOT/$pattern" > /dev/null 2>&1
}

pm_run() {
  local script="$1"
  if [[ "$PM" == "npm" ]]; then
    echo "npm run $script"
  else
    echo "$PM $script"
  fi
}

pm_test() {
  if [[ "$PM" == "npm" ]]; then
    echo "npm test"
  else
    echo "$PM test"
  fi
}

pm_exec() {
  echo "$PM exec $*"
}

# --- gate detection -----------------------------------------------------------

GATES="[]"

add_gate() {
  local name="$1" command="$2"
  GATES=$(echo "$GATES" | jq --arg n "$name" --arg c "$command" '. + [{"name": $n, "command": $c}]')
}

# Lint
if has_script lint; then
  add_gate lint "$(pm_run lint)"
elif has_file ".eslintrc*" || has_file "eslint.config.*" || has_file "biome.json" || has_file "biome.jsonc" || has_file ".oxlintrc*"; then
  if has_file ".eslintrc*" || has_file "eslint.config.*"; then
    add_gate lint "$(pm_exec eslint .)"
  elif has_file "biome.json" || has_file "biome.jsonc"; then
    add_gate lint "$(pm_exec biome check .)"
  elif has_file ".oxlintrc*"; then
    add_gate lint "$(pm_exec oxlint .)"
  fi
fi

# Type check
if has_script typecheck; then
  add_gate typecheck "$(pm_run typecheck)"
elif has_script check-types; then
  add_gate typecheck "$(pm_run check-types)"
elif has_script type-check; then
  add_gate typecheck "$(pm_run type-check)"
elif [[ -f "$ROOT/tsconfig.json" ]]; then
  add_gate typecheck "$(pm_exec tsc --noEmit)"
fi

# Tests
if has_script test; then
  add_gate test "$(pm_test)"
fi

# Build
if has_script build; then
  add_gate build "$(pm_run build)"
fi

# --- output -------------------------------------------------------------------

jq -n --arg pm "$PM" --argjson gates "$GATES" '{ pm: $pm, gates: $gates }'
