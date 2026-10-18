---
name: new-project
description: >-
  Kickstart a new barebones Next.js project on John's preferred stack: Vercel,
  Tailwind, base shadcn/ui, pnpm, Vitest, a `pnpm check` gate, AGENTS.md, a
  plain-language README, a CHANGELOG, and a GitHub repo under `jcottam`. Use
  when the user says "new project", "start a project", "scaffold", "bootstrap",
  "init a repo", or "spin up an app".
license: MIT
metadata:
  author: jcottam
  version: "0.1.0"
---

# New Project

Scaffold the smallest working project on the stack below, verify it, and push it. Everything else gets added later, one block at a time.

The user is a senior web developer. Skip explanations of basics. Ask only what you can't infer, state assumptions in one line, and move.

## Stack

| Concern | Choice |
| --- | --- |
| Framework | Next.js (App Router, TypeScript, `src/`) |
| Hosting | Vercel |
| Styling | Tailwind CSS |
| Components | shadcn/ui, base components customized in place |
| Package manager | pnpm |
| Tests | Vitest + Testing Library |
| Lint | ESLint, as configured by `create-next-app` |
| Repo | GitHub, `jcottam` org |

### Later, when needed

| Concern | Choice |
| --- | --- |
| AI | Vercel AI Gateway through the AI SDK |
| Storage | Vercel Blob for simple needs; Cloudflare R2 once scale, cost, or requirements outgrow it |
| Database | Supabase |
| Email | Resend |
| Edge and access | Cloudflare (DNS, domains, Zero Trust) |

This table is context, not a to-do list. Do not install or configure any of it until a feature calls for it.

## Rules

- **Build by addition.** Start from nothing and add only what the current step needs. No speculative packages, folders, or abstractions.
- **Latest stable.** Use `@latest` installers and resolve versions live. Never pin from memory. No canary, beta, or RC.
- **Trust the generator's current output, not your memory of it.** Defaults shift between majors (lint config, Tailwind config, CLI flags). Read what was generated before building on it.
- **Green before push.** `pnpm check` and `pnpm build` pass before the first push.

## Steps

1. **Ask** for the project name and a one-sentence purpose. Default to a private repo unless told otherwise.

2. **Scaffold.**
   - `pnpm create next-app@latest <name>` with TypeScript, Tailwind, ESLint, App Router, `src/`, `@/*` alias. Pass flags rather than going through the interactive prompts. If a flag is rejected, check `--help`.
   - `pnpm dlx shadcn@latest init` with defaults.
   - Set `"version": "0.1.0"`, `packageManager` (current pnpm), and `engines.node` (current LTS) in `package.json`.

3. **Strip to zero.** Replace the demo home page with a `<main>` holding an `<h1>` (project name) and the purpose sentence. Delete demo assets in `public/`. Set real `metadata` in the root layout. Add an empty `.env.example`.

4. **Base features.**
   - Dark mode: `next-themes` provider in the root layout plus the shadcn mode toggle, placed on the home page.
   - Vercel Analytics and Speed Insights components in the root layout.

5. **Tests and `pnpm check`.**
   - Add Vitest with jsdom, the React plugin, tsconfig paths, and jest-dom matchers.
   - One smoke test that renders the home page and asserts the `<h1>`.
   - Scripts: `lint`, `typecheck` (`tsc --noEmit`), `test` (`vitest run`), `test:watch`, and `check` running lint, typecheck, then test.
   - Run `pnpm check` and `pnpm build`; fix until green.

6. **Docs.**
   - `AGENTS.md`: purpose, stack table, commands, and conventions (build by addition, add shadcn components through the CLI, server-only secrets stay out of client code, new features ship with a test, `pnpm check` before commit). Under ~60 lines. Symlink `CLAUDE.md` to it.
   - `README.md`: 8th-grade reading level. What it is, what it does, how to run it, and how to check it. No badges or empty sections.
   - `CHANGELOG.md`: `# Changelog` header, then `## [0.1.0] - <today>` with `### Features` listing "Initial project setup".

7. **Ship it.**
   - Commit, then `gh repo create jcottam/<name> --private --source=. --push`.
   - Add `.github/workflows/check.yml` that runs `pnpm check` on push and pull request.
   - `vercel link` and connect the Git repo. Confirm the first deployment succeeds.

8. **Report** the repo URL, the deployment URL, the `pnpm check` result, the resolved versions of Next.js, React, Tailwind, and shadcn, and any assumptions or skipped steps.

## Adding blocks later

When a feature needs Supabase, Resend, Cloudflare, or anything new, follow the provider's current docs, then:

- Add new variables to `.env.example` and to Vercel by hand (`vercel env add`).
- Keep secrets in server-only modules.
- Add at least one test for the new code path.
- Note it in the AGENTS.md stack table and, if it changes setup, the README.
- Run `pnpm check`.

Two choices need judgment:

- **AI:** call models through the AI SDK with AI Gateway model strings (`provider/model`) instead of installing provider SDKs one by one. On Vercel, auth comes from OIDC (`vercel env pull` locally); use `AI_GATEWAY_API_KEY` only outside Vercel.
- **Storage:** start with Vercel Blob. Move to R2 when files are large or numerous, egress cost matters, or you need S3-compatible APIs, bucket policies, or access from outside Vercel. Keep storage behind one small module so the swap touches one file.
