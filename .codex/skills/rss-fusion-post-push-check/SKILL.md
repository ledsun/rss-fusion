---
name: rss-fusion-post-push-check
description: Verify rss-fusion deployment after pushing to `main`. Use when checking the latest GitHub Actions run status, build/deploy job results, GitHub Pages availability, and whether `merged.xml` is publicly updated after a push.
---

# Rss Fusion Post Push Check

## Overview

Run the standard post-push verification flow for this repository.
Confirm that GitHub Actions completed successfully and GitHub Pages is serving the updated `merged.xml`.

## Workflow

1. Confirm the push succeeded (if not already shown by the session).
2. Inspect the latest workflow run triggered by `push`.
3. Watch the run until completion.
4. If failed, inspect failing step/logs and report the concrete cause.
5. If successful, confirm Pages URL and fetch `merged.xml` (or at least its header) to verify public output.

## Repository-Specific Targets

- Workflow name: `Build and Deploy Merged RSS`
- Branch: `main`
- Expected jobs:
  - `build`
  - `deploy`
- Expected public URLs:
  - Site: `https://ledsun.github.io/rss-fusion/`
  - Feed: `https://ledsun.github.io/rss-fusion/merged.xml`

## Commands

Use `gh` CLI and `curl` for verification.

- List recent runs:
  - `gh run list --limit 5 --json databaseId,workflowName,status,conclusion,event,createdAt,url`
- Watch a run:
  - `gh run watch <run_id> --exit-status`
- View details:
  - `gh run view <run_id>`
- View failed logs (if needed):
  - `gh run view <run_id> --log-failed`
- Get Pages URL:
  - `gh api repos/ledsun/rss-fusion/pages --jq '.html_url'`
- Check public feed header:
  - `curl -fsSL https://ledsun.github.io/rss-fusion/merged.xml | sed -n '1,20p'`

## Failure Handling

When a run fails, report:

1. Run ID and URL
2. Failing job and step
3. Exact error summary
4. Actionable next step (e.g., enable Pages, fix workflow syntax, rerun)

Common historical issue in this repo:
- `actions/configure-pages` can fail with `Get Pages site failed ... Not Found` when Pages is not enabled in repository settings.

## Success Criteria

Treat post-push verification as complete when:

1. Latest `push` run for `Build and Deploy Merged RSS` is `success`
2. `build` and `deploy` jobs both succeeded
3. Pages URL resolves
4. `merged.xml` is fetchable and contains expected channel metadata (for example `<title>RSS Fusion</title>`)

## Example User Requests

- "push後のActions確認して"
- "GitHub Pagesへの反映が成功しているか見て"
- "最新runの失敗原因を調べて"
- "公開merged.xmlに title が反映されているか確認して"
