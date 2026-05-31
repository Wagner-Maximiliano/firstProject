# GitHub backbone for AMA (B0-3)

This repository enforces the model-free delivery spine for AMA:

- trunk protection on `main`
- CI required on push and PR
- AMA routing labels and templates

## Included artifacts

- `.github/workflows/ci.yml` — lint/type/tests job (`lint-type-test`)
- `.github/ISSUE_TEMPLATE/ama-task.yml` — AMA task issue form
- `.github/PULL_REQUEST_TEMPLATE.md` — PR proof/risk checklist
- `.github/ama-labels.json` — AMA label contract (`ama:owner:*`, `ama:tier:*`)
- `scripts/configure_github_backbone.sh` — applies labels + branch protection via GitHub API

## Enforce branch protection on `main`

Prereqs:
- `gh` CLI installed
- `gh auth login` done
- admin rights on the target repo

Command:

```bash
scripts/configure_github_backbone.sh <owner/repo>
```

Protection settings applied:
- PR required for `main` (no direct pushes)
- required status check: `lint-type-test`
- 1 approving review required
- stale approvals dismissed on new commits
- conversation resolution required
- linear history required
- force-pushes and deletions disabled
- applies to admins too

## Projects v2 board contract

For AMA, set the `Status` field to include at least:
- Backlog
- Ready
- In Progress
- In Review
- Blocked
- Done

The exact board implementation can vary, but these states must exist for routing consistency.

## Verification checklist

1. Open a throwaway PR to `main`.
2. Confirm CI starts automatically and reports `lint-type-test`.
3. Confirm merge is blocked until CI is green and review is approved.
4. Confirm direct push to `main` is rejected.
5. Confirm issue template and PR template appear in GitHub UI.
6. Confirm AMA labels exist in the repository label list.

If GitHub auth/network blocks verification, capture exact command output in `STATE.md` as a blocker.
