---
name: handoff
description: >-
  Compact a chat session or task into a curated markdown handoff file under
  ~/.agents/handoffs/ for continuation in a new agent turn or chat. References
  existing plans and PRDs by path instead of duplicating them; optional next-session
  focus via arguments. Use when the user says handoff, compact context, resume
  handoff, continue session, carry over context, checkpoint, or start fresh with
  prior work. Not the content-wireframe implementer handoff.
license: MIT
metadata:
  author: jcottam
  version: "1.2.0"
disable-model-invocation: true
argument-hint: What will the next session be used for?
---

# Handoff

Editorially compress session context into a small markdown checkpoint an agent
can load in a new turn. Raw transcripts live under Cursor project folders;
handoffs are **curated, short, and decision-dense**.

`SCRIPTS` refers to the `scripts/` directory next to this file.
`HANDOFFS_ROOT` is `~/.agents/handoffs/`.

This skill is **not** the content-wireframe "Handoff" (approved copy →
implementer). It is **session/task continuity** across chats or agents.

## Choose mode

| User intent | Mode |
|-------------|------|
| handoff, compact, checkpoint, save context, done for today | **Create** |
| resume handoff, continue from handoff, load handoff, `@` handoff file | **Resume** |

If ambiguous, ask once which mode they want.

---

## Create

### Phase 0 — Eligibility

Skip creating a handoff (tell the user why) if **all** are true:

- The task is fully done with nothing left to continue
- There are no decisions, partial state, or open questions worth preserving
- A PR/commit message or one sentence is enough (`ship` may be better)

### Phase 1 — Gather inputs

Collect signal in this order. Do **not** paste tool dumps or transcript chunks
into the handoff file.

1. User goal and latest instructions
2. **Next session focus** — if the user passed slash/command arguments or
   stated what the next chat is for, treat that as the primary lens for
   **Next steps** and **Suggested skills**
3. Run `$SCRIPTS/workspace-id.sh` and parse JSON (`workspace_path`,
   `workspace_id`, `git_head`)
4. If git repo: `git status -sb`, `git diff --stat` (and branch name)
5. Files the user `@` mentioned or the agent edited this session
6. Explicit **decisions** and **reversals** from the conversation
7. Open questions, blockers, and **failed approaches** (do not redo)
8. **Existing artifacts** — scan for PRDs, specs, plans, ADRs, issues, open
   PRs, and large on-disk docs. Note paths only; do not copy their contents
   into the handoff (see deduplication below)
9. **Session activity** — condensed outcomes from tool use this session (files
   written, commands run and key results, PRs opened, tests pass/fail counts).
   Outcomes only; no raw stdout or play-by-play

### Phase 2 — Write

**Timestamps and filename:** Do not invent times. Run bash before writing:

```bash
date +%Y-%m-%dT%H:%M:%S%z    # created_at in frontmatter
date +%Y-%m-%d                  # date in frontmatter
date +%H:%M                     # time in frontmatter
```

**Slug:** from user input, next session focus, or 3–5 words from the goal
(kebab-case). Sanitize for filenames — omit `: / \ # ^ [ ] |` and spaces.

**Fidelity:** Set frontmatter `fidelity`:

- `full` — handoff built from complete session context in the current turn
- `partial-reconstruction` — earliest chat context was compacted or missing;
  some sections are reconstructed from inference, not verbatim memory

If `partial-reconstruction`, add this block immediately after the `# Handoff:`
heading (before **TL;DR**):

```markdown
> **Context warning:** Portions of this handoff were reconstructed from
> compacted or missing session context. Treat **Assumptions** and uncited claims
> as unverified until confirmed in the repo or artifacts.
```

Never present reconstructed content as verified fact — move uncertain items to
**Assumptions**.

**Deduplication:** Do not duplicate content already captured in workspace
artifacts (PRDs, specs, plans, ADRs, issues, commit messages, or large diffs).
Reference by path or URL; at most one line summarizing why that artifact matters.
Never paste plan bodies, issue threads, or diff hunks into the handoff.

**Paths:** Use the real timestamp from `date` in the filename:

```
$HANDOFFS_ROOT/<workspace_id>/<YYYY-MM-DD>T<HHMMSS>-<slug>.md
$HANDOFFS_ROOT/<workspace_id>/latest.md   # copy of the same content
```

Example: `2026-06-02T143022-ship-handoff.md`

Create `$HANDOFFS_ROOT/<workspace_id>/` if missing.

**Budget:** ≤120 lines (~2,500 words). Cut exploration narrative first, then
session activity detail, then artifact detail. Never cut **TL;DR**, **Next
steps**, or **Do not redo**.

