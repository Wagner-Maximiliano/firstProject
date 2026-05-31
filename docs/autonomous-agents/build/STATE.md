# STATE — Live Build Progress (single source of truth)

> **This file is the project's memory across sessions.** Every session reads it first and updates it last (see `SESSION_PROTOCOL.md`). If something isn't written here (or in the code/commits), the next session won't know it.

---

## CURRENT STATUS

- **Phase:** B0 foundations in progress; B0-3 GitHub backbone implemented locally, remote enforcement verification blocked by missing GitHub CLI/auth in this environment
- **Active task:** _B0-3 in progress: CI + templates + enforcement script added; need remote GitHub verification_
- **Build branch:** `claude/autonomous-agent-framework-5MdEG` _(holds the handover package, prompts, tap scaffold, and project bootstrap assets; build here, keep `master` untouched)_
- **Build health:** _Local validation green after B0-3 artifacts: `pytest`, `ruff check .`, `black --check .`, `mypy core tests`._
- **Real provider keys present?:** _unknown — assume NO; use the mock provider until told otherwise_

---

## ▶ NEXT SESSION STARTS HERE

**Task B0-3 — finish remote verification, then move to B0-4.**
B0-3 artifacts are now added locally (CI workflow, templates, labels, branch-protection script/docs).
Concretely next:
1. Install/configure `gh` CLI and authenticate for this environment.
2. Run `scripts/configure_github_backbone.sh <owner/repo>` to apply labels + branch protection on `main`.
3. Open a throwaway PR to verify merge is blocked until `lint-type-test` is green and review exists.
4. If verification succeeds, mark B0-3 complete and start B0-4 model gateway scaffold.

---

## TASK CHECKLIST (V1 pilot — from BUILD_PLAN.md)

### Packaging — Hermes tap (ADR-0002)
- [x] Author 8 skills (`skills/ama-*`)
- [x] Author 5 bundles (`skill-bundles/ama-*.yaml`)
- [x] Draft 6 profile `SOUL.md` (`profiles/ama-*`)
- [x] `config/settings.yaml` (tier/seat *roles*; models chosen from Hermes at setup)
- [x] `scripts/setup-ama-profiles.sh` (profile bootstrap)
- [x] `templates/PROJECT_BRIEF.md`
- [x] PKG-1 Verify setup script against real Hermes (resolve `# VERIFY:` markers)
- [x] PKG-2 End-to-end install test (tap add → setup → profiles/skills/bundles usable)
- [x] PKG-3 Dry-run framework-vs-project flow on a throwaway project

### Phase B0 — Foundations
- [x] B0-1 Verify Hermes & reconcile design (ADR-0001)
- [x] B0-2 Project skeleton (venv, pyproject, lint/type, pytest, structure)
- [ ] B0-3 GitHub backbone (branch protection, Projects board, labels, CI) _(local artifacts done; remote verification pending)_
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

### Handoff — 2026-05-31 — B0-3 GitHub backbone local implementation
- DONE this session: Added `.github/workflows/ci.yml` (job `lint-type-test` for pytest+ruff+black+mypy on push/PR), `.github/ISSUE_TEMPLATE/ama-task.yml`, `.github/PULL_REQUEST_TEMPLATE.md`, and `.github/ama-labels.json` aligned with AMA owner/tier routing contract.
- DONE this session (ops/docs): Added `scripts/configure_github_backbone.sh` to apply labels and `main` branch protection via GitHub API (`gh api`), plus `docs/autonomous-agents/GITHUB_BACKBONE.md` documenting enforcement and verification flow.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; local quality checks green (`pytest`, `ruff check .`, `black --check .`, `mypy core tests`); remote GitHub enforcement not yet executed from this environment.
- LEARNED / GOTCHAS: `gh` CLI is not installed here (`gh: command not found`), so throwaway-PR and branch-protection verification cannot be run locally yet.
- NEXT: install/auth `gh`, run `scripts/configure_github_backbone.sh <owner/repo>`, verify throwaway PR protection behavior, then start B0-4.
- BLOCKERS / WAITING ON HUMAN: environment currently lacks `gh`; remote verification needs either `gh` installed + auth in this environment or a human-run verification on GitHub.

