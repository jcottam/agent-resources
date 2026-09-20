---
name: promote-skill
description: >-
  Move a tested personal agent skill into a shared skills repository, check for
  overlap, normalize metadata, update the catalog and release files, validate
  the package, and publish it through a reviewable branch. Use when the user
  asks to promote, publish, share, or contribute a global skill.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Promote Skill

Promote a tested personal skill into a shared repository without creating
duplicate skills or losing its working version.

## Required inputs

Identify:

- The source skill directory
- The destination repository
- The destination category
- The repository's default branch and contribution rules

Personal skills commonly live in `~/.cursor/skills/` or `~/.agents/skills/`.
Read the destination repository's `AGENTS.md`, `CONTRIBUTING.md`, and existing
skill examples before making changes.

## 1. Check for overlap

Search personal and repository skills by:

- Skill name
- Description and trigger phrases
- Main workflow steps
- Commands and safety rules

Classify similar skills as:

- **Duplicate**: same purpose and workflow
- **Extension**: one skill is a more complete version of another
- **Adjacent**: related but has a different outcome

Recommend merging or replacing duplicates. Keep adjacent skills separate with
clear trigger boundaries. Get the user's approval before changing the proposed
publication set.

## 2. Prepare the repository

Start from an updated default branch and create a focused feature branch:

```bash
git fetch origin
git checkout <default-branch>
git pull --ff-only origin <default-branch>
git checkout -b feature/add-<skill-name>-skill
```

Do not work directly on the default branch unless the user explicitly asks.

## 3. Normalize the skill

Copy the complete skill directory, including needed scripts, references, and
assets, into:

```text
skills/<category>/<skill-name>/
```

Use repository metadata conventions. For Agent Resources:

```yaml
---
name: skill-name
description: What the skill does and when it should trigger.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---
```

Keep `SKILL.md` focused and under 500 lines. Remove machine-specific paths,
secrets, temporary files, and private project details.

## 4. Update release files

Update every catalog used by the destination repository:

- Add the skill path to `.claude-plugin/plugin.json`
- Add the skill to the correct table in `README.md`
- Add a new entry to `CHANGELOG.json`

Use the plugin manifest version as the release source of truth:

- Patch: fixes only
- Minor: new skills or improvements
- Major: breaking changes

The newest changelog version must match the plugin manifest version. Keep skill
versions independent in each skill's metadata.

## 5. Validate

Check all of the following:

- YAML frontmatter parses and contains required metadata
- The directory name matches the skill name
- `plugin.json` is valid JSON
- The plugin skills array has no duplicate paths
- Every listed skill path exists
- The README link points to the new `SKILL.md`
- Referenced scripts and files exist
- No secrets or personal project data are included
- The working tree contains only intended changes

Run repository checks when available. Review the final diff before publishing.

## 6. Publish

Commit with a concise message, push the feature branch, and open a pull request
that lists:

- Skills added or replaced
- Overlap decisions
- Version changes
- Validation performed

Do not delete the personal source skill until the repository change is merged
and the installed repository version is confirmed.

## Final report

Report:

- Published skill path
- Replaced or retired skills
- Manifest and changelog version
- Validation results
- Pull request URL
- Any local cleanup still needed
