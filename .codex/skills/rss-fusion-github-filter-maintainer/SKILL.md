---
name: rss-fusion-github-filter-maintainer
description: Maintain rss-fusion GitHub release unstable filters in `lib/filter/github_release_filter.rb`. Use when adding/removing unstable tag keywords (e.g. `rust-`, `alpha`, `nightly`), updating related tests, and optionally committing/pushing changes.
---

# Rss Fusion Github Filter Maintainer

## Overview

Update GitHub release unstable filter rules safely and consistently.
Keep `UNSTABLE_PATTERN` aligned with test expectations and validate behavior with Minitest.

## Workflow

1. Read `lib/filter/github_release_filter.rb` and `test/github_release_filter_test.rb`.
2. Confirm requested keyword changes for unstable tag detection.
3. Update `UNSTABLE_PATTERN` in `GithubReleaseFilter`.
4. Update/add tests so new behavior is explicitly covered.
5. Run focused tests for GitHub release filtering.
6. Optionally run full test suite when requested or when changes may affect broader behavior.
7. Commit and push only if explicitly requested.

## File Rules

- Main target: `lib/filter/github_release_filter.rb`
- Test target: `test/github_release_filter_test.rb`
- Keep matching semantics as substring check via regex on GitHub URLs.
- Keep the GitHub URL prefix guard (`https://github.com/`) intact unless the user asks to change scope.
- Update inline comments when filter semantics change.

## Add/Remove Keywords

When user asks to add/remove a GitHub filter keyword:

1. Inspect current `UNSTABLE_PATTERN`.
2. Apply exact requested keyword change without unrelated refactors.
3. Ensure tests cover:
   - positive case for the keyword (unstable)
   - at least one stable GitHub release tag
   - non-GitHub URL guard behavior
4. Report what changed and what was already present.

## Validation Commands

- Focused tests:
  - `ruby test/github_release_filter_test.rb`
- Full tests:
  - `ruby test/all.rb`

## Commit / Push Behavior

- Commit only when explicitly requested.
- Use concise commit messages describing filter updates.
- Push only when explicitly requested.

## Example User Requests

- "GitHub Filterに`rust-`を追加して"
- "unstable判定から`pre`を外して"
- "GitHub Release filterのキーワードを更新してテストして"
- "このfilter変更をcommitしてpushして"