### Handoff — 2026-05-31 — B0-2 project skeleton session
- DONE this session: Implemented B0-2 skeleton artifacts: `pyproject.toml`, executable `scripts/setup.sh`, `.pre-commit-config.yaml`, starter `core/` package layout (`gateway/`, `agents/`, `orchestrator/`, `board/`, `quality/`, `watchdog/`, `human/`, `state/`), and `tests/test_smoke.py`.
- DONE this session (fixes): Reconciled setup to this environment constraints (`python3 -m venv` unavailable due missing `ensurepip`), switched setup flow to `uv venv` + `uv pip install -e ".[dev]`.
- DONE this session (verification): Local checks green from fresh venv path: `./scripts/setup.sh`, `pytest`, `ruff check .`, `black --check .`, `mypy core tests`.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; B0-2 checked off; next task is B0-3 GitHub backbone.
- LEARNED / GOTCHAS: In this WSL environment, a failed first venv attempt can leave a partial `.venv` (only `pyvenv.cfg`), which breaks activation. If that happens, move aside the broken directory and rerun setup.
- NEXT: start B0-3 by adding CI workflow + validating GitHub templates/branch-protection contract; if push/auth prevents live verification, log exact blocker evidence in STATE.
- BLOCKERS / WAITING ON HUMAN: push/auth blocker may still affect remote verification (`git push` over HTTPS lacks configured credentials in this session).

### Handoff — 2026-05-31 — PKG-3 dry-run verification session
- DONE this session: Executed PKG-3 on throwaway repo `/tmp/ama-pkg3-throwaway-20260531-195024` with `python3 scripts/bootstrap_ama_project.py --repo <path> --mode existing`; verified expected bootstrap files were created under `.ama/` and `.github/` and project tree remained framework-light (no framework code copied in).
- DONE this session (brief/planner): Filled `.ama/PROJECT_BRIEF.md` with a tiny pilot spec; verified planner invocation with current Hermes CLI using profile env (`HERMES_PROFILE=ama-planner hermes chat -q ... -Q`). Confirmed `/ama-plan` activates and can read/summarize `.ama/PROJECT_BRIEF.md` before questioning when explicitly instructed.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; PKG-3 checked off; next task is B0-2 project skeleton.
- LEARNED / GOTCHAS: Current Hermes v0.15.1 CLI in this environment does not support `hermes -p <profile> /ama-plan` shape directly; verified equivalent is profile-scoped `hermes chat` invocation (e.g. `HERMES_PROFILE=ama-planner hermes chat -q "/ama-plan ..." -Q`).
- NEXT: start B0-2 by creating `scripts/setup.sh`, `pyproject.toml`, lint/type/test config, starter `core/` package, and a green placeholder pytest path.
- BLOCKERS / WAITING ON HUMAN: none for PKG-3; push/auth blocker remains for origin.

### Handoff — 2026-05-31 — PKG-1/PKG-2 install verification session
- DONE this session: Patched `scripts/setup-ama-profiles.sh` to match verified Hermes v0.15.1 behavior: removed all `# VERIFY` markers, replaced `hermes models list` assumption, switched profile existence check to `hermes profile show`, corrected bundle destination to profile-local `skill-bundles/`, and fixed skills install flow.
- DONE this session (verification): Ran `hermes skills tap add Wagner-Maximiliano/AMA-Autonomous_Multi-Agent_Framework`, then executed `bash scripts/setup-ama-profiles.sh` end-to-end with explicit `AMA_MODEL_*` assignments; verified all six AMA profiles exist, each profile model was set to the expected value, and each profile has AMA bundle YAMLs loaded.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; PKG-1 and PKG-2 now checked off; no `core/` skeleton yet.
- LEARNED / GOTCHAS: unauthenticated GitHub tap resolution is rate-limited in this environment, and `hermes skills install` can return non-fatal suggestion output with exit code 0 when a skill is unresolved. Script now uses deterministic local skill-copy fallback from repo `skills/` to avoid network dependency and keep installs reproducible.
- NEXT: start PKG-3 dry-run on throwaway repo (bootstrap + planner invocation + cleanliness check), then move into B0-2 project skeleton.
- BLOCKERS / WAITING ON HUMAN: none for PKG-1/PKG-2; push to origin may still require local GitHub auth in this environment.

