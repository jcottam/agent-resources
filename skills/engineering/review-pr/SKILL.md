---
name: review-pr
description: >-
  Forensic, timeline-first pull request review that reconstructs the commit
  narrative before forming opinions. Use when the user says "review PR",
  "review this PR", "look at PR #N", "what happened in this PR", "why did
  they change X", "is this PR good", "review the diff", "check this branch",
  or any variation of wanting to understand, evaluate, or critique a pull
  request. Also use when asked to compare branches, analyze a contributor's
  changes, or assess whether changes were necessary.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Review PR

A forensic, timeline-first approach to pull request review. The core insight: most bad reviews happen because the reviewer looks at the final diff in isolation and either misses the *why* behind changes or doesn't notice that intermediate churn netted to zero.

Reconstruct the narrative before forming opinions.

## Phase 1 — Orientation

Before reading any code, establish context.

### 1. Identify the hosting platform

Determine whether the repo uses GitHub, Azure DevOps, GitLab, or another host. Check git remotes:

```bash
git remote -v
```

Use the appropriate tooling:
- **GitHub** → resolve the PR and branches first:

```bash
gh pr view <N> --json baseRefName,headRefName,title,body,commits,files,statusCheckRollup,reviews
```

Use `baseRefName` as `<base-branch>` and `headRefName` as `<pr-branch>` for all subsequent commands. Do not guess the base branch.

- **Azure DevOps** → `az repos pr show --id <N>` or git log with branch inspection
- **GitLab** → `glab mr view <N>`
- **No CLI access** → fall back to `git log` on the branch

### 2. Read the PR description and commit messages

The PR description and commit messages are the contributor's stated intent — hypotheses you test against the code. Extract what the PR *claims*; do not treat claims as established fact until the net diff confirms them.

```bash
git log <base-branch>..<pr-branch> --reverse --format="%h %s%n%n%b"
```

Extract:
- What the PR claims to do (from title/description)
- How many commits are on the branch
- Whether the commit messages tell a story (tried X → fixed Y → finalized Z)

Form your own judgment of scope and risk **before** reading existing review comments or the user's stated opinion of the PR.

### 3. Check CI status

Before deep code review, inspect `statusCheckRollup` (GitHub) or equivalent CI status. If checks are failing, lead with that — a correct-looking diff that breaks the build is still a blocker.

### 4. Get the shape

```bash
git diff --stat <base-branch>...<pr-branch>
```

Note which files were touched and their rough magnitude. Flag anything unexpected:
- Utility/shared files touched by a "feature" PR
- Large line counts in files unrelated to the stated goal
- Test files present or absent

## Phase 2 — Timeline Reconstruction

This is the most valuable and most frequently skipped step.

### Walk commits in order

```bash
git log <base-branch>..<pr-branch> --reverse --oneline
```

For each commit, read the diff:

```bash
git show <sha> --stat
git show <sha> -- <file-of-interest>
```

Build a mental timeline:
- What was attempted first?
- Were there course corrections?
- Did the contributor fix their own mistakes within the branch?

### Identify reversals and churn

Look for patterns where commit N adds something and commit N+M removes it. This is normal healthy engineering — it means the contributor showed their work. Do not penalize them for it.

Flag it only if the churn is *not* cleaned up (i.e., intermediate complexity still exists in the final state).

### Compare net diff to merge base

The net diff is what actually lands on the target branch:

```bash
git diff <base-branch>...<pr-branch>
```

This is the ground truth. Individual commit diffs are useful for understanding *why*, but the net diff is what matters for the review verdict.

## Phase 3 — Categorize Changes

For each file touched in the net diff, classify the change:

| Category | Definition | Review posture |
|----------|-----------|----------------|
| **Primary** | Directly serves the PR's stated goal | Full scrutiny on correctness |
| **Supporting** | Necessary plumbing to enable primary changes | Check it's minimal, not over-engineered |
| **Opportunistic fix** | A real bug fix discovered along the way | Verify the bug was real; consider if it should be a separate PR |
| **Scope creep** | Unrelated improvement or refactor | Flag for discussion, don't block |
| **Churn** | Added and then reverted within the same PR | Confirm it truly nets to zero in the final diff |

When a change touches a **shared utility** (libraries, helpers, common components), apply extra scrutiny:
- Is the API change justified by more than one caller?
- Could the same result be achieved without modifying the shared surface?
- Are existing callers still correct?

## Phase 4 — Evaluate

Phase 4 is a draft assessment. Phase 5 may surface issues missed here; Phase 6 must reflect the updated picture.

### Review discipline

