---
name: babysit-pr
description: >-
  Babysit Bugbot on the current branch's pull request. Wait for its review, fix
  each valid finding, commit, and push. Repeat for up to three rounds, or until
  Bugbot has no new findings. Use when the user says "babysit PR", "babysit this
  PR", "wait for Bugbot", "address Bugbot comments", "loop until Bugbot is
  clean", or wants Bugbot findings on an open PR fixed without merging.
license: MIT
metadata:
  author: jcottam
  version: "1.1.0"
---

# Babysit PR

Babysit Bugbot on the current branch's pull request. Wait for its review, fix
each valid finding, commit, and push. Repeat for up to three rounds, or until
Bugbot has no new findings.

Do not use this skill to open a PR (`/ship`), write a human review (`/review-pr`),
or squash history (`/squash-branch`). Use it only after a non-draft PR exists and
the job is to loop on Bugbot. Do not merge.

## 1. Find the PR

- Use the PR the user named. Otherwise, find the open PR for the current
  branch.
- Find the host with `git remote -v`:
  - **Azure DevOps** (`dev.azure.com`): find the PR with
    `az repos pr list --source-branch <branch>`. Read threads through the
    `ado` MCP server or
    `az devops invoke --area git --resource pullRequestThreads ...`. Never
    use `gh`.
  - **GitHub**: use `gh pr view`, and `gh api` for review comments.
  - **Cursor Origin**: use the `cursor-origin` tools.
- If the repo has a `ship` skill (for example `.agents/skills/ship/SKILL.md`),
  follow its "After review" section for thread replies and statuses.
- If there is no PR, or the PR is a draft, stop and tell the user. Bugbot
  doesn't review drafts.

## 2. Check the branch

- Check out the PR branch and run `git pull --ff-only`.
- If there are uncommitted changes you didn't make, stop and ask before
  touching them.

## 3. Wait for Bugbot

Bugbot reviews again after every push. Before triaging, make sure it has
finished reviewing the latest commit.

- If its check or review is still running, check again every 15 seconds.
  Use `AwaitShell` or a short sleep loop, not one long wait.
- Wait up to 15 minutes per round. If Bugbot still hasn't finished, stop and
  report that.
- Bugbot's comments come from an author named "Bugbot" or "Cursor" (on
  GitHub, `cursor[bot]`). Collect only its open threads. Skip threads that
  are resolved, fixed, or marked won't fix.

## 4. Triage each finding

Read the code each open thread points at, then pick one:

- **Valid:** fix it on the branch. Keep the fix small and in scope. If the
  finding is a real bug, add or update the nearest test.
- **Doesn't apply:** leave the code alone. Reply in the thread with the
  reason, citing the code, and mark it won't fix (`WontFix` on Azure DevOps).
- **Needs a product or scope decision:** don't guess. Leave the thread open,
  finish the other findings, and ask the user at the end of the round.

Never weaken tests, lint rules, or type safety to silence a finding.

## 5. Verify, commit, and push

- Run the smallest test that covers the change, then the repo's full check
  (for example `pnpm check`). Fix anything you broke. If the check fails for
  reasons unrelated to your change, don't push. Stop and report it.
- Commit once per round, with a message that names the fix. For example:
  `fix: address Bugbot findings (null guard in pause cascade)`. Follow the
  repo's commit conventions if it has any.
- If the branch is behind its base branch, rebase first and resolve conflicts
  on the branch.
- Push with `git push`. Use `git push --force-with-lease` only after a
  rebase. Never force-push `main`.

## 6. Update the threads

- In each thread you fixed, reply with what changed and the commit SHA, then
  resolve it (`Fixed` on Azure DevOps; "Resolve conversation" on GitHub).
- Leave human reviewers' threads alone unless the user asked otherwise. List
  them in the report.

## 7. Repeat

Go back to step 3 and wait for Bugbot to review the new push. Stop when any
of these happens:

- Bugbot's latest review has no new open findings.
- Three fix rounds have run. Bugbot can keep finding small nits, so let the
  user decide whether to continue.
- A finding needs the user's decision.
- Bugbot didn't finish within 15 minutes.
- The full check failed for reasons unrelated to your change.

## 8. Report

Tell the user, in plain prose:

- The PR link and branch.
- Each Bugbot finding and what happened to it: fixed in which commit, or
  declined and why.
- The checks you ran and their results.
- The commits you pushed.
- Anything still open: human reviewers' comments, findings waiting on a
  decision, or Bugbot not finishing.
