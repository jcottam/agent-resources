---
name: ship
description: >-
  Validate a branch, run quality gates, update documentation and changelog, and
  open a pull request. Designed for JavaScript/TypeScript projects; quality gate
  detection requires package.json. Use when the user says "ship", "ship this",
  "open a PR", "prepare a PR", "send this for review", "let's ship it", or any
  variation of wanting to finalize work and create a pull request.
license: MIT
metadata:
  author: jcottam
  version: "1.4.0"
---

# Ship

Pre-flight checklist that validates the branch, runs quality gates, updates documentation and changelog, and opens a pull request.

## Workflow overview

```
- [ ] Step 0: Verify CLI tools and Azure DevOps auth
- [ ] Step 1: Preflight (rebase, branch, existing PR)
- [ ] Step 2: Quality gates (lint → typecheck → test → build)
- [ ] Step 3: Documentation (README.md, AGENTS.md)
- [ ] Step 4: Changelog bump
- [ ] Step 5: Push and open or update PR
- [ ] Step 6: Post-flight report
```

## Script path placeholder

`$SCRIPTS` is a **placeholder** for the absolute path to the `scripts/` directory next to this file — not a predefined shell or PowerShell variable. Resolve it before running any command:

- **bash/zsh**: `SCRIPTS=/abs/path/to/scripts`
- **PowerShell**: `$SCRIPTS = 'C:\abs\path\to\scripts'`

## Running helper scripts (cross-platform)

The helper scripts (`preflight.sh`, `detect-gates.sh`, `changelog-bump.sh`, `backfill-pr.sh`) are bash and require `bash`, `jq`, `node`, `git`, and `az` on PATH. PR lookup uses `az repos pr list` with `--detect true` (organization, project, and repository are inferred from the git remote).

- **macOS / Linux**: run directly — e.g. `bash "$SCRIPTS/preflight.sh"`.
- **Windows (PowerShell)**: use **Git Bash**, not WSL `bash.exe` (which cannot see Windows-installed tools). Discover Git Bash from the git install, then invoke each script through it:

```powershell
$gitRoot = Split-Path (Split-Path (Get-Command git).Source)   # e.g. C:\Program Files\Git
$bash = Join-Path $gitRoot 'bin\bash.exe'
& $bash "$SCRIPTS/preflight.sh"   # repeat per script + args
```

