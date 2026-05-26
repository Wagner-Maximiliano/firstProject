---
name: ama-board
description: Three-vendor Approval Board for high-impact decisions using objective rubric scoring (cost/security/maintainability 1-10), score-blind then cross-check, with prove-it-or-lose-it veto rule.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, board, decisions, governance]
    category: ama
---

# Multi-Vendor Approval Board

This skill convenes three independent frontier models (T3), one from each major vendor (Anthropic, OpenAI, and a third), to score high-impact decisions against a fixed, objective rubric. Decisions are computed from scores, not debated. Any veto must ship a concrete, compiling alternative or it is discarded. This prevents both deadlock and the silent accumulation of unchecked risk.

## When to Use
- A decision touches Board criteria: architecture, schema, dependency, security, irreversible, large blast radius, or exceeds a cost threshold.
- The Reviewer or Planner has flagged `needs_board: true`.
- You need cross-vendor consensus on a high-stakes call, not a single model's opinion.

## Procedure

### Stage 0: Proposal & brief
**Goal:** The proposing agent (Reviewer, Planner, or orchestrator) writes a concise decision brief.

1. **Proposer prepares a brief** (target: < 1 page):
   - **Problem:** what's the decision and why does it matter?
   - **Options:** 2–3 options considered.
   - **Recommendation:** the proposer's preferred choice and why.
   - **Rationale:** the key reasoning (cost, security, maintainability, performance, irreversibility, blast radius, etc.).
   - **Risks:** known downsides or unknowns.
   - **Relevant code/diff:** the specific changes under review.

2. **Map to the rubric (§1.4 below).** The brief notes which axes (Cost, Security, Maintainability, and any project-specific axes like Performance) are relevant.

3. **Ensure the brief is legible to independent vendors.** Assume reviewers have not read prior context; the brief must stand alone.

### Stage 1: Blind scoring
**Goal:** Each Board member scores independently, without seeing the others' scores, based on the fixed rubric.

1. **Board member A (Anthropic frontier):**
   - Reads the brief + relevant diff.
   - Scores each axis 1–10.
   - Writes one-line justification per axis (not essays, just clear reason).
   - If any score is **below a threshold** (rejecting the proposal), attaches a concrete, compiling code-level alternative or pseudo-code patch proving the objection is actionable and better. (See "Prove it or lose it" rule, §1.4.)
   - Does not see Board members B or C's scores yet.

2. **Board member B (OpenAI frontier):**
   - Same process, independently.

3. **Board member C (Third vendor, e.g., via OpenRouter):**
   - Same process, independently.

### Stage 2: Cross-check & revision
**Goal:** Board members see each other's scores and may revise their own in light of others' reasoning or patches.

1. **Scores are revealed:**
   - A, B, C see all three score sets + justifications + any attached patches.

2. **Each member may revise:**
   - Read the others' justifications and patches.
   - Revise your score if their reasoning changes your mind (defend, concede, or revise).
   - If revising, note why.
   - You may challenge a patch: "This patch is correct but introduces a new risk (X)" — but you can only override a patch-backed veto if you have an even better alternative.

3. **Output revised scores:**
   ```json
   {
     "member": "A",
     "scores": { "cost": 8, "security": 9, "maintainability": 7 },
     "justifications": {
       "cost": "Adds a third vendor; quarterly costs +$500. Offset by reduced lock-in risk.",
       "security": "Multi-vendor reduces correlated blind spots; strong win.",
       "maintainability": "Three providers to maintain; operational overhead +20%."
     },
     "verdict": "approve",
     "alternative_patch": null,
     "revised": false
   }
   ```
   If veto:
   ```json
   {
     "member": "B",
     "scores": { "cost": 6, "security": 5, "maintainability": 4 },
     "justifications": {
       "cost": "Third vendor lock-in; no cost benefit.",
       "security": "Data duplication across vendors increases exposure; below threshold.",
       "maintainability": "Op overhead unsustainable for a 3-person team."
     },
     "verdict": "reject",
     "alternative_patch": "Remove the third vendor from the board; use a two-vendor model (Anthropic + OpenAI fallback). Maintains diversity with -50% overhead. [pseudo-code: def board_vote(option): ...; removes provider c from roster ...]",
     "revised": false
   }
   ```

### Stage 3: Reconcile (math, not debate)
**Goal:** Apply scoring thresholds to compute the outcome automatically. Only patch-backed divergence escalates to a human.

**Scoring rubric (tri-factor, 1–10 per axis):**

| Axis | What to score |
|---|---|
| **Cost** | Build/run/maintenance cost and quota-window impact of this choice. |
| **Security** | Risk to data, secrets, auth, users; exposure if the choice fails. |
| **Maintainability** | Readability, handover, blast radius, reversibility, ease of undo. |

(A project may add one more axis, e.g., *Performance*, but set it *before* scoring.)

**Thresholds (example; tune from outcomes):**

| Outcome | Condition | Action |
|---|---|---|
| **Approved** | Mean of each axis ≥ 7 AND no mandatory floor breached. | Merge / proceed. |
| **Mandatory floor** | Security-sensitive / data / irreversible changes require *every* member's Security score ≥ 8. Any sub-floor score blocks regardless of mean. | If any member scores Security < 8, reject and loop back to cross-check. |
| **Approved w/ conditions** | Passes thresholds but carries surviving (patch-backed) objections. | Proceed, but the flagged objections become must-fix conditions on the task. Record in ADR. |
| **Evidence-backed divergence** | Scores straddle a threshold AND a sub-threshold vote is backed by a working alternative patch. | Rare signal: escalate to human (Telegram) with both patches attached. |
| **Rejected** | Below threshold and no working alternative patch. | Return to proposer with scores + best alternative patch. Revise and re-board. |

