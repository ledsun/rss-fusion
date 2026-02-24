---
name: rss-fusion-blacklist-maintainer
description: Maintain the blacklist prefix list for the rss-fusion project (`blacklist.txt`). Use when adding/removing/sorting Qiita or other URL prefixes, deduplicating rules, showing the current blacklist, and optionally committing/pushing blacklist updates.
---

# Rss Fusion Blacklist Maintainer

## Overview

Update `blacklist.txt` safely and consistently for this repository.
Add URL prefixes, ignore duplicates, keep rules sorted, preserve the comment header, and commit/push only when requested.

## Workflow

1. Read the current `blacklist.txt`.
2. Normalize requested prefixes (trim spaces, keep exact prefix semantics).
3. Merge with existing rules without duplicates.
4. Sort rules lexicographically while keeping the comment line at the top.
5. Write the updated file.
6. Show the resulting blacklist (or summarize changes).
7. Commit and push only if the user explicitly asks.

## File Rules

- Target file: `blacklist.txt`
- Format: one prefix per line
- Ignore empty lines and comment lines beginning with `#`
- Matching semantics in the app are prefix match (`start_with?`), so do not rewrite user-provided prefixes unless asked
- Preserve the header comment if present:
  - `# Prefix blacklist rules (one per line)`

## Add Prefixes

When the user asks to add blacklist entries:

1. Read `blacklist.txt`.
2. Compare requested prefixes against existing entries using exact string equality.
3. Add only missing prefixes.
4. Re-sort the rule lines.
5. Report what was added vs already present.

## Show / Sort Only

When the user asks to "show current blacklist" or "sort":

1. Print the current file contents (`cat blacklist.txt`) for show requests.
2. For sort requests, sort only the rule lines and keep the comment header at top.
3. Avoid changing semantics (no prefix normalization) unless requested.

## Commit / Push Behavior

- Commit only when the user explicitly asks.
- Use a concise commit message describing the blacklist change.
- Push only when the user explicitly asks.
- After push, optionally confirm the GitHub Actions run status if requested.

## Common Commands

Use simple shell commands and `apply_patch`; prefer exact edits over scripting for small changes.

- Show file:
  - `cat blacklist.txt`
- Commit blacklist changes:
  - `git add blacklist.txt`
  - `git commit -m "Update blacklist prefixes"`
- Push:
  - `git push origin main`

## Example User Requests

- "ブラックリストに `https://qiita.com/example-user` を追加して"
- "現在のブラックリストを見せて"
- "ブラックリストをソートして"
- "追加して、コミットして、push して"