If `bin\bash.exe` does not exist under the git root, stop and tell the user to install [Git for Windows](https://git-scm.com/downloads) (bundles Git Bash).

Throughout the steps below, every `$SCRIPTS/<name>.sh` reference means run that script using the OS-appropriate invocation above.

## Step 0 — Prerequisites

Verify that all required CLI tools are installed and authenticated before proceeding.

**Check tool availability:**

- **macOS / Linux (bash/zsh)**: `command -v git && command -v az && command -v jq && command -v node` — the `&&` chain fails on the first missing tool.
- **Windows (PowerShell)**: `'git','az','jq','node' | ForEach-Object { if (-not (Get-Command $_ -ErrorAction SilentlyContinue)) { "MISSING: $_" } }` — prints a line per missing tool (no output means all present).

If any tool is missing, stop and tell the user which tool(s) need to be installed.

| Tool | Purpose | Install hint |
| --- | --- | --- |
| `git` | Branch ops, commits, push | [git-scm.com/downloads](https://git-scm.com/downloads) (Windows build bundles Git Bash) |
| `az` | Azure DevOps PR create/list/update | macOS: `brew install azure-cli` · Windows: `winget install Microsoft.AzureCLI` · [aka.ms/azcli](https://aka.ms/azcli) |
| `jq` | JSON parsing in shell scripts | macOS: `brew install jq` · Windows: `winget install jqlang.jq` · [jqlang.github.io/jq](https://jqlang.github.io/jq) |
| `node` | Inline JS for changelog and gates | [nodejs.org](https://nodejs.org) · Windows: `winget install OpenJS.NodeJS` |

This skill uses **Azure DevOps** (`az repos`) for pull requests, not GitHub (`gh`). The `az repos` commands auto-detect organization, project, and repository from the git remote.

**Confirm Azure CLI auth:**

1. `az account show` — if this errors, stop and instruct the user to run `az login`.
2. `az extension show --name azure-devops` — if missing, instruct them to run `az extension add --name azure-devops`.

## Step 1 — Preflight

Run `$SCRIPTS/preflight.sh` and parse the JSON output. This fetches the default branch, rebases, checks for uncommitted changes, counts commits ahead, and detects an existing PR — all in one call.

- If `uncommittedChanges` is `true`, stop and ask the user to commit or stash.
- If `onDefaultBranch` is `true`, create a new branch:
  - Analyze the committed changes to determine the type of work.
  - Pick the appropriate prefix from the table below.
  - Generate a short, descriptive slug from the changes (e.g. `feature/add-team-cadence-grid`).
  - Run `git checkout -b <prefix>/<slug>`.
- If `rebaseStatus` is `"conflicts"`, stop and report the conflicting files from `conflictFiles`. Do not attempt to resolve merge conflicts automatically.
- If `rebaseStatus` is `"clean"`, proceed.
- If `commitsAhead` is `0`, stop — there is nothing to ship.

**Branch prefixes:**

| Prefix | Use when |
| --- | --- |
| `feature/` | New functionality or capabilities |
| `fix/` | Bug fixes |
| `chore/` | Maintenance, dependency updates, config changes |
| `refactor/` | Code restructuring with no behavior change |
| `docs/` | Documentation-only changes |
| `test/` | Adding or updating tests with no production code changes |
| `perf/` | Performance improvements |

## Step 2 — Quality gates

Run `$SCRIPTS/detect-gates.sh` and parse the JSON output. The `gates` array contains each detected gate's `name` and `command`.

- If `noPackageJson` is `true`, warn the user that no quality gates were detected because this does not appear to be a JavaScript/TypeScript project. Ask if they want to proceed without gates or provide manual commands to run.

**Execution rules:**

- Run each gate's `command` in order (the array is already sorted: lint → typecheck → test → build).
- On failure, attempt to fix the issues and re-run the failing gate.
- If a fix requires user input or judgment, stop and report the failure with context.
- If `gates` is empty, skip this step and note it in the final report.

## Step 3 — Documentation

Review the changes on the branch (`git diff <default-branch>..HEAD`) and update project documentation to reflect anything new, changed, or removed.

**Files to check:**

| File | Update when |
| --- | --- |
| `README.md` | New features, changed setup steps, new scripts, new environment variables, updated project structure, or modified user-facing behavior |
| `AGENTS.md` | New or changed conventions, module exports, component APIs, architectural patterns, data flows, or anything an AI agent needs to know when working in the codebase |

**Rules:**

- Read each file first to understand its current structure and voice.
- Only update sections affected by the branch changes. Do not rewrite unrelated content.
- Match the existing heading hierarchy, formatting, and level of detail.
- Write for a developer audience. Be direct and specific. Avoid marketing language.
- Use active voice and present tense. Keep sentences under 25 words.
- Lead with what the user or developer gains, not how the implementation works.
- Do not document internal implementation details, private functions, or architecture decisions that are only relevant to the current change — those belong in commit messages or PR descriptions, not README/AGENTS.
- Include practical examples (commands, config snippets, code) for any new capability.
- Use `code formatting` for commands, variables, and filenames. Use **bold** for UI elements.
- If neither file needs changes (e.g. a pure refactor with no public-facing impact), skip this step.
- Commit documentation updates to the current branch before proceeding.

## Step 4 — Changelog

Run `$SCRIPTS/changelog-bump.sh info` to get the current version and changelog format.

The script auto-detects the changelog format: it uses `CHANGELOG.json` if one exists, otherwise defaults to `CHANGELOG.md`. The `format` field in the output indicates which format is active.

**Decide the bump level** based on the changes:

- `patch` — fixes only
- `minor` — features or improvements
- `major` — breaking changes

Build a changes JSON object by analyzing `git log <default-branch>..HEAD`. Categorize each commit into: `features`, `improvements`, `fixes`, `breaking`, `internal`. Only include categories that have entries.

**Writing changelog descriptions:**

Transform raw commit messages into user-friendly language. The goal is descriptions that a non-technical stakeholder can understand.

- Lead with the user-visible outcome, not the implementation detail.
- Use past tense ("Added", "Fixed", "Improved").
- Strip commit prefixes (`fix:`, `feat:`, `chore:`) — they are for categorization, not display.
- Merge related commits into a single description when they represent one logical change.
- Filter noise: exclude commits that are purely internal (dependency bumps, CI config, test-only changes) unless they are the *only* changes on the branch — in that case, categorize them under `internal`.

| Commit message | Changelog description |
| --- | --- |
| `fix: off-by-one in weekly rollup calc` | Fixed off-by-one error in weekly rollup |
| `feat(dashboard): add cadence heatmap grid` | Added team cadence heatmap grid to the dashboard |
| `refactor: extract date utils to shared module` | *(internal)* Refactored date utilities into a shared module |
| `perf: memoize contributor sort` | Improved contributor table rendering performance |
| `fix: tooltip flickers on hover in Safari` | Fixed tooltip flickering on hover in Safari |

Then run (using the OS-appropriate script invocation from [Running helper scripts](#running-helper-scripts-cross-platform)):

```bash
$SCRIPTS/changelog-bump.sh bump <level> '<changes-json>'
```

The `<changes-json>` argument contains double quotes and spaces, which need care:

- **macOS / Linux**: wrap it in single quotes — e.g. `... bump minor '{"features":["Added X"]}'`.
- **Windows (PowerShell)**: do **not** pass the JSON as a direct argument. Windows PowerShell 5.1 strips embedded double quotes when invoking native executables, corrupting the JSON. Pass it via an environment variable and keep all bash quoting inside a temp script file:

```powershell
# $bash is the Git Bash path from discovery above; re-derive it if not set in this session.
$env:SHIP_CHANGES = $changesJson
$env:SHIP_SCRIPT  = "$SCRIPTS/changelog-bump.sh"
$tmp = Join-Path $env:TEMP 'ship-bump.sh'
Set-Content $tmp 'bash "$(cygpath -u "$SHIP_SCRIPT")" bump "$1" "$SHIP_CHANGES"' -Encoding ascii -NoNewline
& $bash $tmp patch   # use patch, minor, or major
Remove-Item $tmp; Remove-Item Env:\SHIP_CHANGES, Env:\SHIP_SCRIPT
```

This delivers the JSON intact even with spaces, commas, and apostrophes. `cygpath -u` (shipped with Git Bash) normalizes the Windows path for bash, and `-NoNewline` avoids a trailing CRLF that some Git Bash builds would append to the last argument.

If the script output has `"updated": true`, it patched an existing draft entry (from a previous interrupted run) instead of creating a new one.

**Amend the changelog** into the last work commit so it does not create extra commits. The stderr redirect is shell-specific:

- **macOS / Linux (bash/zsh)**: `git add CHANGELOG.json CHANGELOG.md 2>/dev/null; git commit --amend --no-edit`
- **Windows (PowerShell)**: `git add CHANGELOG.json CHANGELOG.md 2>$null; git commit --amend --no-edit`

The redirect suppresses the "pathspec did not match" warning when only one changelog file exists; the amend still succeeds either way.

## Step 5 — Open the PR

Use the `prExists` and `pr` fields from the Step 1 preflight output to decide whether to create or update. The `pr` object has `id` (Azure DevOps pull request ID), `title`, and `url` fields.

1. `git push -u origin HEAD`.
2. Create or update the PR:
   - **New PR**: `az repos pr create` with a title and description derived from the commit log.
   - **Existing PR**: `az repos pr update --id <pr.id>` to update the title and description if the changelog or commits have changed.
   - **Title**: a concise summary of the branch's changes.
   - **Description**: a `## Summary` section with 1–3 bullet points, and a `## Test plan` section with a verification checklist. The `--description` flag accepts multiple arguments — each becomes a separate line. Pass the markdown body as a sequence of quoted line strings:

```bash
az repos pr create \
  --source-branch feature/my-change \
  --target-branch main \
  --title "Add team cadence heatmap grid" \
  --description "## Summary" \
  --description "- Added heatmap grid to the dashboard" \
  --description "- Updated README with setup notes" \
  --description "" \
  --description "## Test plan" \
  --description "- [ ] Verify grid renders with sample data" \
  --description "- [ ] Confirm mobile layout"
```

> **Optional:** Run `$SCRIPTS/backfill-pr.sh` after creating the PR to add a PR link to the changelog entry. This is not run by default — use it if your team wants PR traceability in the changelog.

## Step 6 — Post-flight report

Print a short summary:

- Branch name (and whether it was auto-created)
- PR URL (and whether it was created or updated)
- Quality gates: which ran and their result (pass / skipped / fixed)
- Changelog version bump (e.g. `0.1.0 → 0.2.0`)
- Any warnings encountered during the run
