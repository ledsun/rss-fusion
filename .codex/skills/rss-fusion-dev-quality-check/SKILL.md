---
name: rss-fusion-dev-quality-check
description: Run local test/lint checks for rss-fusion safely. Use when reviewing commits, validating local changes, running Minitest or RuboCop, and keeping RuboCop cache at the default `.rubocop_cache/`.
---

# Rss Fusion Dev Quality Check

## Overview

Run local quality checks for this repository and keep temporary artifacts inside `tmp/`.

## Workflow

1. Check git status and identify changed files.
2. Run focused tests for changed areas when possible.
3. Run full test suite.
4. Run RuboCop.
5. Report failures with concrete file/line references and next actions.

## Commands

- Full tests:
  - `bundle exec ruby -Itest test/all.rb`
- Focused test example:
  - `bundle exec ruby -Itest test/feed_source_test.rb`
- RuboCop:
  - `bundle exec rubocop`

## RuboCop Cache Policy

- Use RuboCop default cache path: `.rubocop_cache/`.
- `.rubocop_cache/` is gitignored; never commit cache files.

## Review Checklist

- Confirm tests pass before concluding review.
- Confirm RuboCop passes before concluding review.
- If checks fail, include:
  1. failing command
  2. concise error summary
  3. concrete fix location

## Example User Requests

- "未pushコミットの修正をレビューして"
- "この変更でテストとlint回して"
- "RuboCopの失敗を再現して原因見て"