### Handoff — 2026-05-31 — B0-1 Hermes reconciliation session
- DONE this session: Completed B0-1 and wrote `docs/adr/ADR-0001-hermes-integration.md` with a module-by-module boundary for Hermes-native vs AMA-custom responsibilities.
- DONE this session (verification): Confirmed real Hermes install is present (`Hermes Agent v0.15.1`) and reconciled setup-script assumptions against real CLI help/behavior (`profile`, `skills tap`, `skills install`, `bundles`, `config`, profile isolation, compression/session support).
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; no `core/` code yet; B0-1 marked complete; PKG-1/PKG-2 not fully finished yet because setup script still contains command/path assumptions that must be patched before full end-to-end run.
- LEARNED / GOTCHAS: (1) `hermes models list` is not valid on this Hermes version. (2) `hermes skills install` takes one identifier per call, so the script's multi-skill single-call form is invalid. (3) Bundle path assumptions should defer to `hermes bundles` behavior rather than guessed filesystem paths.
- NEXT: patch `scripts/setup-ama-profiles.sh` to remove remaining VERIFY assumptions, then execute PKG-1 and PKG-2 end-to-end; if blocked, log exact evidence and proceed to B0-2 skeleton.
- BLOCKERS / WAITING ON HUMAN: none for ADR/B0-1; possible network/auth limits may affect live tap install verification during PKG-2.

### Handoff — 2026-05-31 — operator/bootstrap packaging pass
- DONE this session: Implemented the missing "use AMA in a real repo" layer the human asked for. Added `docs/autonomous-agents/INSTALLATION.md`, `AMA_OPERATOR_RUNBOOK.md`, and `LABEL_ROUTING.md`; added ADR-0003 for the project-adoption/routing contract; rewrote `README.md` around install + bootstrap; updated `OVERVIEW.md`, `FRAMEWORK_SPEC.md`, `BUILD_PLAN.md`, `skills/ama-github-workflow/SKILL.md`, and `scripts/setup-ama-profiles.sh` to reflect GitHub-native routing and project onboarding.
- DONE this session (artifacts): Added a lightweight project bootstrap package under `templates/project-ama/` (`.ama/PROJECT_BRIEF.md`, `.ama/STATE.md`, `.ama/config.yaml`, `.github/ama-labels.json`, issue template, PR template) plus helper scripts `scripts/bootstrap-ama-project.sh`, `scripts/bootstrap_ama_project.py`, and `scripts/bootstrap_github_labels.py`.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; local commit `3ccda8e` (`feat: add project bootstrap and github routing package`) contains the operator/bootstrap work; no `core/` code yet; bootstrap helpers verified by `python3 -m py_compile`, `bash -n`, `python3 scripts/bootstrap_github_labels.py --help`, and a local throwaway-git-repo dry-run of `bootstrap_ama_project.py`. Real Hermes CLI verification and live GitHub API label creation are still pending.
- LEARNED / GOTCHAS: (1) The operator package and the framework-build package must stay distinct in the docs or the human gets understandably confused. (2) Existing-repo adoption needs a safe boundary: AMA-labeled issues only. (3) The current bootstrap layer is parallel-ready at the contract level, but the full autonomous parallel engine still depends on later `core/` work; don't oversell that before B1/Beyond-V1 implementation catches up.
- NEXT: start with task B0-1 — write `docs/adr/ADR-0001-hermes-integration.md`, reconcile `core/` vs Hermes-native responsibilities, then if a real Hermes install is available do PKG-1/PKG-2 verification of the setup script and install flow.
- BLOCKERS / WAITING ON HUMAN: none for the doc/bootstrap work just landed; real Hermes install and a GitHub token/repo are still needed to fully verify PKG-1/PKG-2 and live label creation.

