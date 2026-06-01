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
  version: "4.0.0"
---

# Review PR

Forensic, stage-aware pull request review. Reconstructs the commit narrative,
tests the PR's architectural premises against project reality, and produces a
review comment the user can post directly.

Three core insights:
1. Most bad reviews happen because the reviewer looks at the final diff in
   isolation and misses the *why*.
2. Most over-engineered PRs happen because the contributor builds for imagined
   future requirements instead of the current problem.
3. Most shallow reviews happen because the reviewer catalogs file-level
   findings without first understanding what the change means for the product.
   Think about the product impact before diving into the code.

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

## Phase 5 — Strategic Assessment

**Stop. Before evaluating any individual file or concern, think about the PR
as a product decision.** Most review failures happen here — the reviewer dives
into file-level findings without first understanding what the change means for
the product, its users, and its architecture. A review that catalogs twenty
code issues but misses the one architectural tradeoff is a failed review.

### 5.1 Name the core value

State in one sentence what this PR actually improves for the product. Not what
the code does — what the *product* gains. This becomes the opening line of
your review. If you can't name the value, the PR may lack a clear purpose.

### 5.2 Identify the 2–3 decisions that matter most

Every PR of substance makes decisions — about API surface, data flow,
abstractions, constraints. Most are fine. A few are consequential. Find the
consequential ones:

- **What new constraints does this introduce?** If an input changes from a
  string to a structured object, who can no longer call this? If a workflow
  step is removed, what output disappears?
- **What new infrastructure does this add, and what's the actual usage
  pattern?** Not theoretical usage — actual current usage. One lookup per
  user journey? Thousands of concurrent requests? The answer determines
  whether caching, rate limiting, and auth tiers are justified or premature.
- **Does the deployment model support the abstraction?** Microservice
  patterns in a monolith? Versioned APIs when both sides deploy atomically?
  Schema versioning when there's one consumer?

For each decision, ground your evaluation in the project's reality: its deploy
model, its current traffic, its team size, its stage, its existing infra.
Generic best practices are not arguments — "rate limiting is a best practice"
is not a reason to add six rate limiters to an internal API with one caller.

### 5.3 Check for product-level tradeoffs

Some changes have consequences beyond the code:
- Does a new input requirement block callers that worked before?
- Does removing a feature (even via merge gap) break a user-facing output?
- Does the change create a new operational burden (env vars, infrastructure,
  deployment steps)?
- Are there follow-up tickets implied but not tracked?

If a tradeoff exists, the review should surface it as a question, not an
accusation: "Is it acceptable that X can no longer do Y? If so, let's
document it."

### 5.4 Group concerns into themes

Do **not** produce a flat list of file-level findings. Group related issues
into 2–4 coherent themes, each grounded in the product reality from 5.2. A
theme is a complete argument: what the PR does, why it doesn't fit, what to
do instead.

Bad theme: "`lib/ratelimit.ts` — six rate limiters is too many."
Good theme: "Strip the rate limiting. Our usage pattern is one lookup per
user journey — there's nothing to rate-limit at current volume. Google's
own quota limits are our rate limiter. Ship without it and revisit when
usage data calls for it."

The difference: the good version names the actual usage pattern, explains why
the infrastructure doesn't fit, and gives a clear action.

## Phase 6 — Detailed Evaluation

With the strategic assessment formed, now evaluate the details. The strategic
themes from Phase 5 are your guide — details should support or refine those
themes, not replace them.

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

### Stage-aware evaluation

| Project stage | Bias toward | Accept | Push back on |
|---------------|------------|--------|--------------|
| **Early build** | Simplicity, speed of iteration | Thin wrappers, direct calls, minimal abstraction | Infra for imagined scale, premature versioning |
| **Growth** | Reliability, observability | Caching, rate limiting, structured errors | Over-abstraction, speculative microservice splits |
| **Scale** | Performance, resilience | Multi-tier systems, circuit breakers, versioned APIs | Unnecessary rewrites of working code |

Read `AGENTS.md` and the repo structure to assess stage. If unclear, ask the
user.

### Standard evaluation

Also evaluate:
- **Correctness** — Does the implementation match the stated intent? Edge
  cases? Test coverage?
- **Supporting changes** — Minimum plumbing needed?
- **Scope creep** — Entangled with primary changes or cleanly separable?
- **Project conventions** — Does it follow AGENTS.md boundaries? Are shared
  files (AGENTS.md, workflow-steps, etc.) updated when required?
- **Dead code** — Unused imports, "kept for future callers" functions,
  unreachable branches.

Fold detail findings into the strategic themes from Phase 5. If a detail
doesn't fit any theme, it goes into housekeeping.

### Fast path — clean PRs

If after Phases 1–6 no substantive concerns emerge (correct implementation,
proportional scope, follows conventions, has tests), skip to Phase 8 with a
short approval. Do not manufacture findings to justify the review's existence.
A clean PR gets:

- Confirmation of what it does (one sentence)
- Verdict: **Approve**
- No comment to post (or a one-line "LGTM — [what you verified]")

## Phase 7 — Collaborative Refinement

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

## Phase 8 — Produce the PR Comment

After collaborative refinement, produce a comment the user can post directly.

### Format

The review is a short essay, not a checklist. Structure it as themed
paragraphs, each making a complete argument.

**Opening paragraph:** Name what the PR gets right and *why* it's valuable.
This is not flattery — it tells the contributor you understand the intent and
frames the subsequent asks as refinements, not rejections.

**Themed paragraphs (2–4):** Each paragraph is one coherent concern. Open with
a clear directive ("Strip the rate limiting.", "Drop the versioning."), then
explain *why* grounded in the project's actual reality (deploy model, usage
pattern, existing infra), then state what to do instead. Don't split a single
theme across multiple numbered items.

**Tradeoff questions (if any):** When the PR introduces a constraint that may
or may not be acceptable, frame it as a question: "The workflow now requires X.
Is that an acceptable tradeoff? If so, let's document it. If not, we need a
fallback."

**Housekeeping:** A short bullet list for minor items (dead imports, missing
doc updates, convention violations) that don't merit their own paragraph.

**What should land:** One paragraph specifying the subset to merge now and
what to split into follow-up tickets.

Example structure:

```
Overall: [What the PR gets right and why it matters.]

[Theme 1 directive.] [Why, grounded in project reality.] [What to do.]

[Theme 2 directive.] [Why.] [What to do.]

[Tradeoff question, if any.]

Housekeeping:
- [Item]
- [Item]

What I'd like to land: [Specific subset. What to defer.]
```

### Tone

- Open with genuine recognition of value — but be specific about *what* is
  valuable, not generic praise.
- Critique the decisions, not the person.
- Ground every ask in the project's actual reality, not generic best practices.
  "We don't need this" is weak. "We don't need this because our usage pattern
  is X and our deploy model is Y" is strong.
- If asking the contributor to reconsider a tradeoff, frame as a question.
- Be direct about what to cut. "Strip X" is clearer than "Consider whether X
  is needed."

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
