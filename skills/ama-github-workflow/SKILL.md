---
name: ama-github-workflow
description: Enforcing GitHub best-practice workflow with branch-per-task, Kanban columns, required reviews, and CI gates before merge.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, github, workflow, cicd]
    category: ama
---

# GitHub Workflow for Autonomous Agents

Ensures all work flows through branches, Kanban, and code review with CI gates—never committing directly to trunk. This keeps the build orderly and auditable.

## When to Use

- Before starting any task: branch and create an issue if needed.
- When opening a PR: verify CI will pass, set draft status, request reviews.
- When merging: ensure green CI, required reviews, move card, delete branch.
- At any time: to confirm your current branch and status are correct.

## Procedure

### Starting a task

1. **Confirm you are NOT on `main`/`master`.** Run `git branch` and verify you are on the project's designated **integration/build branch** (named in the project's `PROJECT_BRIEF.md` or `STATE.md`), never the trunk.
2. **Create a GitHub Issue** (if not already done) in the repository. AMA-managed issues should carry exactly one owner label and one tier label:
   - owner: `ama:owner:orchestrator|builder|reviewer|inverted-reviewer|board|human`
   - tier: `ama:tier:t1|t2|t3|board`
   Optional dependency and scope notes should be captured in the issue body so overlap detection can reason about parallel work.
3. **Create a local branch** from the build branch:
   ```bash
   git pull origin <build-branch>
   git checkout -b task/<issue-#>-<slug>
   ```
   Example: `task/42-add-logging` for issue #42.
   - Branch names are case-insensitive, hyphens only (no underscores or dots).
   - **Never** branch from `main`/`master`.
4. **Move the issue card** on the Kanban board from **Backlog** → **Ready** as soon as dependencies are satisfied and you are assigned.

### During work

1. **Commit early and often** with clear, atomic messages using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat(module): add new capability
   fix(module): correct behavior X
   refactor: extract shared logic
   test: add coverage for edge case
   docs: clarify API contract
   ```
   Include **why** you made the change, not just what changed.
2. **Push regularly** to the remote branch (`git push -u origin task/<issue-#>-<slug>` on first push, then `git push`).
3. **Run local lint, tests, and type-check** before pushing—catch failures early.
4. **Move the card** to **In Progress** when you open the draft PR (see below).

### Opening a pull request

1. **Open a draft PR** (not ready for review yet) with title matching the Conventional Commits style: `fix: correct X` or `feat: add Y`.
2. **PR description auto-generated** (by T1 or manual summary):
   - What changed and why.
   - Link the issue: `Closes #<issue-#>`.
   - Reference any relevant ADRs or design docs.
   - Note any assumptions or areas for reviewer focus.
3. **Confirm CI is queued.** GitHub Actions should run automatically on push. Do **not** proceed if CI is not running.
4. **Add the PR to the Kanban board** and move its card to **In Review** column.

### CI & quality gates

1. **Wait for CI to pass:** tests, lint, type-check, build, security scan. All must be green.
   - If any check fails, fix locally, commit, push—CI re-runs automatically.
   - If failures are environmental or transient, consult the logs; do not retry blindly.
2. **Do not skip or force-push past failures.** A failing check signals a real problem.
3. **Once CI is green,** mark the PR as "ready for review" (exit draft status).

### Code review

1. **Request review** from another agent or a human reviewer (configured per org/repo). **Builder and Reviewer must be different model instances** (separation of duties).
2. **Respond promptly to review comments.** Address every feedback item:
   - If you agree, commit the fix.
   - If you disagree (with rationale), document the decision in a reply and/or an ADR.
   - Do **not** dismiss feedback without engagement.
3. **Re-push after addressing comments.** CI runs again automatically.
4. **Approval.** Once the Reviewer approves (green check on the PR) and CI is green, the PR is mergeable.

### High-impact decisions (Board trigger)

If the PR touches architecture, security, schema, dependencies, or irreversible changes (§7.1 in FRAMEWORK_SPEC.md):

1. **Do not merge yet.** The Approval Board must convene.
2. **Tag the PR or linked issue** with the appropriate owner/tier labels and any repo-specific risk marker your project uses.
3. **Wait for Board review.** The 3-vendor panel votes. Proceed only if the vote clears thresholds (§7.4).
4. **Incorporate any conditions** from the Board into a follow-up commit.

### Merging

1. **Confirm final state:**
   - CI is green.
   - All reviews are approved.
   - Branch is up to date with `main` (rebase if needed, or the merge queue does this).
   - No merge conflicts blocking progress.
2. **Merge through the pull request — never by pushing to the trunk locally.** The trunk is protected; the merge is performed via the PR (the merge queue if one is enabled), and triggered by the Integrator, not the Builder, once the PR is approved and green.
   - Use a **squash** merge when there are many small commits, or a **merge commit** to preserve a meaningful history.
   - **Never** run `git push` against `main`/`master`, and never force-push the trunk. If you find yourself typing `git checkout main` to merge, stop — merging is a PR action (GitHub merge button / merge-queue / `pull_request` merge API), not a local push.
3. **Delete the branch** after merge:
   ```bash
   git branch -d task/<issue-#>-<slug>
   git push origin --delete task/<issue-#>-<slug>
   ```
4. **Move the card to Done** on the Kanban board.
5. **Confirm the issue is closed** (GitHub auto-closes linked issues in the PR).

## Pitfalls

**Committing to `main` directly:** Branch protection prevents this mechanically, but never attempt it—always use PRs.

**Merging without green CI:** CI must pass before merge. If CI is flaky, investigate and fix the test/config, do not bypass.

**Self-review:** Always request review from a *different* agent/model or human. If unsure, post in a channel and wait for response.

**Stale branch:** If your branch falls behind `main` (other PRs merged), rebase before merging:
```bash
git fetch origin
git rebase origin/main
git push --force-with-lease origin task/<issue-#>-<slug>
```
`--force-with-lease` (not `-f`) refuses to overwrite the remote if someone else has pushed to your task branch in the meantime — a safe force-push.

**Board-flagged PR merged without Board approval:** A Board decision blocks merge until thresholds clear. Do not bypass.

**Forgotten or conflicting labels:** Labels are routing signals, not decoration. Every AMA-managed issue needs exactly one `ama:owner:*` label and one `ama:tier:*` label. If those are missing or conflicting, the orchestrator should repair the obvious default or block the issue rather than guessing.

## Verification

- **Branch is correct:** `git branch` shows you on a `task/*` or long-lived branch, never `main`.
- **Commits are clean:** `git log --oneline -5` on your branch shows atomic, well-named commits.
- **PR is open:** Link to PR is in the GitHub issue.
- **CI is green:** All checks pass (green checkmarks on the PR).
- **Reviewers assigned:** PR shows assigned reviewers.
- **Card is current:** Kanban card matches the PR status (In Review, or Done if merged).
- **No direct pushes to main:** Confirm via `git log main -1` that the latest commit was merged from a PR, not pushed directly.
