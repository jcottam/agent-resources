# Agent Resources

Battle-tested agent skills and Cursor rules from real projects. Works with Cursor, Claude Code, and any agent.

## What's Inside

- **Skills** -- Repeatable workflows your agent can follow (`SKILL.md` files)
- **Rules** -- Persistent context for Cursor sessions (`.mdc` files)

## Quickstart

### Install all skills

| Platform | Command |
|----------|---------|
| Cursor / npx | `npx skills@latest add jcottam/agent-resources` |
| Claude Code | `/plugin marketplace add jcottam/agent-resources` then `/plugin install agent-resources` |

### Install a single skill

| Platform | Command |
|----------|---------|
| Cursor / npx | `npx skills@latest add jcottam/agent-resources/ship` |
| Manual (any agent) | Copy `SKILL.md` into `~/.cursor/skills/<skill-name>/` |

## Skills

### Engineering

| Skill | Description |
|-------|-------------|
| [ship](./skills/engineering/ship/SKILL.md) | Validate a branch, run quality gates, update documentation and changelog, and open a pull request. |

---

## Rules

Cursor rules (`.mdc` files) will be added to the `rules/` directory over time. See the [rules README](./rules/README.md) for format and installation instructions.

## Resources

Other skills and tools worth checking out.

| Resource | Description |
|----------|-------------|
| [skills.sh](https://skills.sh) | Registry and CLI for discovering, installing, and managing agent skills. |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Engineering and productivity skills for real development -- TDD, diagnosis, grilling, and more. |
| [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | Behavioral guidelines derived from Karpathy's observations on LLM coding pitfalls. |
| [garrytan/gstack](https://github.com/garrytan/gstack) | 23 opinionated tools that serve as CEO, Designer, Eng Manager, Release Manager, and QA. |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Design language that makes your AI better at design. |
| [squirrelscan/squirrelscan](https://github.com/squirrelscan/squirrelscan) | Website auditing tool built for agent and LLM workflows. |

## Contributing

### Add a skill

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
3. Add a row to the skills table in this README.

### Add a rule

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

2. Add the rule to `rules/README.md`.

## License

[MIT](./LICENSE)
