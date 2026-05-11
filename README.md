# Agent Resources

Agent skills and Cursor rules I use for real engineering work. Small, composable, and platform-agnostic.

## Quickstart

### Install all skills

**Cursor / npx:**

```bash
npx skills@latest add jcottam/agent-resources
```

**Claude Code:**

```bash
/plugin marketplace add jcottam/agent-resources
/plugin install agent-resources
```

### Install a single skill

**Cursor / npx:**

```bash
npx skills@latest add jcottam/agent-resources/ship
```

**Manual (any agent):**

Copy the `SKILL.md` file from any skill directory into your agent's skill directory (e.g. `~/.cursor/skills/<skill-name>/SKILL.md`).

## Skills

### Engineering

Skills for daily code work.

- **[ship](./skills/engineering/ship/SKILL.md)** -- Validate a branch, run quality gates, update documentation and changelog, and open a pull request. Use when you say "ship", "open a PR", or "let's ship it".

## Rules

Cursor rules (`.mdc` files) will be added to the `rules/` directory over time. See the [rules README](./rules/README.md) for format and installation instructions.

## Adding a new skill

1. Create `skills/<category>/<skill-name>/SKILL.md` with YAML frontmatter:

```markdown
---
name: my-skill
description: One-liner explaining when to use this skill.
---

# My Skill

Skill instructions here...
```

2. Add the skill path to `.claude-plugin/plugin.json` in the `skills` array.
3. Add a one-liner to the reference table in this README.

## Adding a new rule

1. Create `rules/<rule-name>.mdc` with YAML frontmatter:

```markdown
---
description: What this rule enforces
globs: **/*.ts
alwaysApply: false
---

# Rule Title

Rule content here...
```

2. Update `rules/README.md` with the new rule.

## License

[MIT](./LICENSE)