**Compute the outcome:**
```
mean_cost = mean(A.cost, B.cost, C.cost)
mean_security = mean(A.security, B.security, C.security)
mean_maintainability = mean(A.maintainability, B.maintainability, C.maintainability)

if any_member_security_score < 8 for security_critical_change:
  outcome = REJECTED  # mandatory floor breached
elif mean_cost < 7 or mean_security < 7 or mean_maintainability < 7:
  outcome = REJECTED
elif any_sub_threshold_score_has_working_patch and scores_diverge:
  outcome = ESCALATE_TO_HUMAN  # evidence-backed divergence
else:
  outcome = APPROVED
```

### Stage 4: Record & Act
**Goal:** Document the Board's decision and route the outcome.

1. **Create/update an ADR** (`/docs/adr/ADR-<number>.md`):
   - Decision: what was approved/rejected.
   - Options: the options scored.
   - Scores: the final (post-cross-check) scores from all three members, plus their justifications.
   - Outcome: computed result (Approved / Rejected / Escalated).
   - Surviving objections: any patch-backed issues that became must-fix conditions.
   - Date and member IDs (A/B/C).

2. **Route the outcome:**
   - **Approved:** Proposer (PR, Planner, etc.) proceeds. Merge / implement the decision.
   - **Approved w/ conditions:** Proposer proceeds, but record the conditions in the issue/ADR so the Reviewer/Builder knows to address them.
   - **Rejected:** Return to proposer with the finalized scores + the best alternative patch. Proposer revises the brief or the code and re-boards.
   - **Escalated to human:** Post to Telegram (§11.5 of FRAMEWORK_SPEC) with both patches and the score divergence, asking the human to pick one. Include: the decision brief, both patches, the scores, and a clear question ("Patch A or Patch B?").

## The Prove-it-or-lose-it Veto Rule

**If you score any axis below a threshold** (i.e., you are effectively rejecting), **you must attach a concrete, compiling code-level alternative or pseudo-code patch** demonstrating:
1. Your objection is actionable (the problem is fixable, not a philosophical disagreement).
2. Your alternative is better and more feasible than the original.

**A rejection with no working alternative is discarded as noise.** This rule forces vetoes to be grounded in engineering reality, not preference.

**Examples:**

*Veto A (invalid — no patch):*
> "I don't like the microservices architecture. It's over-engineered."
> Verdict: DISCARDED. No patch = no substance.

*Veto B (valid — has patch):*
> "Microservices architecture increases operational complexity. The team is 3 people; we should start with a monolith.
> [Patch] Move all business logic to a single Python FastAPI service with a PostgreSQL backend. Use background workers (Celery) for async tasks. This is simpler to deploy (docker-compose) and cheaper (one VM vs. five containers). Revisit if we outgrow a single instance."
> Verdict: VALID. Patch is concrete and compilable. Challenge it, but it stands.

## Pitfalls

- **Stylistic deadlock.** Members "disagree" on elegance without any real difference in outcome. **Mitigation:** the rubric is objective (Cost, Security, Maintainability — not Style); score the axes, not the aesthetic. If two patches both pass the rubric, that's OK — it's a tie, not a veto.
- **Veto without a patch.** "This is wrong" with no alternative. **Mitigation:** the prove-it-or-lose-it rule discards it. Force the veto to be actionable.
- **Anchoring to the proposer.** Members don't think independently. **Mitigation:** blind scoring (stage 1); do not see others' scores until after you commit.
- **Anecdotal reasoning.** "A similar project once failed because of X." **Mitigation:** justify scores in concrete terms relevant to *this* decision; cite facts, not war stories.
- **Mandatory floor too strict.** Security floor of 8 means no hard trade-off ever gets approved. **Mitigation:** set floors based on real risk, not maximalism. Security-sensitive changes require high scores, but not *all* changes.
- **Escalation abuse.** Every small divergence escalates to the human. **Mitigation:** only evidence-backed divergence (patch-backed veto + real score split) escalates; normal disagreement is resolved by the math.

## Verification

1. **Brief is recorded:**
   - Problem, options, recommendation, rationale, risks are documented.
   - Maps to rubric axes.
   - Relevant diff is linked.

2. **Scores exist from all three members:**
   - Each axis (Cost, Security, Maintainability, +any project-specific axes) scored 1–10.
   - One-line justification per axis.
   - Blind scoring: A, B, C did not see each other before committing.

3. **Cross-check is recorded:**
   - Any revisions are noted ("revised: true") with reasons.
   - Any sub-threshold votes are backed by concrete alternative patches.

4. **Outcome is computed correctly:**
   - Means calculated.
   - Mandatory floors checked.
   - Outcome (Approved / Rejected / Escalated) derived from thresholds, not debate.

5. **ADR is committed:**
   - `/docs/adr/ADR-<number>.md` exists.
   - Captures decision, scores, justifications, outcome.
   - If Approved w/ conditions, conditions are listed.
   - If Escalated, note that.

6. **Outcome is enacted:**
   - Approved: proposer proceeds.
   - Rejected: proposer revises and re-boards (or proposes alternative).
   - Escalated: human is notified via Telegram with patches attached.
