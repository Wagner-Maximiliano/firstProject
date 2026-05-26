---
name: ama-build-task
description: Implement exactly one task from the plan on a task branch, satisfy acceptance criteria, write tests, and open a draft PR.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, build, coding, task-driven]
    category: ama
---

# Build a Single Task to Acceptance

This skill instructs a Builder agent (T1 for templated tasks, T2 for real coding) to implement exactly one task from the plan, write tests that verify the acceptance criteria, and open a draft PR. The Builder stays in scope, writes code for handover, and does not guess about confidence.

## When to Use
- The Orchestrator has scheduled a task from the plan DAG.
- You have a task description, acceptance criteria, relevant files, and repo conventions.
- You must produce working code on a task branch, not on main/master.

## Procedure

### Stage 1: Intake and planning
**Goal:** Understand the task, the acceptance criteria, and the scope boundary.

1. **Read the task description** from the GitHub issue or plan artifact. Capture:
   - The one-sentence outcome ("when a user X, they should see Y").
   - The acceptance criteria (observable, testable behaviors).
   - Any dependencies marked in the task DAG.
   - Any ADRs or constraints flagged for this task.

2. **Check the task branch naming convention:** `task/<issue-number>-<slug>`. If the branch doesn't exist, create it from the latest `main`:
   ```bash
   git fetch origin
   git checkout -b task/<issue-number>-<slug> origin/main
   ```

3. **Acquire a file lease** (if a lease system exists in `core/`):
   - Call the lease system with the files/directories you plan to touch.
   - If overlapping leases exist, wait or accept serialization.

4. **Gather relevant context:**
   - Read the acceptance criteria.
   - Read any existing tests that are related or foundational.
   - Read the style/lint/format rules for this repo (usually in `.eslintrc`, `pyproject.toml`, `prettier.config.js`, etc.).
   - Read the relevant ADRs that constrain your choices.

### Stage 2: Implement the feature
**Goal:** Write code that meets the acceptance criteria, no more, no less.

1. **Stay strictly in scope.** The acceptance criteria are the boundary. Do not:
   - Refactor unrelated code.
   - Add speculative features "for the future."
   - Optimize prematurely unless the criteria require it.
   - Change interfaces or APIs beyond what the criteria specify.

2. **Write code for handover.**
   - Use clear variable/function names.
   - Add **why-comments only** — explain non-obvious constraints, invariants, workarounds, or design decisions. Do not comment the obvious (e.g., `i += 1; // increment i`).
   - Keep functions small and focused.
   - Follow the repo's existing conventions (indent, naming, structure).

3. **Implement the code incrementally,** committing meaningful chunks:
   ```bash
   git add <specific files>
   git commit -m "feat: <one-line what>, why (link to issue)"
   ```
   Use Conventional Commits; the message should explain the *why*.

4. **If the task involves data changes** (schema, migrations, seed data):
   - Keep the migration reversible (if possible).
   - Document the data shape and any assumptions about existing data.
   - Flag any data-loss risk to the Reviewer and Board.

### Stage 3: Write tests alongside the code
**Goal:** Verify that your code meets the acceptance criteria and handles edge cases.

1. **For each acceptance criterion, write a test** that asserts the observable behavior. Examples:
   - Criterion: "When a user submits a form with invalid email, an error message appears."
   - Test: `assert form_submit_invalid_email() == "error message shown"`.

2. **Test edge cases and error paths:**
   - Empty/null inputs.
   - Boundary values.
   - Concurrent calls (if applicable).
   - Error conditions and fallbacks.

3. **Write tests that actually test** — not tests that mock everything or assert nothing:
   - Avoid mocking the code under test; mock external dependencies only.
   - Each test should assert a specific, meaningful behavior.
   - If a test is flaky or depends on timing, fix the root cause, don't add sleeps.

4. **Keep test coverage reasonable** — aim for coverage of the new code and the paths exercised by the acceptance criteria, not 100% of unreachable code.

5. **Run the tests locally** before committing:
   ```bash
   <repo test command, e.g., pytest, npm test, etc.>
   ```
   All tests must pass.

### Stage 4: Code review self-check
**Goal:** Catch obvious issues before submitting.

