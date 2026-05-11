# Cursor Rules

Cursor rules provide persistent context to the AI agent when working in a project. Rules are `.mdc` files with YAML frontmatter that control when and how they apply.

## Format

Each rule is a `.mdc` file with the following structure:

```markdown
---
description: What this rule enforces or teaches
globs: **/*.ts
alwaysApply: false
---

# Rule Title

Rule content here...
```

### Frontmatter fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | What the rule does (shown in the Cursor rule picker) |
| `globs` | string | File pattern -- rule applies when matching files are open |
| `alwaysApply` | boolean | If `true`, applies to every session regardless of open files |

## Installation

Copy any `.mdc` file from this directory into your project's `.cursor/rules/` directory:

```bash
cp rules/<rule-name>.mdc /path/to/your/project/.cursor/rules/
```

For global rules that apply across all projects, copy to `~/.cursor/rules/`.

## Available Rules

*Rules will be added here as they are created.*
