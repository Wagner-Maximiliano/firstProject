---
name: ama-review
description: Two-stage code quality gate: cheap adversarial review (skepticism score + critical/minor findings), then merge-gate Reviewer deciding approve/request-changes, escalate empirically on test failures or critical findings.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, review, quality-gate, escalation]
    category: ama
---

# Two-Stage Review: Inverted Reviewer + Merge Gate

This skill implements a defense-in-depth code review process. A cheap, deliberately adversarial T1 model (the Inverted Reviewer) hunts for flaws in the Builder's work, producing a skepticism score and critical findings. Then a separate T2 Reviewer (always a different model instance than the Builder) decides approve/request-changes at the merge gate. Escalation is empirical (real test failures + critical findings), not self-reported confidence.

## When to Use
- A draft PR is open and CI (tests, lint, type-check) has passed.
- You need to decide whether the code meets the acceptance criteria and is safe to merge.
- The Builder must be a different model instance than the Reviewer (no self-review).

## Procedure

### Stage 1: Inverted Reviewer (T1, cheap, adversarial)
**Goal:** Hunt for flaws against the acceptance criteria. Produce a skepticism score and critical findings that trigger escalation.

1. **Read the inputs:**
   - The Builder's diff (from the PR).
   - The task's acceptance criteria.
   - The repo's conventions and style guide.
   - Any relevant ADRs or context files.

2. **Adopt adversarial stance.** Your job is to find what's wrong, not to be agreeable. Look specifically for:
   - **Acceptance criteria not actually met** — does the code really do what the criteria require?
   - **Missing edge cases or error handling** — what breaks if the input is empty, null, huge, malformed, concurrent, or fails?
   - **Broken or changed contracts** — does the code change an API that other code depends on?
   - **Security issues** — input validation at boundaries, secrets (hardcoded API keys, passwords), unescaped SQL, etc.
   - **Tests that don't test** — mocked-out features, assertions that never fail, or tests skipped/disabled.
   - **Incomplete transactions or state changes** — can the operation fail halfway and leave the system in an inconsistent state?

3. **Examine the test coverage:**
   - Do the tests actually exercise the new code?
   - Are edge cases tested, or only the happy path?
   - Can you mentally break the code and have the tests catch it?

4. **Produce a skepticism score (0–10):**
   - 0–2 = looks solid, no real concerns.
   - 3–5 = minor issues, not blockers.
   - 6–8 = real problems that need fixing.
   - 9–10 = seriously broken, major rework needed.

5. **List critical findings** (problems that break a requirement, security, or correctness):
   - Each finding: `{ "where": "file:line", "problem": "specific issue", "criterion": "which acceptance criterion is violated" }`.
   - Example: `{ "where": "auth/login.py:42", "problem": "password is logged in plaintext to stdout", "criterion": "Security: no secrets in logs" }`.
   - Be specific. Point to code. Explain why it's a problem.

6. **List minor findings** (style, nitpicks, suggestions):
   - Each note: `{ "where": "file:line", "note": "..." }`.
   - Do not block on these.

7. **Decide: escalate?** Escalate (recommend_escalation = true) if:
   - ≥3 critical findings, OR
   - Any finding breaks security, correctness, or a hard acceptance criterion, OR
   - Skepticism score ≥7.

8. **Output JSON:**
   ```json
   {
     "skepticism_score": 6,
     "critical_findings": [
       { "where": "form/submit.js:85", "problem": "Validation skipped if email field is empty; criterion requires 'form rejects invalid emails'", "criterion": "Email validation" }
     ],
     "minor_findings": [
       { "where": "form/submit.js:10", "note": "var instead of const; repo uses const by convention" }
     ],
     "recommend_escalation": true
   }
   ```

### Stage 2: Reviewer merge gate (T2, different model than Builder)
**Goal:** Make a firm approve/request-changes decision. Incorporate the Inverted Reviewer's findings. Do not self-review.

1. **Assert separation of duties:**
   - You are not the same model instance that wrote the code.
   - If you are, stop and request a different reviewer.

2. **Read the inputs:**
   - The PR diff and description.
   - The task's acceptance criteria.
   - The Inverted Reviewer's findings, skepticism score, and recommendation.
   - CI results (tests, lint, type-check).
   - The Builder's description of what they did.

3. **Check for correctness:**
   - Does the code actually implement the acceptance criteria?
   - Are all acceptance criteria met, or only some?
   - Are there edge cases that should be handled but aren't?

4. **Check for test adequacy:**
   - Are the tests meaningful (not mocks that hide the behavior)?
   - Do they cover the happy path *and* edge cases?
   - Would the tests catch a subtle bug in the implementation?

5. **Check for security issues:**
   - Inputs validated at boundaries?
   - Secrets not in code/logs?
   - SQL/template injection risks?
   - Any unintended API exposure?

