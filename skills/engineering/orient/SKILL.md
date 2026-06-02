---
name: orient
description: >-
  Orient a developer to an unfamiliar codebase by systematically exploring its
  structure, purpose, features, conventions, and workflows. Produces a concise
  orientation document. Use when the user says "orient me", "what does this
  project do", "walk me through this codebase", "help me understand this repo",
  "onboard me", "give me the lay of the land", "codebase overview", or any
  variation of wanting to quickly understand a project they're new to.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Orient

Systematically explore a codebase and produce a structured orientation that
tells a developer everything they need to start working productively. Depth
scales with project size — small projects get a tight summary, large projects
get a layered map.

## Phase 1 — Project Identity

Establish what the project *is* before reading any source code.

### Read top-level files (in order of priority)

1. `README.md` / `README` — stated purpose, setup instructions, feature list
2. `AGENTS.md` — architecture boundaries, "always do / never do" rules
3. `.cursor/rules/` — workspace conventions for this project
4. Manifest file — `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
   `pom.xml`, `Gemfile`, `composer.json`, or equivalent
5. `CONTRIBUTING.md`, `ARCHITECTURE.md`, `docs/` index — if present

### Extract

- **One-sentence purpose**: What does this project do, for whom?
- **Domain**: What problem space does it operate in?
- **Stage**: Early build, growth, or mature/stable?
- **Key dependencies**: Frameworks, databases, external services

If the README is absent or unhelpful, infer purpose from the manifest
description field, directory names, and import patterns.

## Phase 2 — Shape

Map the physical layout without reading file contents yet.

```bash
# Get directory tree (depth 2–3 depending on project size)
find . -type f | head -200
# or
tree -L 3 -I 'node_modules|.git|dist|build|__pycache__|venv|.venv|target'
```

### Categorize top-level directories

| Role | Common names | What to look for |
|------|-------------|------------------|
| Source | `src/`, `lib/`, `app/`, `pkg/`, `internal/` | Production code |
| Tests | `test/`, `tests/`, `spec/`, `__tests__/` | Test suites |
| Config | Root dotfiles, `config/`, `.github/` | Build/CI/lint config |
| Docs | `docs/`, `doc/`, `wiki/` | Documentation |
| Infra | `infra/`, `deploy/`, `terraform/`, `k8s/`, `docker/` | Deployment |
| Scripts | `scripts/`, `bin/`, `tools/` | Automation helpers |
| Generated | `dist/`, `build/`, `out/`, `target/` | Build artifacts (skip) |

### Identify the tech stack

From manifest files and directory structure, determine:
- Language(s) and version constraints
- Framework(s) — web, CLI, library, monorepo tooling
- Database / storage layer
- Build system and package manager
- CI/CD platform (from `.github/workflows/`, `.gitlab-ci.yml`, etc.)

## Phase 3 — Architecture

Now read code — but strategically. The goal is to understand the skeleton, not
every function.

### Scaling strategy

| Project size | Approach |
|--------------|----------|
| **Small** (≤20 files) | Read every source file. Full picture is cheap. |
| **Medium** (21–100 files) | Read entry points + 3–5 core modules. Skim the rest by name/export. |
| **Large** (>100 files) | Read entry points, trace one request/command end-to-end, read the 5 highest-import-count modules. |

### Find entry points

Look for:
- `main.ts`, `index.ts`, `app.ts`, `server.ts` — web/API entry
- `main.py`, `app.py`, `__main__.py`, `manage.py` — Python entry
- `main.go`, `cmd/` — Go entry
- `src/main.rs`, `src/lib.rs` — Rust entry
- `bin/` scripts, CLI definitions
- `package.json` `"main"`, `"bin"`, `"exports"` fields
- Framework-specific: `pages/`, `app/` (Next.js), `routes/` (Express/Rails)

### Trace the skeleton

From entry points, follow the import graph to identify:
- **Core modules** — where the main logic lives
- **Data layer** — models, schemas, database access
- **API surface** — routes, handlers, controllers, exported functions
- **Shared utilities** — helpers used across modules
- **Configuration** — how settings flow into the system

Read 3–5 pivotal files fully to understand the primary abstraction patterns.

### Identify boundaries

- Monorepo packages / workspaces
- Service boundaries (if microservices)
- Plugin / extension points
- Public API vs internal implementation

## Phase 4 — Features and Functionality

Shift from code structure to user/consumer perspective.

### For applications (web, CLI, desktop)

Enumerate:
- User-facing features (routes, pages, commands)
- Authentication / authorization model
- Data inputs and outputs
- Background jobs, workers, scheduled tasks
- External integrations (APIs, webhooks, third-party services)

### For libraries / SDKs

Enumerate:
- Public exports and their purpose
- Primary use cases (from README examples or test files)
- Extension points (plugins, middleware, hooks)
- Versioning / compatibility guarantees

### For infrastructure / tooling

Enumerate:
- What it provisions or manages
- Configuration surface (env vars, config files, CLI flags)
- Operational commands (deploy, rollback, scale)

## Phase 5 — Conventions and Patterns

Extract the implicit rules that make contributions consistent.

### Look for

- **Naming**: File naming (kebab, camel, pascal), variable/function style
- **Code organization**: Feature-based vs layer-based, barrel exports
- **Error handling**: Custom error types, Result patterns, try/catch strategy
- **Testing**: Unit vs integration split, fixture patterns, mocking approach
- **State management**: Where state lives, how it flows
- **Type patterns**: Strict vs loose typing, shared type definitions
- **Logging / observability**: Structured logging, tracing, metrics

### Sources of truth (in priority order)

1. `AGENTS.md` explicit rules
2. `.cursor/rules/` files
3. Linter/formatter config (`.eslintrc`, `prettier`, `ruff.toml`, `clippy`)
4. Existing code patterns (what the majority of files actually do)

When explicit rules conflict with existing code, note the discrepancy.

## Phase 6 — Developer Workflows

Document the practical "how do I..." answers.

### Essential workflows to cover

| Workflow | Where to find it |
|----------|-----------------|
| Install dependencies | README, manifest lockfile presence |
| Run locally | README, `scripts` in package.json, `Makefile`, `docker-compose.yml` |
| Run tests | `test` script, CI config, test framework config |
| Build / compile | `build` script, build tool config |
| Lint / format | `lint` script, pre-commit hooks, editor config |
| Deploy | CI/CD config, deploy scripts, `infra/` directory |
| Add a new feature | CONTRIBUTING.md, existing PR patterns |

### Environment setup

Note any required:
- Environment variables (from `.env.example`, `.env.template`, docs)
- External services (databases, queues, caches)
- System-level dependencies (specific runtime versions, native libs)

## Output

Present findings as a structured orientation document. Adapt depth to what the
project warrants — a 10-file CLI tool does not need the same treatment as a
200-file web platform.

### Format

```markdown
# [Project Name] — Orientation

