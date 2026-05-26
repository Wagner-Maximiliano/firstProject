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

**Task B0-1 — Verify Hermes & reconcile the design** (now also: lock `core/` scope against Hermes-native features).
First read `docs/adr/ADR-0002` — it sets the packaging architecture everything else follows.
Concretely:
1. Confirm you're on `claude/autonomous-agent-framework-5MdEG` (it holds this package + the starter prompts in `/prompts/`). Do NOT branch from `master`.
2. Read `BUILD_PLAN.md` §2–§5, `FRAMEWORK_SPEC.md` §16, and `docs/adr/ADR-0002`; skim the starter job descriptions in `/prompts/`.
3. Write `docs/adr/ADR-0001-hermes-integration.md`: the real `hermes-agent` capabilities (skills/bundles/taps/profiles, provider/tier config, session persistence, compression, retries) vs. what the spec assumed — and decide, per `core/` module, **build-custom vs. defer-to-Hermes** (prefer Hermes for routing/sessions/compression; custom for the quota guard, board orchestration, GUI-test flow).
4. Then begin the packaging scaffold (per ADR-0002 follow-ups): create `skills/` with the 8 SKILL.md, `skill-bundles/ama-*.yaml`, and the profile-setup script; refactor `prompts/` content into skill bodies (the *how*) and new-profile `SOUL.md` drafts (the *who*). These will become explicit BUILD_PLAN tasks (a new packaging phase) — add them when you touch BUILD_PLAN.

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

### Handoff — 2026-05-26 — architecture/packaging session
- DONE this session: Verified (against real Nous `hermes-agent` docs) that Hermes has native **skills, bundles, taps, and profiles**. Decided and recorded the **packaging/distribution architecture** as `docs/adr/ADR-0002`: repo → Hermes tap; ~8 focused skills (the *how*); new dedicated AMA profiles for identity (the *who*, in their own `SOUL.md`); keep custom `core/`; per-project `PROJECT_BRIEF.md`. No code written yet; this was design lock-in.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`, no build/tests yet, last work = ADR-0002 + this STATE update.
- LEARNED / GOTCHAS: (1) Never write the human's existing profile `SOUL.md`; only profiles AMA creates. (2) Hermes already does routing/sessions/compression — don't rebuild these in `core/`; reconcile in B0-1. (3) Hub/URL skills are security-scanned — author skills to read clean. (4) "AMA" name + repo rename is a human decision/settings action.
- NEXT: see "NEXT SESSION STARTS HERE" — B0-1 (Hermes reconciliation/ADR-0001), now explicitly scoped to settle `core/`-vs-Hermes overlap; then scaffold the tap (`skills/`, `skill-bundles/`, profile setup) and refactor `prompts/` into skill bodies + new-profile `SOUL.md` drafts.
- BLOCKERS / WAITING ON HUMAN: name confirmation ("AMA"); provider keys/Telegram token (mock until supplied).

---

## DECISIONS LOG (ADR index)

- **ADR-0002** (2026-05-26) — Distribute the framework as a **Hermes tap + dedicated profiles**. Repo becomes a tap (`skills/`), installed via `hermes skills tap add`. ~8 focused skills carry the *how*; new dedicated AMA profiles (`ama-planner/builder/reviewer/board-a/b/c`) carry the *who* in their own `SOUL.md` — the human's existing profiles are never touched. Keep the custom `core/` engine; reconcile its overlap with Hermes-native features in ADR-0001. Projects stay clean: a per-project `PROJECT_BRIEF.md` + kickoff prompt, framework lives globally in `~/.hermes`. (ADR-0001 = Hermes-integration, still to be written in B0-1.)

---

## OPEN QUESTIONS / BLOCKERS

- [ ] Provider keys + Telegram token not yet confirmed in the environment → using mock provider until the human supplies them (see HUMAN_RUNBOOK.md "One-time setup").
- [ ] Pilot toy-project idea not chosen yet → the first planning run (B1-1) can pick a simple one (e.g. single-screen to-do list) unless the human specifies.
- [ ] **Working name "AMA"** collides with "Ask Me Anything" in search/docs. Human to confirm the name (and the GitHub repo rename, which is a GitHub *settings* action the human performs — not scriptable here).
- [ ] **`core/` vs Hermes-native overlap** must be settled in B0-1/ADR-0001 before building B0-4 (gateway) and B0-5 (state): prefer Hermes-native routing/sessions/compression; build custom only for real gaps (quota guard, board orchestration, GUI-test flow).

### Resolved
- **Portability** (was open): the framework is NOT copied into projects. It's a **Hermes tap** installed once per machine; each project carries only a small `PROJECT_BRIEF.md` + `STATE.md`. See ADR-0002.

---

## ENVIRONMENT / SETUP NOTES

_Fill in as discovered: Python version, how to run setup/tests, expected env-var names, Hermes install notes, anything a fresh session needs to get running fast._
