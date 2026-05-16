---
name: publish
description: >-
  Upload files to Cloudflare R2 and return a shareable public URL. Supports any
  file type (HTML, images, PDFs, etc.) with automatic slug generation, clipboard
  copy, and publish history tracking. Use when the user says "publish",
  "publish this", "share this file", "upload to R2", "make this public",
  "get a shareable link", "host this", "deploy this file", "put this online",
  or any variation of wanting to make a file publicly accessible via URL.
license: MIT
metadata:
  author: jcottam
  version: "1.0.0"
---

# Publish

Upload any file to Cloudflare R2 and get back a shareable public URL.

`SCRIPTS` below refers to the `scripts/` directory next to this file.

## Prerequisites

- **Node.js** (for `npx wrangler`)
- **Cloudflare account** with an R2 bucket that has public access enabled
- **Wrangler auth** via one of:
  - `wrangler login` (interactive OAuth -- run once, persists in `~/.wrangler`)
  - `CLOUDFLARE_API_TOKEN` environment variable

## Step 1 — Check configuration

Look for `~/.publish.json`. If it doesn't exist, run `$SCRIPTS/setup.sh` and walk the user through the prompts. The setup script creates the config file with:

```json
{
  "bucket": "my-bucket-name",
  "publicBaseUrl": "https://pub-xxx.r2.dev"
}
```

If the file exists, read it and parse the `bucket` and `publicBaseUrl` values. Both are required.

## Step 2 — Identify the asset

Determine what file to publish from context:

1. If the user specified a file path, use that.
2. If the user said "publish this" without a path, check for:
   - A file the user is currently viewing or recently created
   - A `.canvas.tsx` output or generated HTML file from the current session
3. Verify the file exists before proceeding. If ambiguous, ask the user to clarify.

## Step 3 — Generate the key

Decide the R2 object key (the path within the bucket):

- **Default**: derive a readable slug from the filename.
  - Strip extension, lowercase, replace spaces and special characters with hyphens
  - Append today's date: `my-report-2026-05-15`
  - Re-attach the original file extension
  - Example: `Sales Report Q1.html` becomes `sales-report-q1-2026-05-15.html`
- **User override**: if the user provided a custom name, use it instead (sanitized).
- **Collision check**: scan `~/.publish-history.json` for the key. If it exists, ask the user whether to overwrite or append a suffix (`-2`, `-3`, etc.).

## Step 4 — Publish

Run the publish script:

```bash
$SCRIPTS/publish.sh <file-path> [--key <custom-key>]
```

The script:
1. Reads `~/.publish.json` for bucket name and public URL base
2. Detects the content type from the file extension
3. Uploads via `npx wrangler r2 object put <bucket>/<key> --file <path> --content-type <type>`
4. Constructs the public URL: `<publicBaseUrl>/<key>`
5. Copies the URL to the clipboard (`pbcopy` on macOS, `xclip`/`xsel` on Linux)
6. Appends an entry to `~/.publish-history.json`
7. Outputs JSON with `url`, `key`, `contentType`, `size`, and `publishedAt`

If the script exits non-zero, report the error to the user. Common issues:
- **Not authenticated**: suggest running `wrangler login` or setting `CLOUDFLARE_API_TOKEN`
- **Bucket not found**: confirm the bucket name in `~/.publish.json` and that public access is enabled
- **File not found**: re-check the file path

## Step 5 — Report

After a successful publish:

1. Print the public URL prominently.
2. Confirm the URL was copied to the clipboard.
3. Mention the entry was added to publish history.

Example output:

```
Published: https://pub-xxx.r2.dev/sales-report-q1-2026-05-15.html
Copied to clipboard.
```

## Publish history

Use `$SCRIPTS/history.sh` to interact with the local publish history at `~/.publish-history.json`.

| Command | Description |
|---------|-------------|
| `history.sh list` | Show the 10 most recent publishes |
| `history.sh list --all` | Show all publishes |
| `history.sh search <query>` | Filter entries by key or local path |
| `history.sh prune` | Remove entries whose R2 objects no longer exist |

When the user asks to see their publish history, list recent uploads, or find a previously published file, use the appropriate history command.

## Custom domains

For setting up a custom domain instead of the default `r2.dev` URL, see [references/custom-domain.md](references/custom-domain.md).
