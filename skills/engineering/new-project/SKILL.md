---
name: new-project
description: >-
  Kickstart a new project by interviewing for context, choosing Astro or
  Next.js and extras, then scaffolding a barebones app on Vercel with Tailwind,
  base shadcn/ui, pnpm, Vitest, a `pnpm check` gate, AGENTS.md, a
  plain-language README, a CHANGELOG, and a GitHub repo under `jcottam`. Use
  when the user says "new project", "start a project", "scaffold", "bootstrap",
  "init a repo", or "spin up an app".
license: MIT
metadata:
  author: jcottam
  version: "0.2.0"
---

# New Project

Interview first. Understand the product, pick Astro or Next.js, and decide
which extras belong in v0. Then scaffold the smallest working project, verify
it, and push it. Everything else gets added later, one block at a time.

The user is a senior web developer. Skip explanations of basics. Ask only what
you can't infer. Do not silently fill gaps in the stack.

## Gate

Do not create a directory, run a generator, write app files, or open a repo
until all of these are true:

1. You understand the product (name, purpose, who it's for, site vs app).
2. The framework is **Astro** or **Next.js**, chosen after questions — never
   assumed, never a silent default.
3. Each extra that could apply is **in v0**, **later**, or **out**. Ask; do
   not assume.
4. You recapped the stack in a short table and the user confirmed it.

If the user already answered something, don't re-ask. Partial answers are not
permission to scaffold. If they say "just start" without a framework, still
ask the discriminating questions, recommend one, and wait.

## Defaults vs choices

State the defaults. Only ask about them if the conversation contradicts them.
**Framework has no default.**

| Concern | Choice |
| --- | --- |
| Framework | *No default.* Astro **or** Next.js — ask, then confirm. |
| Hosting | Vercel |
| Styling | Tailwind CSS |
| Components | shadcn/ui, base components customized in place (React; on Astro that means the React integration) |
| Package manager | pnpm |
| Tests | Vitest + Testing Library |
| Lint | ESLint, as the generator configures it |
| Repo | GitHub, `jcottam` org, private unless told otherwise |

## Interview

Work in rounds. Don't dump the whole list. Don't implement between rounds. Ask
in the conversation; if the host has a structured question tool, use it.

### 1. Product

Ask:

- Project name
- One-sentence purpose
- Who uses it and what they do in it
- Is v0 a **site** (content, marketing, docs, brochure) or an **app** (auth,
  dashboards, mutations, user-specific data)?
- What must exist on day one vs later?

### 2. Framework — Astro or Next.js

Ask enough to recommend. Discriminators:

- HTML-first pages with islands of interactivity, or React as the default UI?
- Mostly public / static-capable pages, or authenticated / session-heavy flows?
- Content collections, MDX, or marketing as the core — or app routing, server
  mutations, and dashboard UI?

Recommend explicitly, with one or two lines of why:

- **Astro** — content-led sites, marketing, docs, portfolios, mostly public
  pages, islands of interactivity
- **Next.js** (App Router, TypeScript, `src/`) — app-led products, auth,
  dashboards, mutations, React-default UI

If mixed, ask which shape v0 is. **Do not pick one without confirmation.**

### 3. Extras — ask; none ship in v0 unless yes

For each extra that could apply, ask **in v0 / later / out**. Skip only when
the purpose makes it nonsense. When in doubt, ask.

| Extra | Discriminators |
| --- | --- |
| Database | **Supabase** (Postgres, Auth, Realtime) vs **Turso** (libSQL / SQLite at the edge, lighter) vs none |
| Storage | **Vercel Blob** (simple, Vercel-native) vs **Cloudflare R2** (scale, cost, S3, access outside Vercel) vs none |
| Email | **Resend** vs none |
| AI | **Vercel AI Gateway** through the AI SDK vs none |
| Edge and access | **Cloudflare DNS / domains** and/or **Zero Trust (Access)** vs none |

Do not install or configure an extra until the answer is **in v0**. "Later" is
not a yes. Never add an extra because it appears on this list.

### 4. Recap

Print a short stack table: framework, defaults, each extra as in / later /
out. Wait for go-ahead. Then scaffold.

## Rules

- **Build by addition.** Start from nothing and add only what the current step
  needs. No speculative packages, folders, or abstractions.
- **Latest stable.** Use `@latest` installers and resolve versions live. Never
  pin from memory. No canary, beta, or RC.
- **Trust the generator's current output, not your memory of it.** Defaults
  shift between majors (lint config, Tailwind config, CLI flags). Read what
  was generated before building on it.
- **Green before push.** `pnpm check` and `pnpm build` pass before the first
  push.

## Steps

1. **Interview** (see above). Stop here until the gate is met.

2. **Scaffold** the chosen framework. Pass flags rather than interactive
   prompts. If a flag is rejected, check `--help` and current docs.
   - **Next.js:** `pnpm create next-app@latest <name>` with TypeScript,
     Tailwind, ESLint, App Router, `src/`, `@/*` alias.
   - **Astro:** `pnpm create astro@latest <name>` with TypeScript (current
     default), Tailwind, and the React integration. Add the official Vercel
     adapter. Ensure `@/*` → `./src/*` in `tsconfig`.
   - `pnpm dlx shadcn@latest init` with defaults (Astro: current Astro
     template / docs).
   - Set `"version": "0.1.0"`, `packageManager` (current pnpm), and
     `engines.node` (current LTS) in `package.json`.

3. **Strip to zero.** Replace the demo home page with a `<main>` holding an
   `<h1>` (project name) and the purpose sentence. Delete demo assets in
   `public/`. Set real title / metadata in the root layout. Add an empty
   `.env.example`.

4. **Base features.**
   - Dark mode: shadcn mode toggle on the home page. Next.js: `next-themes`
     provider in the root layout. Astro: follow current shadcn Astro theming
     (class on `<html>`, toggle as a React island). Do not invent a package.
   - Vercel Analytics and Speed Insights in the root layout, using the
     current package for that framework.

5. **Chosen v0 extras.** Only those marked **in v0**. Follow the provider's
   current docs. Add variables to `.env.example` (and to Vercel by hand later
   with `vercel env add`). Keep secrets in server-only modules. Skip this
   step when every extra is later or out.

6. **Tests and `pnpm check`.**
   - Add Vitest with jsdom, the React plugin when React is in play, tsconfig
     paths, and jest-dom matchers.
   - One smoke test that renders the home page and asserts the `<h1>`. Add a
     test for each v0 extra that introduced a code path.
   - Scripts: `lint`, `typecheck` (`tsc --noEmit` on Next.js; `astro check`
     or current Astro equivalent), `test` (`vitest run`), `test:watch`, and
     `check` running lint, typecheck, then test. Add ESLint if the generator
     didn't.
   - Run `pnpm check` and `pnpm build`; fix until green.

7. **Docs.**
   - `AGENTS.md`: purpose, stack table (actual choices, including extras in /
     later / out), commands, and conventions (build by addition, add shadcn
     components through the CLI, server-only secrets stay out of client code,
     new features ship with a test, `pnpm check` before commit). Under ~60
     lines. Symlink `CLAUDE.md` to it.
   - `README.md`: 8th-grade reading level. What it is, what it does, how to
     run it, and how to check it. No badges or empty sections.
   - `CHANGELOG.md`: `# Changelog` header, then `## [0.1.0] - <today>` with
     `### Features` listing "Initial project setup".

8. **Ship it.**
   - Commit, then `gh repo create jcottam/<name> --private --source=. --push`.
   - Add `.github/workflows/check.yml` that runs `pnpm check` on push and
     pull request.
   - `vercel link` and connect the Git repo. Confirm the first deployment
     succeeds.

9. **Report** the repo URL, the deployment URL, the `pnpm check` result, the
   chosen framework, extras in / later / out, the resolved versions of the
   framework, React, Tailwind, and shadcn, and any assumptions or skipped
   steps.

## Adding blocks later

When a later extra (Supabase, Turso, Resend, R2, Zero Trust, or anything new)
becomes a feature, follow the provider's current docs, then:

- Add new variables to `.env.example` and to Vercel by hand (`vercel env add`).
- Keep secrets in server-only modules.
- Add at least one test for the new code path.
- Note it in the AGENTS.md stack table and, if it changes setup, the README.
- Run `pnpm check`.

Choices that need judgment when they come up:

- **AI:** call models through the AI SDK with AI Gateway model strings
  (`provider/model`) instead of installing provider SDKs one by one. On
  Vercel, auth comes from OIDC (`vercel env pull` locally); use
  `AI_GATEWAY_API_KEY` only outside Vercel.
- **Storage:** start with Vercel Blob. Move to R2 when files are large or
  numerous, egress cost matters, or you need S3-compatible APIs, bucket
  policies, or access from outside Vercel. Keep storage behind one small
  module so the swap touches one file.
- **Database:** Supabase when you want Postgres plus Auth / Realtime.
  Turso when you want libSQL / SQLite at the edge and a smaller footprint.
  Don't run both unless the product actually needs both.
