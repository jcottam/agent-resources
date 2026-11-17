---
name: babysit-pr
description: >-
  Babysit Bugbot on the current branch's pull request: wait for its review, fix
  every valid finding, commit, push, and repeat until Bugbot has nothing left to
  say. Use when the user says "babysit PR", "babysit this PR", "wait for Bugbot",
  "address Bugbot comments", "loop until Bugbot is clean", or wants Bugbot
  findings on an open PR fixed without merging.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Babysit PR

Babysit Bugbot on the current branch's pull request: wait for its review, fix
every valid finding, commit, push, and repeat until Bugbot has nothing left to
say.

Do not use this skill to open a PR (`/ship`), write a human review (`/review-pr`),
or squash history (`/squash-branch`). Use it only after a non-draft PR exists and
the job is to loop on Bugbot until it is clean. Do not merge.

## 1. Find the PR

- Use the PR the user named. Otherwise find the open PR for the current branch.
- Work out the host from `git remote -v`:
  - **Azure DevOps** (`dev.azure.com`): use `az repos pr list --source-branch <branch>`
    and read threads through the `ado` MCP server or
    `az devops invoke --area git --resource pullRequestThreads ...`. Never use `gh`.
  - **GitHub**: use `gh pr view` and `gh api` for review comments.
  - **Cursor Origin**: use the `cursor-origin` tools.
- If the repo has a `ship` skill (for example `.agents/skills/ship/SKILL.md`),
  read its "After review" section and follow it for thread replies and status.
- If there is no PR, or it is a draft (Bugbot skips drafts), stop and tell the user.

## 2. Make sure the branch is clean

- Check out the PR branch and `git pull --ff-only`.
- If there are uncommitted changes you didn't make, stop and ask before touching them.

## 3. Wait for Bugbot

- Bugbot reviews after each push. If its check or review for the latest
  commit is still running, poll every 15 seconds (use `AwaitShell` or a
  short sleep loop, not one long wait). Keep polling for up to 15 minutes, then give up and
  report that Bugbot never finished.
- Bugbot's comments come from an author whose name contains "Bugbot" or
  "Cursor" (on GitHub, `cursor[bot]`). Only collect **active / unresolved**
  threads. Ignore threads already resolved, fixed, or marked won't fix.

## 4. Triage each finding

For each open Bugbot thread, read the code it points at and decide:

- **Valid:** fix it on the branch. Keep the fix small and in scope. Add or
  update the nearest test when the finding is a real bug.
- **Not valid / doesn't apply:** don't change code. Reply in the thread with
  the reason, citing the code, and mark it won't fix.
- **Needs a product or scope decision:** stop and ask the user. Don't guess.

Never weaken tests, lint rules, or type safety just to silence a finding.

## 5. Verify, commit, push

- Run the smallest check that covers the change, then the repo's full gate
  before pushing (for example `pnpm check`). Fix anything you broke.
- Commit with a message that says what was fixed, e.g.
  `fix: address Bugbot findings (null guard in pause cascade)`. One commit per
  round is fine. Follow the repo's commit conventions if it has any.
- If the branch is behind the base branch, rebase onto it first and resolve
  conflicts on the branch. Push with `git push`, or
  `git push --force-with-lease` only after a rebase. Never force-push `main`.

## 6. Close the loop on the PR

- Reply in each thread you fixed with what changed and the commit SHA, then
  resolve it (Azure DevOps: status `Fixed`; GitHub: resolve the conversation).
- Don't touch threads from human reviewers unless the user asked. List them
  in the report instead.

## 7. Repeat

Go back to step 3 and wait for Bugbot to review the new push. Stop when any
of these is true:

- Bugbot's latest review has no new open findings.
- Three fix rounds have run (Bugbot may keep finding nits; report and let the
  user decide).
- A finding needs the user's decision.

## 8. Report

Tell the user, in plain prose:

- The PR link and branch.
- Each Bugbot finding and what happened to it (fixed in which commit, or
  declined and why).
- Checks run and their results.
- Commits pushed.
- Anything still open: unresolved human comments, findings waiting on a
  decision, or Bugbot not finishing.
