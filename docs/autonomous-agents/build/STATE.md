# STATE — Live Build Progress (single source of truth)

> **This file is the project's memory across sessions.** Every session reads it first and updates it last (see `SESSION_PROTOCOL.md`). If something isn't written here (or in the code/commits), the next session won't know it.

---

## CURRENT STATUS

- **Phase:** Packaging scaffold complete (ADR-0002) → next is B0-1 reconciliation + PKG verification
- **Active task:** _none in progress — packaging scaffold just shipped_
- **Build branch:** `claude/autonomous-agent-framework-5MdEG` _(holds the handover package, prompts, AND the new tap: `skills/`, `profiles/`, `skill-bundles/`, `config/`, `scripts/`, `templates/`; build here, keep `master` untouched)_
- **Build health:** _no `core/` code or tests yet; the tap (skills/bundles/profiles) is authored but NOT yet tested against a real Hermes install_
- **Real provider keys present?:** _unknown — assume NO; use the mock provider until told otherwise_

---

## ▶ NEXT SESSION STARTS HERE

**Task B0-1 — Verify Hermes & reconcile `core/` scope** (unblocked; no running Hermes needed).
The packaging scaffold (tap: `skills/`, `skill-bundles/`, `profiles/`, `config/`, setup script, brief template) is already built and committed — see `docs/adr/ADR-0002`, the README, and BUILD_PLAN's "Packaging as a Hermes tap" section. **Do NOT rebuild it.**
Concretely:
1. Confirm you're on `claude/autonomous-agent-framework-5MdEG`. Do NOT branch from `master`.
2. Read `BUILD_PLAN.md` §2–§5 + the "Packaging as a Hermes tap" section, `FRAMEWORK_SPEC.md` §16, and `docs/adr/ADR-0002`.
3. Write `docs/adr/ADR-0001-hermes-integration.md`: real `hermes-agent` capabilities vs. spec assumptions, and decide per `core/` module **build-custom vs. defer-to-Hermes** (prefer Hermes for routing/sessions/compression; custom for the quota guard, board orchestration, GUI-test flow).
4. If a real Hermes install is available, do **PKG-1** (resolve the `# VERIFY:` markers in `scripts/setup-ama-profiles.sh`) and **PKG-2** (end-to-end install test). If not, mark them blocked-on-environment and proceed.
5. Then continue the `core/` build from **B0-2** (project skeleton) onward.

---

## TASK CHECKLIST (V1 pilot — from BUILD_PLAN.md)

### Packaging — Hermes tap (ADR-0002)
- [x] Author 8 skills (`skills/ama-*`)
- [x] Author 5 bundles (`skill-bundles/ama-*.yaml`)
- [x] Draft 6 profile `SOUL.md` (`profiles/ama-*`)
- [x] `config/settings.yaml` (tier→model + board seats)
- [x] `scripts/setup-ama-profiles.sh` (profile bootstrap)
- [x] `templates/PROJECT_BRIEF.md`
- [ ] PKG-1 Verify setup script against real Hermes (resolve `# VERIFY:` markers)
- [ ] PKG-2 End-to-end install test (tap add → setup → profiles/skills/bundles usable)
- [ ] PKG-3 Dry-run framework-vs-project flow on a throwaway project

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

### Handoff — 2026-05-26 — packaging build session
- DONE this session: Built the full packaging scaffold on top of ADR-0002. Authored **8 skills** (`skills/ama-*`), **5 bundles** (`skill-bundles/ama-*.yaml`), **6 dedicated-profile `SOUL.md`** drafts (`profiles/ama-*`), `config/settings.yaml`, an idempotent `scripts/setup-ama-profiles.sh`, and `templates/PROJECT_BRIEF.md`. Rewrote the README around the portable install/use model and appended a "Packaging as a Hermes tap" section (PKG-1/2/3) to BUILD_PLAN. Authoring was done by Haiku subagents; every file was reviewed and corrected before each commit.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; tap scaffold complete and pushed (commits up to `9ad4767`); no `core/` code or tests yet; tap NOT yet tested on a real Hermes.
- LEARNED / GOTCHAS: (1) Skills must be portable — no hardcoded build-branch names or AMA-internal task IDs (fixed several such leaks). (2) Bundle `instruction:` is a top-level YAML key (sibling of `skills:`). (3) The `/ama-board` bundle is intentionally lean `[ama-board, ama-session-handoff]` — keep board SOULs consistent with it. (4) `scripts/setup-ama-profiles.sh` has `# VERIFY:` markers — exact Hermes CLI must be confirmed on a real install (PKG-1). (5) Skills are instructions-first; they reference `core/` scripts only as optional helpers. (6) Haiku subagents sometimes revise a file after a first write — re-read before final review/commit.
- NEXT: B0-1 (ADR-0001 reconciliation, unblocked) → PKG-1/PKG-2 if a Hermes env exists → continue `core/` from B0-2.
- BLOCKERS / WAITING ON HUMAN: confirm the "AMA" name + GitHub repo rename (a settings action you perform); provide provider keys/Telegram token when ready (mock until then); PKG-1/2 need a real Hermes install to verify CLI commands.

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
