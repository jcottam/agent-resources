---
name: cleanup-harden
description: Runs a cleanup and hardening pass on an application or website covering security fixes, DRY consolidation, orphan and dead-code removal, doc drift, dependency audit, error handling, config validation, performance, and repo hygiene, without changing user-facing behavior. Use when the user asks to clean up, prune, harden, audit, tidy, or de-cruft a codebase, remove dead code, fix doc drift, or do a security pass.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Cleanup & Hardening Pass

Make the repository smaller, safer, and more accurate without changing behavior users rely on.

## Scope

If the user named a scope (paths, categories, or "security only"), limit the pass to it. Otherwise run every category in order. For large codebases, finish and report security first, then continue.

## Ground rules

- **Learn the project first.** Read README, AGENTS.md / CONTRIBUTING, the package manifest, CI config, and entry points. Find the lint, typecheck, test, and build commands and run them for a baseline. Record checks that already fail.
- **Preserve behavior.** Public APIs, routes, response shapes, env var names, CLI flags, and URLs stay the same unless a security fix requires otherwise. Flag any breaking change explicitly.
- **Prove before deleting.** Search the whole repo for references: string usage, dynamic imports, config, CI, scripts, docs, tests, and framework conventions (file-based routing, magic filenames, decorators, plugin registries). If uncertain, list it as a candidate instead of deleting.
- **Small, reviewable changes.** One category per commit when committing. Don't reformat untouched code.
- **Match existing style.** Same naming, error handling, and import conventions. No speculative abstractions.
- **Verify after each category.** Rerun checks; fix or revert regressions before moving on.
- **Never** push, deploy, force-push, or rewrite git history.

## Progress checklist

```
- [ ] 0. Baseline: read docs, run lint/typecheck/test/build
- [ ] 1. Security
- [ ] 2. DRY consolidation
- [ ] 3. Orphan cleanup
- [ ] 4. Doc drift
- [ ] 5. Other pruning and hardening
- [ ] 6. Final verification and report
```

## 1. Security

Fix confirmed issues. List anything needing a product decision instead of guessing.

- **Secrets:** hardcoded keys, tokens, passwords in code, tests, fixtures, docs, tracked `.env` files. Check `.gitignore`. Flag secrets that need rotation; deleting doesn't remove them from history.
- **AuthN/AuthZ:** every protected route or page is actually protected. Look for missing checks, IDOR (reaching another user's records by changing an ID), and admin/debug endpoints exposed in production.
- **Input handling:** validation at the boundary; SQL/NoSQL/command injection, path traversal, unsafe deserialization, `eval` / dynamic `Function`.
- **Outbound requests:** caller-supplied URLs must block private and metadata addresses, re-check redirects, and cap size and time (SSRF).
- **Web:** XSS (raw HTML, `dangerouslySetInnerHTML`, unescaped templates), CSRF, open redirects, permissive CORS, missing headers (CSP, HSTS, X-Content-Type-Options, Referrer-Policy, frame-ancestors).
- **Information leaks:** stack traces, raw upstream errors, internal paths, or secrets in responses, logs, or telemetry. Logs redact tokens, cookies, and bodies.
- **Uploads/files:** content-type and size limits, filename sanitization, safe `Content-Type` / `Content-Disposition` when serving user content.
- **Abuse:** rate limits and timeouts on expensive or unauthenticated endpoints.
- **Dependencies:** run the ecosystem audit (`npm audit`, `bun audit`, `pnpm audit`, `pip-audit`, `cargo audit`, etc.). Apply safe patch/minor upgrades; list majors separately.
- **CI/CD:** pinned third-party actions, least-privilege tokens, no secrets exposed to fork PRs.

Add a regression test for each security fix where the project has tests.

## 2. DRY consolidation

- Find duplicated or near-duplicated logic: validation, error formatting, fetch/retry wrappers, parsing, constants, types, config loading.
- Merge only when copies mean the same thing. Code that looks alike but changes for different reasons stays separate.
- Put shared code where the project already keeps shared code; update every caller.
- Name magic numbers and repeated strings that appear three or more times.

## 3. Orphan cleanup

Delete once proven dead:

- unimported files, modules, components, routes, assets
- unused exports, types, constants; unreachable branches
- manifest dependencies never imported, and imported packages missing from the manifest
- stale scripts, configs for tools no longer used, unreferenced migrations/fixtures, committed build output
- commented-out code, dead feature flags, permanently-on/off flag branches
- tests for deleted code; skipped tests with no explanation

Use tooling when available (`knip`, `ts-prune`, `depcheck`, `vulture`, `cargo udeps`, etc.) but confirm each result manually.

## 4. Doc drift

- Compare README, AGENTS.md, API docs / OpenAPI, `.env.example`, and inline docs against the code: endpoints, parameters, defaults, env vars, commands, ports, deploy steps.
- Fix documented-but-gone and real-but-undocumented items. `.env.example` lists exactly the variables the code reads.
- Remove docs for removed features. Fix broken links and relative paths.
- Delete comments that restate code or narrate history. Keep comments stating constraints the code can't show.

## 5. Other pruning and hardening

- **Error handling:** no empty `catch` or swallowed promises; consistent error shapes and status codes; graceful shutdown.
- **Config:** validate required env vars at startup with a clear message; no unsafe production defaults.
- **Types/lint:** remove unjustified `any`, `@ts-ignore`, lint-disable comments; enable stricter settings when cheap.
- **Performance:** N+1 queries, unbounded loops/pagination, missing outbound timeouts, heavy sync work on hot paths, obvious missing caching, oversized bundles/images.
- **Websites:** meta/OG tags, `robots.txt` and sitemap accuracy, broken internal links, accessibility basics (alt text, labels, contrast, focus), dead CSS.
- **Tests:** cover consolidated helpers that lacked coverage.
- **Repo hygiene:** `.gitignore` gaps, large binaries, conflicting lockfiles, stale references in docs.

## 6. Report

Finish with this structure:

```markdown
## Summary
[What changed, net lines removed]

## Security
- [file] — [severity] — [issue and what an attacker could have done] — fixed
### Needs human action
- [secret rotation, infra change, product decision]

## Changes by category
- Consolidated: ...
- Deleted: ...
- Docs updated: ...
- Hardening: ...

## Not done
- [candidate or refactor] — [reason: couldn't prove dead / risky / major upgrade]

## Verification
| Check | Before | After |
|-------|--------|-------|
| lint | | |
| typecheck | | |
| test | | |
| build | | |
```