6. **Check for maintainability:**
   - Code is readable; why-comments explain non-obvious decisions.
   - Follows repo conventions (style, structure, ADRs).
   - Blast radius is reasonable (not touching 50 unrelated files).

7. **Incorporate the Inverted Reviewer's findings:**
   - If skepticism_score < 7 and no critical findings: the reviewer's judgment aligns with a likely approval. Proceed with normal review.
   - If skepticism_score ≥ 7 OR recommend_escalation = true: escalate (see Escalation ladder below) *unless* you independently verify that the findings are invalid (e.g., the Inverted Reviewer misread the code, or the criterion was already met). Document why you're overriding the recommendation.

8. **Check if the change touches Board criteria:**
   - Architecture, schema, dependency, security, irreversible, large blast radius?
   - If yes, mark `needs_board: true` and do not merge; route to the Board instead.

9. **Make a decision: approve or request changes.**
   - **Approve:** The code meets the acceptance criteria, tests are adequate, no security issues, and it follows conventions.
   - **Request changes:** Specific, actionable feedback. Example: "Line 42: password must be hashed using bcrypt, not plaintext. Update the hash function and add a test for a correct hash." Every "request changes" must be concrete and fixable.

10. **Output JSON:**
    ```json
    {
      "decision": "approve",
      "needs_board": false,
      "comments": [],
      "summary": "Code meets all acceptance criteria; tests are thorough and pass."
    }
    ```
    Or (request changes):
    ```json
    {
      "decision": "request_changes",
      "needs_board": false,
      "comments": [
        { "where": "auth/login.py:42", "issue": "Password must be hashed (bcrypt) before storage. Add bcrypt.hashpw() call and update test_login_hash to verify.", "required": true }
      ],
      "summary": "Blocker: password handling violates security criterion."
    }
    ```

### Escalation Ladder (empirical, not self-reported)

**Trigger 1: Empirical test failure (T0)**
- CI has failed: tests, build, lint, or type-check do not pass.
- Escalate to T3 (hard debugging) or Builder (to fix).
- Do not approve.

**Trigger 2: Inverted Reviewer critical findings + escalation flag**
- Skepticism score ≥ 7 OR recommend_escalation = true AND ≥3 critical findings.
- Escalate to T3 for a deep security/correctness review.
- Do not approve until escalation is resolved.

**Trigger 3: Board criteria touched**
- Architecture, schema, dependency, security, irreversible, large blast radius.
- Mark `needs_board: true`.
- Do not merge; route to Approval Board.

**Trigger 4: Repeated request-changes cycles (loop detection)**
- Same PR cycles through request-changes → resubmit → request-changes (same issue) >2 times.
- Escalate to T3 or mark Blocked.
- Circuit-breaker: stop the loop; don't let it spin endlessly.

## Pitfalls

- **Self-review.** Same model instance that wrote the code reviews it. **Mitigation:** strict separation of duty; Reviewer is a different tier/instance.
- **Trusting the Inverted Reviewer blindly.** Finding is invalid but you don't catch it. **Mitigation:** independently verify critical findings; if the finding doesn't match your read of the code, say so and explain.
- **Blocking on style instead of substance.** "This code is inelegant." **Mitigation:** lint/format already passed; only block on actual bugs, security, or test gaps.
- **Missing security issues.** Hardcoded secret, unvalidated input, SQL injection. **Mitigation:** always scan inputs at boundaries; check for secrets; ask "what if this input is malicious?"
- **Approving partial implementations.** Criteria are half-met (edge case untested). **Mitigation:** re-read acceptance criteria; verify each one is addressed in the code *and* in the tests.
- **Merging a Board-criteria change without the Board.** Huge blast radius, but didn't notice. **Mitigation:** before approving, check the task DAG and ADRs for Board flags; ask "does this change something architects should have signed off on?"

## Verification

1. **CI is green:**
   - All tests pass.
   - Lint/type-check pass.
   - Build succeeds.

2. **Inverted Reviewer output exists:**
   - Skepticism score assigned.
   - Critical and minor findings listed (or empty if none).
   - Escalation flag set.

3. **Reviewer decision is recorded:**
   - Decision: approve / request_changes.
   - If request_changes, each comment is specific and actionable (not vague).
   - If approve, the reasoning is documented.

4. **Board routing is correct:**
   - If needs_board = true, the PR is not merged; it's queued for the Board.
   - If needs_board = false, the PR proceeds to merge (if approved).

5. **Escalation is logged:**
   - If escalation triggered, the reason and escalation tier are recorded.
   - The escalated agent receives the full context (diff, findings, reason).

6. **Reviewer is a different model instance than the Builder:**
   - Confirmed in the model routing log or session metadata.
