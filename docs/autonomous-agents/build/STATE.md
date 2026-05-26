# STATE — Live Build Progress (single source of truth)

> **This file is the project's memory across sessions.** Every session reads it first and updates it last (see `SESSION_PROTOCOL.md`). If something isn't written here (or in the code/commits), the next session won't know it.

---

## CURRENT STATUS

- **Phase:** B0 — Foundations & spec reconciliation
- **Active task:** _none yet — not started_
- **Build branch:** `claude/autonomous-agent-framework-5MdEG` _(already holds this handover package + starter prompts; build here and keep `master` untouched)_
- **Build health:** _no code yet_
- **Real provider keys present?:** _unknown — assume NO; use the mock provider until told otherwise_

---

## ▶ NEXT SESSION STARTS HERE

**Task B0-1 — Verify Hermes & reconcile the design.**
First session also needs to do the protocol's START checklist and create the build branch.
Concretely:
1. Confirm you're on `claude/autonomous-agent-framework-5MdEG` (it holds this package + the starter prompts in `/prompts/`). Do NOT branch from `master`.
2. Read `BUILD_PLAN.md` §2–§5 and `FRAMEWORK_SPEC.md` §16, and skim the starter job descriptions in `/prompts/`.
3. Research the real `hermes-agent` API (its repo/docs) and write `docs/adr/ADR-0001-hermes-integration.md` capturing what's actually true vs. what the spec assumed.
4. If quick, scaffold B0-2 (project skeleton) as well.

---

## TASK CHECKLIST (V1 pilot — from BUILD_PLAN.md)

### Phase B0 — Foundations
- [ ] B0-1 Verify Hermes & reconcile design (ADR-0001)
- [ ] B0-2 Project skeleton (venv, pyproject, lint/type, pytest, structure)
- [ ] B0-3 GitHub backbone (branch protection, Projects board, labels, CI)
- [ ] B0-4 Model gateway over Hermes (tier→provider, mock provider, smoke tests)
- [ ] B0-5 State store + checkpoint/resume (SQLite)
- [ ] B0-6 Telegram channel (send + tap-to-answer)
- [ ] B0-7 Quota & rate guard skeleton (5-hour windows, free-first)

### Phase B1 — Core autonomous loop (single stream)
- [ ] B1-1 Planning (progressive disclosure) + sign-off
- [ ] B1-2 Orchestrator loop (single stream)
- [ ] B1-3 Builder agent
- [ ] B1-4 Empirical + adversarial escalation (T0 runner + inverted reviewer)
- [ ] B1-5 Reviewer + Integrator (PR merge to trunk)
- [ ] B1-6 Human test guide + test env + Telegram gate
- [ ] B1-7 Board (3 vendors): rubric + prove-it-or-lose-it
- [ ] B1-8 Watchdog + recovery (minimal)
- [ ] B1-9 Go-live gate (human-approved)

### Phase B2 — Pilot dry run
- [ ] B2-1 End-to-end pilot + PILOT_REPORT.md

---

## LAST SESSION SUMMARY

_None yet — this is the starting state. The first session should replace this with its handoff note (template in SESSION_PROTOCOL.md §6)._

---

## DECISIONS LOG (ADR index)

_None yet. Add a one-line entry here whenever you commit an ADR to `docs/adr/`._

---

## OPEN QUESTIONS / BLOCKERS

- [ ] Provider keys + Telegram token not yet confirmed in the environment → using mock provider until the human supplies them (see HUMAN_RUNBOOK.md "One-time setup").
- [ ] Pilot toy-project idea not chosen yet → the first planning run (B1-1) can pick a simple one (e.g. single-screen to-do list) unless the human specifies.

---

## ENVIRONMENT / SETUP NOTES

_Fill in as discovered: Python version, how to run setup/tests, expected env-var names, Hermes install notes, anything a fresh session needs to get running fast._
