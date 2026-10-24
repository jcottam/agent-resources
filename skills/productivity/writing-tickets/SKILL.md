---
name: writing-tickets
description: >-
  Write or rewrite an issue tracker ticket (Linear, GitHub Issues, Jira, or
  similar) that a person or coding agent will pick up. States the objective,
  evidence, decisions already made, hard rules, and done criteria, and leaves
  the how to the implementer. Use when the user says "write a ticket", "file an
  issue", "create a Linear issue", "open a GitHub issue", "rewrite this
  ticket", "turn this into a ticket", or any variation of wanting a task
  written up for someone else to implement.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Writing Tickets

A ticket sets up whoever picks it up, whether a person or a coding agent, to succeed. It says **what** needs to happen and **why**, not **how**. The implementer is closest to the code and decides the approach.

This matters even more for AI agents, which take tickets literally: every step you list is something they build, whether or not it still makes sense once they're in the code. Prescriptive tickets add bloat, unintended behavior, and things that later have to be ripped out.

## Before writing

1. Do light discovery only: read the error, the failing log, the relevant file or two, and the recent commits. The goal is to get the problem and its evidence right, not to design the fix.
2. Find out what's already decided. Ask the requester if a choice that matters is still open (for example, which version, which vendor, or what's in or out of scope).

## Sections

Use these sections in this order and skip any that would be empty.

- **Objective.** One or two sentences on the outcome we want and why it matters.
- **Problem / Evidence.** What's happening now, with the facts that prove it: exact error text, links to failing runs, commit SHAs, affected files, and how it shows up for users. Report what you saw, not guesses about the fix.
- **Decisions already made.** Choices the requester has already made that the implementer shouldn't reopen (for example, "Use Node 24 everywhere"). Leave this out if there are none.
- **Hard rules.** The real constraints and known traps: what must not be touched, things that need a human (like dashboard settings or secrets), and safety lines like "don't apply migrations to production" or "don't merge; the owner reviews."
- **Done when.** Observable acceptance criteria someone can check, like "CI is green on the PR" or "the preview deploy builds on X." Describe the end state, not the steps to reach it.

## Don't

- Write numbered implementation steps, file-by-file edit lists, or code snippets of the fix.
- Propose new tooling, infrastructure, or dependencies unless the requester already decided on them. Prefer the smallest change that meets the objective, and let the implementer judge that.
- Bundle side quests. If you notice a separate problem, mention it in one line or file its own ticket.
- Pad the ticket. Short and clear beats thorough and noisy.

## Housekeeping

- The title should name the outcome or the problem, not the method.
- Set the priority, project, and any labels the workspace requires (for example, a repo label that tells a cloud agent which repository to use).
- Link related tickets instead of restating them.

## Example

Too prescriptive: "1. Set node-version: 24 in ci.yml. 2. Add a Docker Hub login step. 3. Cache the database images..."

Better:

> **Objective:** Get main back to green and standardize the project on Node 24.
>
> **Evidence:** The production build fails in CI with "Node.js v22.23.3 is not supported... >=22.23.4" since commit `abc1234` (link to the failing run).
>
> **Decisions:** Node 24 everywhere: CI, local dev, and hosting.
>
> **Hard rules:** No production migrations. Don't merge.
>
> **Done when:** CI is green on the PR, and the preview deploy builds on Node 24.