## What this project does
[One paragraph: purpose, domain, users/consumers, stage]

## Tech stack
[Language, framework, database, key dependencies — bullet list]

## Project structure
[Directory map with role annotations — only meaningful directories]

## Architecture
[How components connect. Entry points → core logic → data layer.
Include a brief data flow description for the primary use case.]

## Key features
[Bulleted list of what the project does from a user/consumer perspective]

## Conventions
[Naming, patterns, testing approach, error handling — the implicit rules]

## Developer workflows
[How to: install, run, test, build, deploy — with actual commands]

## Caveats and gotchas
[Anything surprising, non-obvious, or likely to trip up a new contributor]
```

### Adaptation rules

- **Skip empty sections.** If there's no infra directory, don't fabricate a
  deployment section.
- **Flag unknowns.** If something is unclear from the code alone, say so
  rather than guessing.
- **Prioritize actionability.** A new developer should be able to start
  working after reading this.
- **Keep it concise.** Target 1–2 pages for small projects, 3–4 for large
  ones. Link to existing docs rather than reproducing them.

## Principles

- Read before you conclude. Every claim about the project should be grounded
  in something you actually read, not inferred from the name.
- Shape before depth. Understand the map before zooming into any territory.
- User perspective matters. Features are what the project does, not how the
  code is organized.
- Flag, don't fabricate. If the README is stale or docs are missing, say so.
- Respect existing documentation. Point to it rather than restating it when
  it's accurate and current.
