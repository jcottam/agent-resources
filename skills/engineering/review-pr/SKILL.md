---
name: review-pr
description: >-
  Forensic, stage-aware pull request review. Reconstructs the commit narrative,
  tests architectural premises against project reality, detects over-engineering,
  and produces a ready-to-post review comment. Use when the user says "review PR",
  "review this PR", "review PR #N", "is this PR ready to merge", "review the
  diff", or any variation of wanting to critically evaluate a pull request for
  merge readiness. Do NOT use for branch summaries or "what does this PR do"
  questions — those are explanation tasks, not reviews.
license: MIT
metadata:
  author: jcottam
  version: "3.0.0"
---

# Review PR

Forensic, stage-aware pull request review. Reconstructs the commit narrative,
tests the PR's architectural premises against project reality, and produces a
review comment the user can post directly.

Two core insights:
1. Most bad reviews happen because the reviewer looks at the final diff in
   isolation and misses the *why*.
2. Most over-engineered PRs happen because the contributor builds for imagined
   future requirements instead of the current problem.

## Phase 1 — Orientation

Before reading any code, establish context.

### 1. Get PR metadata

```bash
git remote -v
```

**GitHub (primary path):**

```bash
gh pr view <N> --json baseRefName,headRefName,title,body,commits,files,statusCheckRollup,reviews
```

**Fallback (no `gh` CLI or non-GitHub remote):**

```bash
git log --oneline <base-branch>..<pr-branch>
git diff --stat <base-branch>...<pr-branch>
```

Use the resolved base/head branch names for all subsequent commands.

### 2. Read project conventions

Before forming opinions, read the project's own rules:
- `AGENTS.md` — architecture, boundaries, "always do / never do" lists
- `.cursor/rules/` — workspace rules that apply to all changes
- `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` if present

If none of these exist, infer conventions from the existing codebase: look at
2–3 files in the same directory as the PR's primary changes. Match naming,
error handling patterns, test structure, and abstraction level already
established.

These are the standards the PR should be measured against, not generic best
practices.

### 3. Read the PR description and commit messages

```bash
git log <base-branch>..<pr-branch> --reverse --format="%h %s%n%n%b"
```

Extract what the PR *claims* to do. Do not treat claims as fact until the
diff confirms them. Form your own judgment of scope and risk before reading
existing review comments or the user's opinion.

### 4. Check CI status

If checks are failing, lead with that.

### 5. Get the shape

```bash
git diff --stat <base-branch>...<pr-branch>
```

Flag anything unexpected: utility files touched by a feature PR, large line
counts unrelated to the stated goal, test files present or absent.

## Phase 2 — Timeline Reconstruction

```bash
git log <base-branch>..<pr-branch> --reverse --oneline
```

### Scaling strategy

| PR size | Approach |
|---------|----------|
| **≤15 commits, ≤30 files** | Full reconstruction — read every commit's `--stat`, inspect files of interest |
| **16–40 commits or 31–80 files** | Sample — read first commit, last commit, and any commit whose message signals a pivot ("revert", "actually", "try different approach"). Focus on the 5 highest-churn files. |
| **>40 commits or >80 files** | Shape-only — read `--stat` for all commits but only inspect the 3–5 files with the largest net diff. Note in findings that full reconstruction was not feasible. |

### Reconstruction

For each commit in scope, read `git show <sha> --stat` and inspect files of
interest.

Build a timeline: what was attempted first, were there course corrections,
did the contributor fix their own mistakes within the branch?

**Reversals and churn** — commit N adds something, commit N+M removes it.
Normal and healthy. Flag only if intermediate complexity survives in the final
state.

**Net diff is ground truth:**

```bash
git diff <base-branch>...<pr-branch>
```

Individual commits explain *why*; the net diff is what lands.

## Phase 3 — Categorize Changes

For each file in the net diff:

| Category | Definition | Review actions |
|----------|-----------|----------------|
| **Primary** | Directly serves the PR's stated goal | Read full file (Phase 4). Check correctness, edge cases, test coverage. Evaluate naming, error paths, and interaction with existing code. |
| **Supporting** | Necessary plumbing for primary changes | Verify it's the minimum change needed. Check: could the primary change work without this? Is the API surface minimal? |
| **Opportunistic fix** | Real bug fix discovered along the way | Confirm the bug exists on main. Check the fix is correct. Flag for separate PR if it complicates revert. |
| **Scope creep** | Unrelated improvement or refactor | Note in findings. Don't block merge unless it creates risk. Suggest splitting. |
| **Churn** | Added and reverted within the same PR | Run `git diff <base>...<head> -- <file>` to confirm net-zero. If not net-zero, reclassify. |

Shared utility changes get extra scrutiny: is the API change justified by more
than one caller? Could the same result be achieved without modifying the shared
surface?

## Phase 4 — Read the Current State

For files categorized as **Primary**, read the full file on the PR branch:

```bash
git show <pr-branch>:<path/to/file>
```

Diffs show what changed but hide whether the result is coherent. Check for
leftover artifacts, naming consistency, dead imports. Understanding the full
file prevents forming architectural opinions from incomplete context — a diff
that looks over-engineered may match patterns already established in the file.

