---
name: babysit-pr
description: >-
  Babysit review comments on the current branch's pull request. Bugbot comes
  first: wait for its review, fix each valid finding, commit, and push. Handle
  every other open comment too, from human reviewers and other bots. Repeat for
  up to three rounds, or until nothing new is open. Use when the user says
  "babysit PR", "babysit this PR", "wait for Bugbot", "address review comments",
  "address Bugbot comments", "loop until Bugbot is clean", or wants open PR
  feedback fixed without merging.
license: MIT
metadata:
  author: jcottam
  version: "1.2.0"
---

# Babysit PR

Babysit review comments on the current branch's pull request. Bugbot comes
first: wait for its review, fix each valid finding, commit, and push. Handle
every other open comment too, from human reviewers and other bots. Repeat for
up to three rounds, or until nothing new is open.

Do not use this skill to open a PR (`/ship`), write a human review (`/review-pr`),
or squash history (`/squash-branch`). Use it only after a non-draft PR exists and
the job is to loop on review comments. Do not merge.

## 1. Find the PR

- Use the PR the user named. Otherwise, find the open PR for the current
  branch.
- Find the host with `git remote -v`:
  - **Azure DevOps** (`dev.azure.com`): find the PR with
    `az repos pr list --source-branch <branch>`. Read threads through the
    `ado` MCP server or
    `az devops invoke --area git --resource pullRequestThreads ...`. Never
    use `gh`.
  - **GitHub**: use `gh pr view`, and `gh api` for review comments, review
    bodies, and issue (top-level) comments.
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
- Wait up to 15 minutes per round. If Bugbot still hasn't finished, triage
  the other comments anyway, then stop and report that Bugbot didn't finish.
- Bugbot's comments come from an author named "Bugbot" or "Cursor" (on
  GitHub, `cursor[bot]`).

## 4. Collect every open comment

Gather all open feedback on the PR, not just Bugbot's:

- Inline code threads, top-level PR comments, and review summaries (for
  example a GitHub "Request changes" review body).
- Skip threads that are resolved, fixed, closed, or marked won't fix.
- Skip system threads (votes, pushes, status updates, Azure DevOps threads
  with `commentType: system`) and threads where the last reply is yours or
  the user's and nobody has responded since.
- Group what's left by author: **Bugbot**, **human reviewers**, and **other
  bots** (linters, coverage, security scanners, deploy previews).

Triage in that order: Bugbot first, then human reviewers, then other bots.

## 5. Triage each comment

Read the code each thread points at, then pick one.

For **Bugbot and other bots**:

- **Valid:** fix it on the branch. Keep the fix small and in scope. If the
  finding is a real bug, add or update the nearest test.
- **Doesn't apply:** leave the code alone. Reply in the thread with the
  reason, citing the code, and mark it won't fix (`WontFix` on Azure DevOps).
- **Needs a product or scope decision:** don't guess. Leave the thread open,
  finish the others, and ask the user at the end of the round.
- Informational bot posts (preview links, coverage summaries with no ask)
  need no action.

For **human reviewers**:

- **Clear, in-scope change request:** fix it, the same way as a Bugbot
  finding.
- **Question:** answer it in the thread, citing the code. Don't change code
  unless the answer reveals a bug.
- **You disagree, or it's out of scope, a design call, or ambiguous:** don't
  reply or decline on the user's behalf. Leave it open and ask the user at
  the end of the round.
- Never mark a human's thread won't fix yourself.

Never weaken tests, lint rules, or type safety to silence a comment.

## 6. Verify, commit, and push

- Run the smallest test that covers the change, then the repo's full check
  (for example `pnpm check`). Fix anything you broke. If the check fails for
  reasons unrelated to your change, don't push. Stop and report it.
- Commit once per round, with a message that names the fixes. For example:
  `fix: address review feedback (null guard in pause cascade)`. Follow the
  repo's commit conventions if it has any.
- If the branch is behind its base branch, rebase first and resolve conflicts
  on the branch.
- Push with `git push`. Use `git push --force-with-lease` only after a
  rebase. Never force-push `main`.

## 7. Update the threads

- **Bot threads you fixed:** reply with what changed and the commit SHA, then
  resolve them (`Fixed` on Azure DevOps; "Resolve conversation" on GitHub).
- **Human threads you fixed or answered:** reply with what changed and the
  commit SHA, or with the answer. Leave resolving to the reviewer unless the
  repo's `ship` skill says otherwise.
- After addressing a human reviewer's comments, post one PR comment that tags
  each of them, so they know it's ready for another look.

## 8. Repeat

Go back to step 3 and wait for Bugbot to review the new push. Also pick up
any new comments that arrived from anyone since the last round. Stop when
any of these happens:

- Bugbot's latest review has no new open findings, and no other comment is
  waiting on you.
- Three fix rounds have run. Bugbot can keep finding small nits, so let the
  user decide whether to continue.
- A comment needs the user's decision.
- Bugbot didn't finish within 15 minutes.
- The full check failed for reasons unrelated to your change.

## 9. Report

Tell the user, in plain prose:

- The PR link and branch.
- Each Bugbot finding and what happened to it: fixed in which commit, or
  declined and why.
- Each human reviewer's comment and what happened to it: fixed, answered, or
  waiting on the user's decision. Note which reviewers you tagged.
- Other bot comments you acted on, if any.
- The checks you ran and their results.
- The commits you pushed.
- Anything still open: comments waiting on a decision, or Bugbot not
  finishing.
