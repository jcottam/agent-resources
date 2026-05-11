---
name: ship
description: >-
  Validate a branch, run quality gates, update documentation and changelog, and
  open a pull request. Use when the user says "ship", "ship this", "open a PR",
  "prepare a PR", "send this for review", "let's ship it", or any variation of
  wanting to finalize work and create a pull request.
---

# Ship

Pre-flight checklist that validates the branch, runs quality gates, updates documentation and changelog, and opens a pull request.

## Step 1 — Git health check

1. Determine the default branch (`main`, `master`, or whatever `git symbolic-ref refs/remotes/origin/HEAD` resolves to).
2. Run `git status`. If there are uncommitted changes, stop and ask the user to commit or stash them before continuing.
3. If the current branch is the default branch, create a new branch:
   - Analyze the committed changes to determine the type of work.
   - Pick the appropriate prefix from the table below.
   - Generate a short, descriptive slug from the changes (e.g. `feature/add-team-cadence-grid`).
   - Run `git checkout -b <prefix>/<slug>`.

   **Branch prefixes:**

   | Prefix | Use when |
   |--------|----------|
   | `feature/` | New functionality or capabilities |
   | `fix/` | Bug fixes |
   | `chore/` | Maintenance, dependency updates, config changes |
   | `refactor/` | Code restructuring with no behavior change |
   | `docs/` | Documentation-only changes |
   | `test/` | Adding or updating tests with no production code changes |
   | `perf/` | Performance improvements |

4. Run `git log <default-branch>..HEAD --oneline` to build a summary of what will be in the PR. If there are no commits ahead of the default branch, stop — there is nothing to ship.

## Step 2 — Sync with upstream

Rebase the branch on the latest default branch to avoid merge conflicts and stale CI failures:

1. `git fetch origin <default-branch>`.
2. `git rebase origin/<default-branch>`.
3. If the rebase has conflicts, stop and report them to the user with the conflicting files listed. Do not attempt to resolve merge conflicts automatically.

## Step 3 — Quality gates

Detect which gates exist in the project, then run only those that are present. Run them sequentially so earlier fixes (e.g. lint auto-fix) benefit later steps.

**Detection rules:**

| Gate | Present when | Command |
|------|-------------|---------|
| Lint | A `lint` script exists in `package.json`, or a linter config file exists at the repo root (ESLint, Biome, oxlint) | `<pm> lint` (prefer the `lint` script; fall back to `<pm> exec eslint .` if only a config file exists) |
| Type check | `tsconfig.json` exists at the repo root | Prefer a `typecheck`, `check-types`, or `type-check` script in `package.json` if one exists; otherwise `<pm> exec tsc --noEmit` |
| Tests | A `test` script exists in `package.json` | `<pm> test` |
| Build | A `build` script exists in `package.json` | `<pm> build` |

`<pm>` is the project's package manager. Detect it from the lock file: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun, otherwise npm.

**Execution rules:**

- Run each detected gate in order: lint → type check → tests → build.
- On failure, attempt to fix the issues and re-run the failing gate.
- If a fix requires user input or judgment, stop and report the failure with context.
- If no gates are detected at all, skip this step and note it in the final report.

## Step 4 — Documentation

Review the changes on the branch (`git diff <default-branch>..HEAD`) and update project documentation to reflect anything new, changed, or removed. Follow the `/technical-writer` skill for writing style and structure.

**Files to check:**

| File | Update when |
|------|-------------|
| `README.md` | New features, changed setup steps, new scripts, new environment variables, updated project structure, or modified user-facing behavior |
| `AGENTS.md` | New or changed conventions, module exports, component APIs, architectural patterns, data flows, or anything an AI agent needs to know when working in the codebase |

**Rules:**

- Read each file first to understand its current structure and voice.
- Only update sections that are affected by the changes on the branch. Do not rewrite unrelated content.
- Match the existing heading hierarchy, formatting, and level of detail.
- Use active voice and present tense. Keep sentences under 25 words.
- Lead with what the user or developer gains, not how the implementation works.
- Include practical examples (commands, config snippets, code) for any new capability.
- Use `code formatting` for commands, variables, and filenames. Use **bold** for UI elements.
- If neither file needs changes (e.g. a pure refactor with no public-facing impact), skip this step.
- Commit documentation updates to the current branch before proceeding.