**Redaction (before write):** Remove API keys, tokens, `.env` values,
passwords, and personally identifiable information. Use `[REDACTED]`. When
unsure, omit the line.

Use this template:

```markdown
---
handoff_version: 2
title: Short Title
date: 2026-06-02
time: "14:30"
created_at: 2026-06-02T14:30:22-0400
workspace_path: /absolute/path/to/project
workspace_id: agent-resources-a3f9c2e1b4d0
git_head: abc123def456789...
fidelity: full
source: cursor-chat
tags: [handoff, topic-one, topic-two]
supersedes: null
---

# Handoff: [short title]

## TL;DR

[3–4 sentences max: what this session was about, what was decided or produced,
and open loops. Write so a future search reveals whether this is the right
handoff. Do not duplicate **Next steps** verbatim.]

## Goal

[One sentence]

## Next session focus

[What the next chat is for — from user args or conversation. Omit this section
if not provided.]

## Current state

- Branch: ...
- Status: [what is done / in progress]
- Key changes: [files or areas touched]

## Session activity (condensed)

[Outcomes-only digest of meaningful tool/session work — not a transcript.
Bullet list: files created/edited, commands and key results, PRs/issues touched,
tests run and pass/fail counts. Omit raw stdout. Omit section if nothing
concrete happened beyond conversation.]

## Decisions

| Decision | Rationale |
|----------|-----------|
| ... | ... |

## Verified facts

- [Things confirmed in repo, docs, or commands]

## Assumptions

- [Guesses not yet verified — label clearly]

## Constraints

- [User rules, repo conventions, explicit "do not"]

## Do not redo

- [Approach X failed because Y — do not retry unless user asks]

## Open questions

- [ ] ...

## Next steps

1. ...
2. ...

## Suggested skills

[List 0–3 installed skills the next agent should consider invoking, each with
one line why. Only skills that match **Next session focus** or **Next steps**.
Use skill `name` from frontmatter (e.g. `ship`, `review-pr`). Omit section if
none apply.]

## Artifacts

- `path/to/file` — why it matters (reference only; no duplicated content)
- PR/issue URL if any
- **Quantifiable facts** not stored in linked files: version numbers, error
  codes, test counts, env var names, config keys, metric values
```

Set `supersedes` to the prior handoff path when continuing a multi-session task.
Set `tags` to 2–5 lowercase hyphenated topics for search (always include
`handoff`). Set `title` to match the `# Handoff:` heading.

### Phase 3 — Verify and report

1. Count lines; trim if over budget
2. Copy the file to `latest.md` in the same `workspace_id` folder
3. Tell the user:
   - Absolute path to the timestamped file
   - That `latest.md` was updated
   - To attach with `@` or say **resume handoff** in the next chat
4. Note: handoffs are not auto-deleted; prune old files manually if needed

---

## Resume

### Phase 1 — Load

1. If the user `@` a specific `.md` file, read that file
2. Else run `$SCRIPTS/workspace-id.sh`, then read:
   `$HANDOFFS_ROOT/<workspace_id>/latest.md`
3. If `latest.md` is missing, list `$HANDOFFS_ROOT/<workspace_id>/` and ask
   which file to use

### Phase 2 — Validate

1. Compare `workspace_path` in frontmatter to `$SCRIPTS/workspace-id.sh`
   output. If they differ, warn and ask whether to trust the handoff or
   re-audit the repo
2. If `git_head` is set and the repo has git: compare to current
   `git rev-parse HEAD`. If they differ, say the repo moved on and ask
   whether to trust handoff state or re-gather git status
3. If frontmatter `fidelity` is `partial-reconstruction`, treat **Verified
   facts** skeptically and re-verify before acting on them
4. This handoff does **not** replace `AGENTS.md`, `.cursor/rules/`, or user
   rules — read those before implementing code if relevant

### Phase 3 — Continue

In one short message: restate **TL;DR** or **Goal** (and **Next session focus**
if present) and **Next step 1**, then execute. Do not parrot the entire file. Work from
**Next steps** in order; respect **Do not redo** and **Constraints**.

If **Suggested skills** lists skills, read and follow those skill files when
their scope matches the current task — do not invoke them blindly if the work
has diverged.

---

## Utility script

**workspace-id.sh** — stable paths for handoff storage:

```bash
$SCRIPTS/workspace-id.sh
$SCRIPTS/workspace-id.sh /path/to/workspace
```

Example output:

```json
{
  "workspace_path": "/Users/me/apps/agent-resources",
  "workspace_id": "agent-resources-a3f9c2e1b4d0",
  "git_head": "abc123..."
}
```

`git_head` is `null` when not inside a git repository.