For large files (>500 lines), read at minimum the 50 lines surrounding each
change hunk plus the file's imports/exports.

## Phase 5 — Evaluate Proportionality

This is where most reviewers stop at "is the code correct?" and miss "is the
code necessary?"

### Over-engineering detection

For each piece of infrastructure the PR introduces, ask:

1. **What problem does this solve right now?** Not "could solve someday" —
   right now, for current users at current scale.
2. **Is there evidence the problem exists?** Usage data, incident reports,
   user complaints, or is it anticipatory?
3. **What's the simplest thing that could work?** If the answer is 50 lines
   and the PR ships 500, the 450-line delta needs justification.
4. **Does this match the project's stage?** Early-stage projects should
   optimize for speed of iteration, not theoretical scalability.

Common over-engineering patterns:
- **Versioned internal APIs** (`/v1/`, `schemaVersion`) in monorepos that
  deploy atomically
- **Multi-tier auth/rate-limiting** for traffic patterns that don't exist yet
- **Custom observability layers** when the stack already has tracing
- **Microservice boundaries** (self-calling HTTP, message dispatch) inside a
  monolith
- **Caching infrastructure** for access patterns with no repeated reads
- **Abstract interfaces** with a single implementation
- **"Kept for future callers"** exports that nobody calls

When flagging over-engineering, always steelman first: state the strongest case
for the infrastructure, then explain why the current reality doesn't justify
it.

### Stage-aware evaluation

| Project stage | Bias toward | Accept | Push back on |
|---------------|------------|--------|--------------|
| **Early build** | Simplicity, speed of iteration | Thin wrappers, direct calls, minimal abstraction | Infra for imagined scale, premature versioning |
| **Growth** | Reliability, observability | Caching, rate limiting, structured errors | Over-abstraction, speculative microservice splits |
| **Scale** | Performance, resilience | Multi-tier systems, circuit breakers, versioned APIs | Unnecessary rewrites of working code |

Read `AGENTS.md` and the repo structure to assess stage. If unclear, ask the
user.

### Architecture challenge

Test the PR's architectural premises:
- Does the deployment model support the abstraction? (Microservice patterns in
  a monolith? Versioned APIs with atomic deploys?)
- Does the PR introduce infrastructure that duplicates what the stack already
  provides?
- Does a new constraint (e.g., requiring a pre-resolved object instead of a
  string) have downstream consequences for other callers?
- If the PR changes a workflow or pipeline, what breaks for existing
  consumers?

### Standard evaluation

Also evaluate:
- **Correctness** — Does the implementation match the stated intent? Edge
  cases? Test coverage?
- **Supporting changes** — Minimum plumbing needed?
- **Scope creep** — Entangled with primary changes or cleanly separable?
- **Project conventions** — Does it follow AGENTS.md boundaries? Are shared
  files (AGENTS.md, workflow-steps, etc.) updated when required?

Tag substantive concerns with confidence levels: `[high confidence]`,
`[moderate confidence]`, `[low confidence]`.

### Fast path — clean PRs

If after Phases 1–5 no substantive concerns emerge (correct implementation,
proportional scope, follows conventions, has tests), skip to Phase 7 with a
short approval. Do not manufacture findings to justify the review's existence.
A clean PR gets:

- Confirmation of what it does (one sentence)
- Verdict: **Approve**
- No comment to post (or a one-line "LGTM — [what you verified]")

## Phase 6 — Collaborative Refinement

Present findings to the user, then **expect corrections**. The reviewer often
lacks context the user has:

- The branch may have forked before certain features existed on the target
  (apparent "removals" are merge gaps, not regressions)
- A decision that looks wrong from the diff may have been discussed and agreed
  offline
- The contributor may have constraints you can't see from the code

When the user corrects an assumption, update your assessment immediately. Drop
the finding — don't hedge or footnote it.

This is iterative. The first pass surfaces raw findings; dialogue refines them
into the actual review.

## Phase 7 — Produce the PR Comment

After collaborative refinement, produce a comment the user can post directly.

### Format

Each concern is one block: location, problem, fix. No preamble.

```
**1. [File or area]** — [Problem in one sentence]. [What to do about it.]

**2. [File or area]** — [Problem]. [Fix.]

**Housekeeping:**
- [Item]
- [Item]

**What should land:** [Subset to merge now. What to split out.]
```

### Tone

- No openers. No "overall" paragraph. No "great work" buffer.
- Lead with the strongest concern.
- Critique the diff, not the contributor.
- If asking the contributor to reconsider a tradeoff, frame as a question.

### Verdict (internal, not in the posted comment)

One of:
- **Approve** — correct and well-scoped
- **Approve with nits** — minor suggestions, don't block merge
- **Request changes** — specific issues that must be fixed before merge
- **Split** — correct work but too large or entangled; specify which subset to merge now and what to extract into follow-up PRs
- **Needs discussion** — architectural questions that need team input before proceeding

## Principles

- Never judge a diff without reading commit messages first.
- Always check the net diff, not just individual commits.
- Don't penalize showing work — course corrections within a branch are healthy.
- Infrastructure should be justified by current reality, not anticipated need.
- Assume good intent. Challenge the code, not the person.
- Accuracy over agreeability. A review that misses a real problem to avoid
  friction is a failed review.