## Step 5 — Changelog

Write a structured changelog entry to `CHANGELOG.json` at the project root.

**If `CHANGELOG.json` does not exist**, create it with an empty array `[]` first.

The file is a JSON array of release entry objects, newest first. Prepend the new entry at index 0.

**Entry schema:**

```json
{
  "version": "0.2.0",
  "date": "2026-05-10",
  "pr": {
    "number": 42,
    "title": "Add team cadence grid",
    "url": "https://github.com/org/repo/pull/42"
  },
  "changes": {
    "features": ["Added team cadence heatmap grid to the dashboard"],
    "improvements": ["Improved date picker responsiveness on mobile"],
    "fixes": ["Fixed off-by-one error in weekly rollup"]
  }
}
```

**Field rules:**

- **version** — Read the latest `version` string from the array (or `"0.0.0"` if the array is empty). Bump semantically: patch (`0.0.X`) for fixes only, minor (`0.X.0`) for features or improvements, major (`X.0.0`) for breaking changes.
- **date** — Today's date in `YYYY-MM-DD` format.
- **pr** — Set to `null` initially. Back-filled with the real PR number, title, and URL after Step 6 creates the PR.
- **changes** — Run `git log <default-branch>..HEAD` and categorize each commit into the five buckets: `features`, `improvements`, `fixes`, `breaking`, `internal`. Only include categories that have entries; omit empty arrays.

**Writing changelog descriptions:**

Transform raw commit messages into user-friendly language. The goal is descriptions a non-technical stakeholder can understand.

- Lead with the user-visible outcome, not the implementation detail.
- Use past tense ("Added", "Fixed", "Improved").
- Strip commit prefixes (`fix:`, `feat:`, `chore:`) — they are for categorization, not display.
- Merge related commits into a single description when they represent one logical change.
- Filter noise: exclude commits that are purely internal (dependency bumps, CI config, test-only changes) unless they are the *only* changes on the branch — in that case, categorize them under `internal`.

| Commit message | Changelog description |
|---|---|
| `fix: off-by-one in weekly rollup calc` | Fixed off-by-one error in weekly rollup |
| `feat(dashboard): add cadence heatmap grid` | Added team cadence heatmap grid to the dashboard |
| `refactor: extract date utils to shared module` | *(internal)* Refactored date utilities into a shared module |
| `perf: memoize contributor sort` | Improved contributor table rendering performance |
| `fix: tooltip flickers on hover in Safari` | Fixed tooltip flickering on hover in Safari |

## Step 6 — Open the PR

1. Check if a PR already exists for this branch: `gh pr view HEAD --json url 2>/dev/null`. If one exists, skip to sub-step 4 to update it instead of creating a new one.
2. `git add CHANGELOG.json && git commit -m "chore: add changelog entry"` — the `pr` field is `null` at this point.
3. `git push -u origin HEAD`.
4. Create or update the PR:
   - **New PR**: `gh pr create` with a title and body derived from the commit log.
   - **Existing PR**: `gh pr edit` to update the title and body if the changelog or commits have changed. Push any new commits.
   - **Title**: a concise summary of the branch's changes.
   - **Body**: a `## Summary` section with 1-3 bullet points describing the changes, and a `## Test plan` section with a checklist of verification steps.
5. Back-fill the `pr` object in `CHANGELOG.json` with the number, title, and URL from `gh pr view HEAD --json number,title,url`.
6. Amend the changelog commit: `git add CHANGELOG.json && git commit --amend --no-edit`.
7. Force-push: `git push --force-with-lease`.

## Step 7 — Post-flight report

Print a short summary:

- Branch name (and whether it was auto-created)
- PR URL (and whether it was created or updated)
- Quality gates: which ran and their result (pass / skipped / fixed)
- Changelog version bump (e.g. `0.1.0 → 0.2.0`)
- Any warnings encountered during the run