### Handoff — 2026-05-27 — model-reuse design change
- DONE: Reworked model routing to **reuse the human's existing Hermes models** instead of hardcoding IDs (human-directed). `config/settings.yaml` now records tier/seat *roles* only. `scripts/setup-ama-profiles.sh` gained `gather_models()` — it lists Hermes models (best-effort, `# VERIFY`) and picks each tier/seat model from `AMA_MODEL_*` env vars → interactive prompt → commented fallback (latest Claude IDs). Removed the per-AMA API-key requirement from README + script ("next steps"). README Prerequisites + Configuration rewritten around "AMA reuses your Hermes setup". `bash -n` passes.
- DECISIONS captured (see Resolved): reuse Hermes models + ask-at-setup; board seat C chosen at setup (pick 3 distinct vendors); pilot deferred to B1-1.
- STILL OPEN / `# VERIFY`: exact Hermes command to **list** configured models, and `hermes -p <profile> config set model.default` syntax — both to confirm in PKG-1 on a real Hermes install.
- NEXT: unchanged — B0-1 (ADR-0001 reconciliation) → PKG-1/2 if a Hermes env exists → `core/` from B0-2.

### Handoff — 2026-05-26 — packaging build session
- DONE this session: Built the full packaging scaffold on top of ADR-0002. Authored **8 skills** (`skills/ama-*`), **5 bundles** (`skill-bundles/ama-*.yaml`), **6 dedicated-profile `SOUL.md`** drafts (`profiles/ama-*`), `config/settings.yaml`, an idempotent `scripts/setup-ama-profiles.sh`, and `templates/PROJECT_BRIEF.md`. Rewrote the README around the portable install/use model and appended a "Packaging as a Hermes tap" section (PKG-1/2/3) to BUILD_PLAN. Authoring was done by Haiku subagents; every file was reviewed and corrected before each commit.
- STATE: build branch `claude/autonomous-agent-framework-5MdEG`; tap scaffold complete and pushed (commits up to `9ad4767`); no `core/` code or tests yet; tap NOT yet tested on a real Hermes.
- LEARNED / GOTCHAS: (1) Skills must be portable — no hardcoded build-branch names or AMA-internal task IDs (fixed several such leaks). (2) Bundle `instruction:` is a top-level YAML key (sibling of `skills:`). (3) The `/ama-board` bundle is intentionally lean `[ama-board, ama-session-handoff]` — keep board SOULs consistent with it. (4) `scripts/setup-ama-profiles.sh` has `# VERIFY:` markers — exact Hermes CLI must be confirmed on a real install (PKG-1). (5) Skills are instructions-first; they reference `core/` scripts only as optional helpers. (6) Haiku subagents sometimes revise a file after a first write — re-read before final review/commit.
- NEXT: B0-1 (ADR-0001 reconciliation, unblocked) → PKG-1/PKG-2 if a Hermes env exists → continue `core/` from B0-2.
- BLOCKERS / WAITING ON HUMAN: confirm the "AMA" name + GitHub repo rename (a settings action you perform); provide provider keys/Telegram token when ready (mock until then); PKG-1/2 need a real Hermes install to verify CLI commands.

---

## DECISIONS LOG (ADR index)

- **ADR-0001** (2026-05-31) — Reconciles AMA `core/` scope against real Hermes capabilities (verified on Hermes Agent v0.15.1). Decision: defer routing/session/compression/runtime concerns to Hermes; keep AMA custom logic for DAG orchestration, quota-window guard, board protocol, GUI-test flow, quality/escalation policy, and runtime state schema. Also records concrete CLI deltas to fix in setup scripts (`hermes models list` assumption invalid on this version; `hermes skills install` is single-identifier per call).
- **ADR-0002** (2026-05-26) — Distribute the framework as a **Hermes tap + dedicated profiles**. Repo becomes a tap (`skills/`), installed via `hermes skills tap add`. ~8 focused skills carry the *how*; new dedicated AMA profiles (`ama-planner/builder/reviewer/board-a/b/c`) carry the *who* in their own `SOUL.md` — the human's existing profiles are never touched. Keep the custom `core/` engine; reconcile its overlap with Hermes-native features in ADR-0001. Projects stay clean: a per-project `PROJECT_BRIEF.md` + kickoff prompt, framework lives globally in `~/.hermes`. (Superseded by completed ADR-0001 in B0-1.)
- **ADR-0003** (2026-05-31) — Adopt AMA into target projects through a **lightweight project-local bootstrap + GitHub-native routing contract**. New/existing repos get `.ama/` state/brief/config files, GitHub templates, and AMA owner/tier labels; AMA manages only AMA-labeled issues, uses one implementation issue = one branch = one PR, releases tasks in phase batches, and stays parallel-ready with overlap-aware scheduling rules.

