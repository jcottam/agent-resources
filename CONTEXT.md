# Agent Resources

A collection of agent skills and Cursor rules for coding agents.

## Language

**Skill**:
A markdown file (`SKILL.md`) with YAML frontmatter (`name`, `description`) that teaches an agent a repeatable behavior or workflow. Skills are platform-agnostic and work with Cursor, Claude Code, and other agents.

**Rule**:
A Cursor project rule (`.mdc` file) with YAML frontmatter (`description`, `globs`, `alwaysApply`) that provides persistent context to the AI agent. Rules are Cursor-specific.

**Category**:
A grouping directory under `skills/` (e.g. `engineering`, `productivity`) that organizes related skills.

## Relationships

- A **Category** contains one or more **Skills**
- A **Skill** belongs to exactly one **Category**
- **Rules** are independent of categories and live flat under `rules/`
