---
name: commit-release-notes
description: >-
  Summarizes recent git commits into plain-language release notes for
  non-technical readers. Use when the user asks what changed, wants a summary of
  commits, release notes, a plain-English changelog, or an easy-to-read bullet
  list of recent work at a specific reading level (default 8th grade).
---

# Commit Release Notes

Turn git history into clear summaries for teammates, stakeholders, or changelogs — not developer jargon.

## Workflow

### 1. Gather commits

Run read-only git commands. Do not commit, push, or edit files unless the user explicitly asks.

| User intent | Command |
|-------------|---------|
| Recent work (default) | `git log --oneline -10` |
| By author | `git log --author=<name> --oneline -15` |
| Since a tag or commit | `git log <ref>..HEAD --oneline` |
| Detail per commit | `git log --stat --format='%h %s%n%b' <range>` |

**Defaults when unspecified:**
- Branch: current branch
- Count: 5–15 commits, enough to cover the work without noise
- Skip empty merge commits unless they carry meaningful context

### 2. Understand the changes

- Read commit messages and file stats (`--stat`) to learn what actually changed.
- **Group related commits** into one user-facing idea (e.g. three truncation commits → "prompts load without flicker").
- Focus on **user-visible behavior**: what someone using the app will see or feel.
- Deprioritize internal-only work (refactors, lockfile-only bumps) unless it is the whole story or the user asked for technical detail.

### 3. Deliver outputs (in order)

Produce only what the user asked for. When they want the full treatment, use this order:

1. **Technical digest** (optional) — one short paragraph for engineers; file names and mechanisms OK here.
2. **Plain paragraph** — 3–5 sentences at the requested reading level (default: 8th grade).
3. **Bulleted list** — same content as the paragraph, one idea per line.

If the user liked the paragraph and asks for bullets next, convert without re-explaining from scratch.

## Plain-language writing rules

- Short sentences. Common words. Active voice.
- Describe **what changed for the user**, not which files moved.
- Prefer: "the page loads smoother", "videos show first", "a duplicate button was removed".
- Avoid unless requested: refactor, dependency bump, ResizeObserver, hook names, component paths.
- No hype ("exciting", "powerful", "game-changing"). State facts.
- Dependency updates: one line like "software packages were updated" unless versions matter to the audience.

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

For a technical-only request, omit the template and write a concise engineer-facing summary.

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

**User:** "Summarize jcottam's last 5 commits for the team"

1. Run `git log --author=jcottam --oneline -5` and `git log --author=jcottam --stat -5`.
2. Group: prompt truncation work, browse width, model sort, nav cleanup, deps.
3. Output paragraph + bullets at 8th-grade level.

**User:** "What did we ship since v1.2.0? Keep it short."

1. Run `git log v1.2.0..HEAD --oneline`.
2. Output plain paragraph only; skip technical digest unless asked.

**User:** "Bullet list only, executive level"

1. Gather commits as above.
2. Output `### At a glance` bullets only; no paragraph; outcome-focused.

## Boundaries

- **Do:** summarize, rephrase, group, adjust reading level.
- **Do not:** invent features not supported by the commits.
- **Do not:** run destructive git commands or modify the repo as part of this skill.
- If the range is ambiguous (author? date? tag?), ask once, then proceed with a reasonable default and state it.
