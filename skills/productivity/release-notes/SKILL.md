---
name: release-notes
description: >-
  Summarize a logical grouping of git commits into plain-language release notes
  for non-technical readers. Use when the user asks for release notes, what
  changed, a summary of commits, a plain-English changelog, or an easy-to-read
  bullet list of work at a specific reading level (default 8th grade). Ask which
  boundary to use (this branch, a PR, or recent commits) before writing.
license: MIT
metadata:
  author: jcottam
  version: "1.1.0"
---

# Release Notes

Turn a logical grouping of commits into clear summaries for teammates,
stakeholders, or changelogs — not developer jargon.

## Workflow

### 1. Choose the boundary (required)

Ask **which grouping of commits** to summarize **before** gathering history or
writing notes. Do not assume. Do not default to "recent commits."

If the user already named a boundary in this request, use it. Otherwise ask
once and wait:

**Which commits should these notes cover?**

1. **This branch** — commits on the current branch that are not on the default
   base (usually `main`)
2. **A PR** — commits in a pull request (number, URL, or this branch's open PR)
3. **Recent commits** — only when the user chooses this; they must name a count,
   date, or tag

Do not gather git history or draft notes until the boundary is known.

Follow-ups after they pick:

| They chose | If still missing, ask |
|------------|------------------------|
| A PR | Which PR (number, URL), unless the current branch already has one |
| Recent commits | How far back (last *N* commits, since a date, or since a tag) |
| This branch | Nothing — detect the base and proceed |

Author, path, or extra filters are optional refinements **after** the boundary
is set, not a substitute for it.

### 2. Gather that range

Run read-only git commands. Do not commit, push, or edit files unless the user
explicitly asks.

Detect the default base with `git symbolic-ref refs/remotes/origin/HEAD` (fall
back to `origin/main` or `origin/master`).

| Boundary | Range |
|----------|-------|
| This branch | `<base>..HEAD` on the current branch. If HEAD is already the default branch, say so and ask for another boundary — there is no unique branch range. |
| A PR | Commits on the PR head that are not on its base. Prefer `gh pr view [<n>\|URL] --json title,baseRefName,headRefName,commits` when GitHub CLI is available; otherwise `git log <pr-base>..<pr-head>`. |
| Recent commits | Exactly the window they named: `git log --oneline -<n>`, `--since=<date>`, or `<tag>..HEAD`. Do not invent a count. |

Then collect detail:

```bash
git log --oneline <range>
git log --stat --format='%h %s%n%b' <range>
```

Skip empty merge commits unless they carry meaningful context.

If the range is empty, say so and stop. Do not widen the range on your own.

### 3. Understand the changes

- Read commit messages and file stats (`--stat`) to learn what actually changed.
- **Group related commits** into one user-facing idea (e.g. three truncation
  commits → "prompts load without flicker").
- Focus on **user-visible behavior**: what someone using the app will see or
  feel.
- Deprioritize internal-only work (refactors, lockfile-only bumps) unless it is
  the whole story or the user asked for technical detail.

### 4. Deliver outputs (in order)

Produce only what the user asked for. When they want the full treatment, use
this order:

1. **Technical digest** (optional) — one short paragraph for engineers; file
   names and mechanisms OK here.
2. **Plain paragraph** — 3–5 sentences at the requested reading level (default:
   8th grade).
3. **Bulleted list** — same content as the paragraph, one idea per line.

If the user liked the paragraph and asks for bullets next, convert without
re-explaining from scratch.

State the boundary you used in one short line before the notes (branch name, PR
number, or the recent-commits window).

## Plain-language writing rules

- Short sentences. Common words. Active voice.
- Describe **what changed for the user**, not which files moved.
- Prefer: "the page loads smoother", "videos show first", "a duplicate button
  was removed".
- Avoid unless requested: refactor, dependency bump, ResizeObserver, hook
  names, component paths.
- No hype ("exciting", "powerful", "game-changing"). State facts.
- Dependency updates: one line like "software packages were updated" unless
  versions matter to the audience.

### Reading levels

| Level | Guidance |
|-------|----------|
| **8th grade** (default) | Everyday words; no acronyms without explanation; one idea per sentence |
| **Executive** | Outcomes and impact; even shorter; skip implementation |
| **Technical** | Commit themes, areas touched, breaking changes; jargon OK |

## Output template

Use these headings unless the user specifies another format.

```markdown
### What changed
[One short paragraph — plain language]

### At a glance
- [Bullet 1]
- [Bullet 2]
- ...
```

For a technical-only request, omit the template and write a concise
engineer-facing summary.

## Categorization hints

When grouping commits, map themes to plain labels:

| Commit theme | Plain-language angle |
|--------------|----------------------|
| UI layout / typography | Easier to read; cleaner layout |
| Performance / flicker | Loads smoother; less jumping on screen |
| Sort / ordering | Important items show up first |
| Nav / header | Menu or navigation simplified |
| Auth / permissions | Who can do what changed |
| Dependencies | Behind-the-scenes updates (brief) |
| Tests only | Usually omit unless user cares |

## Examples

**User:** "Write release notes"

1. Ask which boundary: this branch, a PR, or recent commits. Do not log git yet.
2. After they answer, gather that range, group related commits, then write
   notes at 8th-grade level.

**User:** "Release notes for this PR"

1. Boundary is already a PR — do not re-ask. Identify the PR (current branch's
   open PR, or ask for the number if none).
2. Gather PR commits vs its base. Output paragraph + bullets.

**User:** "Summarize this branch for the team"

1. Boundary is this branch. Log `<base>..HEAD`.
2. Group related commits. Output paragraph + bullets at 8th-grade level.

**User:** "What did we ship since v1.2.0? Keep it short."

1. Boundary is recent commits with a named tag. `git log v1.2.0..HEAD --oneline`.
2. Output plain paragraph only; skip technical digest unless asked.

**User:** "Bullet list only, executive level, last 5 commits"

1. Boundary is recent commits with an explicit count. Do not ask again.
2. Output `### At a glance` bullets only; no paragraph; outcome-focused.

## Boundaries

- **Do:** ask which grouping to use, then summarize, rephrase, group, and
  adjust reading level.
- **Do not:** invent features not supported by the commits.
- **Do not:** default the range to "recent commits" or a commit count.
- **Do not:** run destructive git commands or modify the repo as part of this
  skill.