1. **Review your own diff** against the acceptance criteria:
   - Does each criterion have a corresponding code change?
   - Is any criterion missing?
   - Is any criterion partially met (e.g., it works for happy path but not edge cases)?

2. **Check the style/lint/format:**
   ```bash
   <repo lint/format command, e.g., eslint, black, rustfmt>
   ```
   Fix any violations.

3. **Build and test one more time:**
   ```bash
   <repo build command>
   <repo test command>
   ```
   All must pass.

4. **If tests fail or the build doesn't compile after a couple of honest attempts:**
   - Stop and report it. Do not ship broken code.
   - Include the error message and what you tried.
   - The Escalation ladder will route this to a higher-tier model or mark it Blocked.

### Stage 5: Open a draft PR
**Goal:** Submit your work for review without marking it "ready."

1. **Push your branch:**
   ```bash
   git push origin task/<issue-number>-<slug>
   ```

2. **Open a draft PR:**
   - Title: `[DRAFT] <one-line what you did>` (e.g., `[DRAFT] Add email validation to signup form`).
   - Description: a short summary of what you implemented and how it satisfies the acceptance criteria. Example:
     ```
     ## Summary
     - Validates email format on form submission.
     - Shows error message if invalid; submits only if valid.
     - Added unit tests for valid/invalid email cases.
     
     ## Acceptance criteria met
     - [x] Form rejects invalid emails.
     - [x] Error message is shown to user.
     - [x] Valid emails submit successfully.
     
     Closes #<issue-number>.
     ```

3. **Mark the PR as draft** (not ready for merge) so CI runs but reviewers know it's WIP.

4. **Do not request review yet.** The Orchestrator will route the PR to the Reviewer after CI passes.

## Pitfalls

- **Scope creep.** "While I'm here, let me refactor X." **Mitigation:** the acceptance criteria are the boundary; note out-of-scope work as a separate issue.
- **Partial implementation.** Criteria are half-met (happy path works, edge case doesn't). **Mitigation:** re-read the criteria before pushing; test edge cases; ask if unclear.
- **Tests that don't test.** Mocking out the entire feature, or assertions that never fail. **Mitigation:** test behavior, not implementation; mock only external deps; if a test passes even when you break the feature, rewrite it.
- **Confident but wrong.** Code compiles locally but doesn't actually work. **Mitigation:** run tests; don't guess; if stuck after two honest attempts, report it and escalate.
- **Skipping type/lint/format checks.** "It looks fine to me." **Mitigation:** automate checks; run them locally before push; CI will catch you anyway.
- **Secret/credential leaks.** Hardcoding API keys or passwords. **Mitigation:** use `.env`/secrets management; the secret scanner in CI will reject it.

## Verification

1. **Branch exists and is not main/master:**
   ```bash
   git branch | grep "task/"
   ```

2. **All acceptance criteria are met:**
   - Code changes address each criterion.
   - Tests pass and cover the criteria.
   - Manual check (if criteria are user-facing): the feature works as described.

3. **All tests pass:**
   ```bash
   <repo test command>
   ```
   Exit code 0.

4. **Lint/format/type-check pass:**
   ```bash
   <repo lint command>
   <repo type-check command (if applicable)>
   ```

5. **Code builds:**
   ```bash
   <repo build command>
   ```

6. **PR is open and marked as draft:**
   - Title contains `[DRAFT]`.
   - Description summarizes the work and links acceptance criteria.
   - Issue is linked (Closes #<number>).

7. **The Builder reports success or failure:**
   ```json
   {
     "pr_url": "https://github.com/...",
     "summary": "one-line what was built",
     "tests_added": ["test_email_validation", "test_form_submit"],
     "out_of_scope_notes": ["refactor of X noted as separate issue"],
     "blocked": false,
     "blocker_reason": null
   }
   ```
   Or if blocked:
   ```json
   {
     "pr_url": null,
     "summary": null,
     "tests_added": [],
     "out_of_scope_notes": [],
     "blocked": true,
     "blocker_reason": "Tests fail because [error]; tried [approaches]; need higher tier model"
   }
   ```