---

## OPEN QUESTIONS / BLOCKERS

- [ ] Provider keys: AMA itself needs none (it reuses Hermes' configured providers — see Resolved). Confirm in B0-4 whether the **mock provider** path is needed for `core/` tests that run with no Hermes session.
- [ ] GitHub remote verification blocker in this environment: `gh` CLI is not installed (`gh: command not found`), and prior `git push` attempts in this session family also lacked GitHub credentials over HTTPS. Until auth/tooling is available, branch-protection + throwaway-PR verification remains pending.

### Resolved
- **B0-1 complete (2026-05-31):** ADR-0001 finalized the Hermes integration boundary: defer runtime routing/sessions/compression concerns to Hermes; keep AMA custom for quota guard, board orchestration protocol, GUI-test flow, orchestrator/state/quality policies.
- **Portability** (was open): the framework is NOT copied into projects. It's a **Hermes tap** installed once per machine; each project carries only a small `PROJECT_BRIEF.md` + `STATE.md`. See ADR-0002.
- **Project adoption model** (2026-05-31): AMA installs into a target repo through a lightweight bootstrap package (`templates/project-ama/` + helper scripts), not by copying the whole framework. Existing repos are adopted conservatively: AMA manages only AMA-labeled issues. See ADR-0003.
- **GitHub routing contract** (2026-05-31): AMA-managed issues use exactly one `ama:owner:*` label and one `ama:tier:*` label; implementation flow is one issue = one branch = one PR, with phase-batched issue creation and overlap-aware parallel routing. See ADR-0003 + `docs/autonomous-agents/LABEL_ROUTING.md`.
- **Name confirmed: "AMA".** (An optional GitHub repo rename stays a human settings action; if you rename, update the `AMA_TAP_REPO` value / your `hermes skills tap add` argument to match.)
- **Human channel = Hermes' existing Telegram** (human confirmed it's configured & connected): AMA reuses it, so no separate AMA bot/token is needed for normal interactive use. Only out-of-band messaging needs the B0-1 check above.
- **Model routing reuses Hermes' existing models** (2026-05-27, human-directed): AMA does **not** hardcode model IDs or carry its own provider keys. `config/settings.yaml` records only the *role* of each tier (T1/T2/T3) and board seat; the **setup script asks the human which existing Hermes model to assign** to each role (interactive prompt, or `AMA_MODEL_*` env vars so an installing agent can pass the human's choices non-interactively). Latest-Claude IDs (Opus 4.7 / Sonnet 4.6 / Haiku 4.5) are kept only as commented fallback examples.
- **Board seat C vendor** (was open, Q2): not pinned in the repo — chosen at setup from existing Hermes models. Guidance: pick three *different* vendors across seats A/B/C for real cross-vendor diversity.
- **Pilot toy-project: deferred** (human chose "decide later") — the Planner proposes one at planning time (B1-1).

---

## ENVIRONMENT / SETUP NOTES

- Python in this environment: `python3` available; `python` shim and `pip` module not reliable for project bootstrap.
- Use `uv` for venv + deps (`uv venv .venv` and `uv pip install -e ".[dev]`) — this is what `scripts/setup.sh` now does.
- If `.venv` exists but activation fails, inspect for partial venv (for example only `pyvenv.cfg` after failed `ensurepip` path), move it aside, then rerun `./scripts/setup.sh`.
- Current baseline validation command set:
  - `./scripts/setup.sh`
  - `source .venv/bin/activate && pytest && ruff check . && black --check . && mypy core tests`
