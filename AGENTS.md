# Agent Resources

This repository contains agent skills and Cursor rules.

## Contributing

- Skills live in `skills/<category>/<skill-name>/SKILL.md`.
- Each `SKILL.md` has YAML frontmatter with `name` and `description`, followed by the skill body in markdown.
- When adding a skill, also add it to `.claude-plugin/plugin.json` and the reference table in `README.md`.
- Rules live in `rules/` as `.mdc` files with YAML frontmatter (`description`, `globs`, `alwaysApply`).
- Keep skills focused on a single concern. Prefer short, composable skills over large monolithic ones.
