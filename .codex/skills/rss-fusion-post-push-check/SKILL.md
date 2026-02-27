---
name: rss-fusion-post-push-check
description: Verify rss-fusion deployment after pushing to `main`. Use when checking the latest GitHub Actions run status, build/deploy job results, tests/lint workflow results, GitHub Pages availability, and whether `merged.xml` is publicly updated after a push.
---

# Rss Fusion Post Push Check

## Overview

Run the standard post-push verification flow for this repository.
Confirm that GitHub Actions completed successfully (both deploy and tests/lint workflows) and GitHub Pages is serving the updated `merged.xml`.

## Workflow

1. Confirm the push succeeded (if not already shown by the session).
2. Inspect the latest `push` runs for both target workflows.
3. Watch the runs until completion.
4. If any run fails, inspect failing step/logs and report the concrete cause.
5. If both runs succeed, confirm Pages URL and fetch `merged.xml` (or at least its header) to verify public output.

## Repository-Specific Targets

- Workflow names:
  - `Build and Deploy Merged RSS`
  - `Run Tests and Lint`
- Branch: `main`
- Expected jobs (`Build and Deploy Merged RSS`):
  - `build`
  - `deploy`
- Expected jobs (`Run Tests and Lint`):
  - `tests` (includes unit tests + RuboCop step)
- Expected public URLs:
  - Site: `https://ledsun.github.io/rss-fusion/`
  - Feed: `https://ledsun.github.io/rss-fusion/merged.xml`

## Commands

Use `gh` CLI and `curl` for verification.

- List recent runs:
  - `gh run list --limit 10 --branch main --event push --json databaseId,workflowName,status,conclusion,event,createdAt,url`
- Watch a run:
  - `gh run watch <run_id> --exit-status`
- View details:
  - `gh run view <run_id>`
- View job summary in JSON (useful for checking expected jobs):
  - `gh run view <run_id> --json jobs`
- View failed logs (if needed):
  - `gh run view <run_id> --log-failed`
- Get Pages URL:
  - `gh api repos/ledsun/rss-fusion/pages --jq '.html_url'`
- Check public feed header:
  - `curl -fsSL https://ledsun.github.io/rss-fusion/merged.xml | sed -n '1,20p'`

## Local RuboCop Reproduction

When `Run Tests and Lint` fails on RuboCop, reproduce locally without writing outside the workspace.

- Use workspace-local cache root:
  - `mkdir -p tmp/rubocop_cache`
  - `RUBOCOP_CACHE_ROOT=/home/ledsun/rss-fusion/tmp/rubocop_cache bundle exec rubocop`
- For single-file checks:
  - `RUBOCOP_CACHE_ROOT=/home/ledsun/rss-fusion/tmp/rubocop_cache bundle exec rubocop <path>`
- Temporary file handling:
  - Keep cache under `tmp/rubocop_cache` only.
  - Do not commit files under `tmp/`.
  - Remove cache after verification when no longer needed:
    - `rm -rf tmp/rubocop_cache`

## Failure Handling

When a run fails, report:

1. Run ID and URL
2. Failing job and step
3. Exact error summary
4. Actionable next step (e.g., enable Pages, fix workflow syntax, rerun)

Common historical issue in this repo:
- `actions/configure-pages` can fail with `Get Pages site failed ... Not Found` when Pages is not enabled in repository settings.

When `Run Tests and Lint` fails, also call out whether the failure came from:
- `Run tests`
- `Run RuboCop`

## Success Criteria

Treat post-push verification as complete when:

1. Latest `push` run for `Build and Deploy Merged RSS` is `success`
2. Latest `push` run for `Run Tests and Lint` is `success`
3. `build` and `deploy` jobs both succeeded
4. `tests` job succeeded (including `Run tests` and `Run RuboCop` steps)
5. Pages URL resolves
6. `merged.xml` is fetchable and contains expected channel metadata (for example `<title>RSS Fusion</title>`)

## Example User Requests

- "push後のActions確認して"
- "GitHub Pagesへの反映が成功しているか見て"
- "push後の lint workflow も含めて確認して"
- "最新runの失敗原因を調べて"
- "公開merged.xmlに title が反映されているか確認して"
