---
name: squash-branch
description: >-
  Review commits in a branch, date range, or recent history; group related work
  into a clean linear history; and verify that the final tree is unchanged. Use
  when the user asks to squash commits, clean Git history, combine WIP commits,
  organize today's commits, or prepare a readable commit stack.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Squash Branch

Turn noisy Git history into a small, reviewable commit stack without changing
the final code.

## Workflow

1. Define the commit range.
2. Review each commit's purpose and files.
3. Group related commits.
4. Create a backup branch.
5. Rebuild the commits.
6. Compare the rebuilt tree with the backup.
7. Run the project's tests and build.
8. Push with `--force-with-lease`.

## 1. Define the range

Use the range named by the user:

- Feature branch: `<base>..HEAD`
- Since a commit or tag: `<ref>..HEAD`
- Today's work: commits since local midnight
- Recent work: the requested number of commits

Confirm the current branch, working tree, remote, and selected base before
changing history.

If there are uncommitted changes, commit them only when the user asks. Otherwise,
ask whether to commit or stash them.

## 2. Review the commits

Read the log, messages, and file statistics:

```bash
git log <range> --reverse --format="%H %s%n%b---"
git diff <base>...HEAD --stat
git show --stat <sha>
```

Group commits by purpose. Combine fixups, tests, documentation, and polish with
the change they support. Keep unrelated features, infrastructure changes, and
reverts separate.

Prefer a few clear commits, but do not force unrelated work into an arbitrary
commit count.

## 3. Create a backup

```bash
git branch backup/<branch>-<date> HEAD
```

Record the original tip and base commit. The backup protects the exact tree
while history is rebuilt.

## 4. Rebuild the history

Reset to the base only after the backup exists:

```bash
git reset --hard <base>
```

For contiguous groups, restore the tree at each group's tip:

```bash
git read-tree -u --reset <group-tip>
git commit -m "<clear subject>" -m "<why this group exists>"
```

For non-contiguous groups, apply the selected commits without committing, then
create one new commit:

```bash
git cherry-pick -n <sha-1> <sha-2> <sha-3>
git commit -m "<clear subject>" -m "<why this group exists>"
```

Keep commits in their original order unless reordering is required to form a
logical group. Stop and report conflicts rather than guessing how to resolve
them.

Do not use `git checkout <sha> -- .` to restore a full tree. It can leave files
that later commits deleted.

## 5. Verify

The rebuilt tree must exactly match the backup:

```bash
git diff --exit-code backup/<branch>-<date> HEAD
git log <base>..HEAD --oneline
git status --short
```

Run the repository's normal quality gates. Include tests and a production build
when available.

If the tree differs or a quality gate fails, do not push.

## 6. Push safely

Rewriting `main` or `master` requires clear user approval. Warn that other
checkouts may need to reset after the push.

```bash
git push --force-with-lease origin <branch>
```

Never use a plain `--force` push. Delete the backup only after verification and
the push both succeed.

## Commit messages

- Use an imperative subject of 72 characters or fewer.
- Explain why the group exists in one or two body sentences.
- Do not list every changed file.

## Final report

Report:

- The old and new commit counts
- The new commit list
- Quality gates and their results
- The pushed branch
- Any reset command collaborators may need