- **Test the PR's premise, don't validate it.** Check whether the net diff actually proves what the description claims before evaluating implementation details.
- **Seek disconfirming evidence.** Before approving, actively look for reasons the change could fail (missing edge cases, broken callers, rollback risk). If you find none, say so explicitly in Phase 6.
- **Confidence tags on findings.** Tag each substantive concern or approval reason as `[high confidence]`, `[moderate confidence]`, `[low confidence]`, or `[unknown]`. Example: "Race on concurrent writes [high confidence]" vs "May increase memory under load [moderate confidence — no benchmark run]."
- **Independent assessment.** Do not anchor on the PR author's framing, existing review comments, or the user's opinion until you have formed your own view from the diff and timeline.

### Primary changes

- Does the implementation match the stated intent?
- Are schemas, types, and contracts correct?
- Are edge cases handled?
- Is there test coverage for new behavior?

### Supporting changes

- Is this the minimum plumbing needed?
- Could the primary goal be achieved without this supporting change?
- Is the abstraction level appropriate (not over-engineered for a single use case)?

### Opportunistic fixes

- Was the original bug actually real? (Check git blame, production behavior, existing tests)
- Is the fix correct?
- Should it have been a separate PR for cleaner history?

### Scope creep

- Does it make the PR harder to review or revert?
- Is it entangled with the primary changes or cleanly separable?
- Note it but don't block unless it introduces risk.

### Churn

- Confirm the net diff shows zero residue from the intermediate state.
- If residue exists (dead parameters, unused imports, vestigial config), flag it.

## Phase 5 — Read the current state

For any file with significant changes, read the **current state** of the file (not just the diff). Diffs show what changed but hide whether the result is coherent. A clean diff can still produce incoherent code.

```bash
git show <pr-branch>:<path/to/file>
```

Check:
- Does the file read well as a whole?
- Are there leftover artifacts from the PR's development process?
- Is naming consistent with the rest of the codebase?

If Phase 5 reveals issues missed in Phase 4, Phase 6 must reflect the updated assessment.

## Phase 6 — Synthesize

### Tone

- Start with findings, not praise. No "great PR", "nice work", or "solid approach" openers.
- **Lead with the strongest concern** when the verdict is Request changes or Needs discussion. Steelman the contributor's approach first, then explain why it still fails the bar.
- **Separate code from contributor.** Critique the diff; do not attribute intent or competence.
- **Show reasoning for the verdict.** Cite specific files, lines, or commit SHAs — not vague impressions.

Produce a structured summary with these sections:

### 1. What the PR does
One to two sentences. What lands on the target branch?

### 2. Commit timeline
Ordered narrative of what happened on the branch. Include course corrections — they show the contributor's reasoning process.

### 3. Net impact
What actually changes after churn is removed. Distinguish "files touched" from "meaningful changes."

### 4. Change categories
Map each significant file change to its category (primary, supporting, opportunistic fix, scope creep, churn).

### 5. Concerns
Organized by severity. Tag blockers and substantive concerns with confidence levels; skip tags on pure style nits unless the nit reflects a real convention violation.

- **Correctness** — bugs, logic errors, missing edge cases
- **Scope** — changes that don't belong in this PR
- **Complexity** — over-engineering, unnecessary abstractions
- **Risk** — shared utility changes, migration concerns, rollback difficulty

### 6. Verdict
One of:
- **Approve** — changes are correct and well-scoped
- **Approve with nits** — minor suggestions that don't block merge
- **Request changes** — specific issues that need addressing before merge
- **Needs discussion** — architectural or scope questions that need team input

Always include reasoning for the verdict. Add these sub-bullets **proportionally**:

- **Steelman:** strongest case for merging as-is. Required for Request changes / Needs discussion. Optional one-liner for Approve with nits. Skip for trivial Approve (typo fixes, single-line changes).
- **Disconfirming evidence checked:** what you looked for and what you found. Required before any Approve verdict on non-trivial PRs; one sentence is enough for small changes.

## Principles

- **Never judge a diff without reading commit messages first.** The diff is the "what"; the message is the "why." You need both.
- **Always check the net diff, not just individual commits.** A 3-commit PR can have 500 lines of churn that nets to 50 lines of real change.
- **Distinguish "code in the PR" from "code landing on the target branch."** Follow-up fixups within the same branch are self-correcting, not problems.
- **Don't penalize showing work.** A commit history of "tried X → realized Y was better → switched to Y" is healthy engineering.
- **Flag shared-utility changes with extra scrutiny.** When a PR touches code that other features depend on, verify the change is justified and existing callers still work.
- **Assume good intent.** A wrong assumption that was later corrected is not incompetence — it's iterative development.
- **Separate the review from the reviewer.** Comment on the code, not the person.
- **Accuracy over agreeability.** A review that misses a real bug to avoid friction is a failed review. Deliver blockers plainly.
