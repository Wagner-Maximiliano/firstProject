# V1 Pilot — Build Plan

> **Status:** Ready to hand off to build sessions.
> **Reads with:** `SESSION_PROTOCOL.md` (how sessions operate), `STATE.md` (live progress), `HUMAN_RUNBOOK.md` (what the human does), and the design in `../FRAMEWORK_SPEC.md` / `../OVERVIEW.md`.
---

## 1. What we're building (and what "V1 pilot" means)

We are building an **autonomous multi-agent orchestration system** that runs on top of **Hermes** (`hermes-agent`). It drives a software project from idea to shipped product using a team of AI agents, with the human involved only at planning/sign-off, GUI testing, and go-live. The full design is in `../FRAMEWORK_SPEC.md`.

**V1 pilot = the smallest version that proves the whole loop end-to-end on one tiny real project, single-stream (no parallelism yet).** It must demonstrate:

1. A non-developer describes an idea → guided planning (progressive disclosure) → human sign-off.
2. The orchestrator turns the plan into a task DAG and drives a **single stream**: Builder → empirical + adversarial checks → Reviewer → PR merged to a trunk-protected `main`.
3. One flagged decision goes to a **3-vendor Board** (rubric scoring + "prove it or lose it").
4. A **per-phase human test guide** + isolated test env, with **Telegram** pass/fail.
5. A **watchdog + quota guard** keep it alive across vendor hiccups and 5-hour windows.
6. **Go-live only on human approval.**
7. The build itself **survives many sessions** (the meta-goal — see `SESSION_PROTOCOL.md`).

**Explicitly OUT of V1 (deferred to "Beyond V1", §7):** true multi-stream parallelism with worktrees/leases, a real merge queue, rich dashboards, and production hardening. Build the simplest thing that works; leave clean seams for these.

**Pilot success criterion (the demo):** from a one-paragraph idea, the system ships a working tiny app (e.g. a "personal links page" or "to-do list with a single screen") to a staging URL, with the human only: signing off the plan, passing the GUI test, and approving go-live.

---

## 2. Tech stack (decided — don't re-litigate, just build)

| Concern | Choice | Notes |
|---|---|---|
| Language | **Python 3.11+** | Matches Hermes; `.venv` per project (rule from spec §14b). |
| Agent runtime / model gateway | **Hermes (`hermes-agent`)** | Provider routing, per-task slots, retries, compression, session persistence. **Verify real API in B0-1.** |
| Orchestration core | **Our own small Python package** (`core/`) | The business rules (DAG, scheduling, escalation, board, watchdog) stay ours — not captive to a framework. |
| Runtime state store | **SQLite** (file: `helm.db`) | DAG, leases, heartbeats, quota meters, event log. Survives restarts. |
| Source of truth | **GitHub** | Issues = tasks, PRs = work, Projects v2 = Kanban, `/docs/adr` = decisions. |
| CI | **GitHub Actions** | Lint, type-check, tests, build. The T0 backbone. |
| Lint/format/type | **ruff + black + mypy** | Enforced in pre-commit and CI. |
| Tests | **pytest** | Acceptance criteria become tests. |
| Human channel | **Telegram** (`python-telegram-bot`) | Send + tap-to-answer. |
| Config | **YAML** (`config/settings.yaml`) | Tier→provider map, thresholds, vendors, budgets. |
| Secrets | **Environment variables / env secret store** | NEVER committed. Anthropic / OpenAI / 3rd-vendor / Telegram keys. |

**Offline/dev-friendliness:** include a **mock provider** so the loop can be developed and tested without burning real quota. Real providers switch on via config.

---

## 3. Project structure (target)

```
core/                      # the orchestration package (our code)
  __init__.py
  gateway/                 # thin interface over Hermes; tier→provider routing
  agents/                  # agent definitions (Planner, Builder, Reviewer, Board, InvertedReviewer...)
  orchestrator/            # the loop: DAG, scheduler, kanban sync, integrator
  board/                   # rubric scoring + prove-it-or-lose-it protocol
  quality/                 # T0 runners (tests/lint), inverted reviewer, escalation ladder
  watchdog/                # heartbeats, recovery ladder, quota guard
  human/                   # telegram, planning (progressive disclosure), test-guide generator
  state/                   # SQLite store + event log + checkpoint/resume
config/
  helm.yaml                # tiers, providers, thresholds (no secrets)
prompts/                   # agent system prompts (Planner/Builder/Reviewer/Board/InvertedReviewer)
scripts/                   # T0 deterministic scripts (git, kanban moves, env setup)
tests/                     # pytest suite for the framework itself
.github/workflows/         # CI
docs/autonomous-agents/    # design + this build package (already here)
```

Build sessions create this incrementally; it does not all appear at once. **Note:** `prompts/` is already seeded with starter agent job descriptions (Concierge, Planner, Builder, Inverted Reviewer, Reviewer, Board Member) — refine these rather than writing them from scratch when you reach the relevant tasks.

---

## 4. Cross-cutting build rules

- **Never commit to `master`/`main`.** Build on the build branch (see `SESSION_PROTOCOL.md`). Trunk protection is set up in B0-3 and applies thereafter.
- **Scripts-first.** Anything deterministic (git, kanban moves, env setup, test runs) is a plain script in `scripts/`, not a model call.
- **Test-as-you-go.** Every module ships with pytest tests; CI must stay green on the build branch.
- **Comment the *why*.** Per spec §14 — handover-readable.
- **Record decisions as ADRs** in `docs/adr/` (start at ADR-0001 in B0-1).
- **Secrets via env only.** If a key is missing, fall back to the mock provider and note it as a blocker for the human.

---

## 5. The build phases & tasks (V1 pilot)

Format per task — **Goal / Deliverable / Done when / Verify**. Task IDs seed `STATE.md`. Tasks are sized to fit in roughly one session each (some may span two — that's fine, sub-progress is tracked in STATE.md).

### Phase B0 — Foundations & spec reconciliation

**B0-1 · Verify Hermes & reconcile the design**
- *Goal:* Replace assumptions with facts about `hermes-agent`'s real API.
- *Deliverable:* `docs/adr/ADR-0001-hermes-integration.md` — actual capabilities (provider config, task slots, session persistence, compression, retries), how the orchestrator will call it, and any deltas from `FRAMEWORK_SPEC §16`.
- *Done when:* a minimal "hello, route to a provider via Hermes" spike runs (mock acceptable if keys absent), and the ADR is committed.
- *Verify:* spike script runs in CI or locally; ADR reviewed by the human only if it changes the architecture.

**B0-2 · Project skeleton**
- *Goal:* Bootable Python project.
- *Deliverable:* repo structure (§3), `.venv` setup script, `pyproject.toml`, ruff/black/mypy config, pre-commit, empty `core/` package, `README` for developers.
- *Done when:* `scripts/setup.sh` builds a venv and `pytest` runs (even if only a placeholder test) green.
- *Verify:* fresh-clone setup works; lint/format/type pass.

**B0-3 · GitHub backbone**
- *Goal:* The model-free spine.
- *Deliverable:* branch protection on `main` (PR required, CI required, no direct push), Projects v2 board with columns (Backlog/Ready/In Progress/In Review/Blocked/Done) + label scheme (`stream:* tier:* risk:* complexity:*`), issue/PR templates, a CI workflow running lint+type+tests.
- *Done when:* a test PR cannot merge until CI is green; cards exist; CI runs on push.
- *Verify:* open a throwaway PR and confirm protection + CI behave.

**B0-4 · Model gateway over Hermes**
- *Goal:* `gateway.get_model(tier)` abstraction + tier→provider config.
- *Deliverable:* `core/gateway/` with config-driven mapping (T1 free, T2, T3, Board seats A/B/C across 3 vendors), a **mock provider**, and a smoke test per configured provider.
- *Done when:* code requests "a T2 model" and gets one; switching providers is config-only; mock works with no keys.
- *Verify:* `pytest tests/gateway` green with mock; real-provider smoke test documented for when keys are present.

**B0-5 · State store + checkpoint/resume**
- *Goal:* Durable runtime state (distinct from the build's `STATE.md`).
- *Deliverable:* `core/state/` SQLite schema (tasks/DAG, leases, heartbeats, quota meters, append-only event log) + checkpoint/resume helpers.
- *Done when:* state survives a process restart; an interrupted run resumes from the last checkpoint.
- *Verify:* test that kills and restarts a fake run and confirms continuity.

**B0-6 · Telegram channel**
- *Goal:* Send + receive tap-to-answer.
- *Deliverable:* `core/human/telegram.py` — send a message with inline option buttons, receive the choice; graceful no-op if token absent.
- *Done when:* a manual test message round-trips (or is cleanly mocked).
- *Verify:* mocked test green; real round-trip documented for when token present.

**B0-7 · Quota & rate guard (skeleton)**
- *Goal:* Manage 5-hour windows + free-first routing.
- *Deliverable:* `core/watchdog/quota.py` — per-vendor rolling-window meter, soft-threshold downgrade to free, window-reset auto-resume.
- *Done when:* simulated window exhaustion reroutes to free/other vendor without crashing.
- *Verify:* unit test simulating limits.

### Phase B1 — The core autonomous loop (single stream)

**B1-1 · Planning (progressive disclosure) + sign-off**
- *Goal:* Idea → plan, the human's one big job.
- *Deliverable:* `core/human/planning.py` + `prompts/planner.md`, `prompts/concierge.md`. Concierge (T1) triages; Architect (T3) drives **business-impact domains** with dive-deeper/trust controls; emits PRD + tech spec + **task DAG** + acceptance criteria + ADRs; presents an assumption ledger; waits for human sign-off via Telegram/CLI.
- *Done when:* a sample idea produces a committed plan + DAG and pauses for sign-off.
- *Verify:* run on the pilot toy idea; human confirms the plan reads correctly in plain language.

**B1-2 · Orchestrator loop (single stream)**
- *Goal:* Drive the DAG.
- *Deliverable:* `core/orchestrator/` — load DAG, pick the next ready task, move Kanban cards (scripted), event-driven (consume CI/PR events; no model-polling).
- *Done when:* given a DAG, it schedules tasks in order and updates the board.
- *Verify:* test with a 3-task fake DAG.

**B1-3 · Builder agent**
- *Goal:* Implement one task.
- *Deliverable:* `core/agents/builder.py` + `prompts/builder.md` — on a `task/<id>` branch, write code + tests + why-comments, open a draft PR.
- *Done when:* a trivial task yields a branch + draft PR with passing tests.
- *Verify:* end-to-end on one toy task.

**B1-4 · Empirical + adversarial escalation**
- *Goal:* No reliance on self-reported confidence (spec §5.3–5.4).
- *Deliverable:* `core/quality/` — T0 runner (tests/lint/build) with the "N failures in a row → escalate" rule; **inverted reviewer** (T1) producing a skepticism score; the escalation ladder.
- *Done when:* repeated test failure auto-escalates tier; inverted reviewer flags a planted bug.
- *Verify:* tests with deliberately broken code confirm escalation fires.

**B1-5 · Reviewer + Integrator**
- *Goal:* Safe merge to trunk.
- *Deliverable:* `core/agents/reviewer.py` (T2, ≠ builder model) + `core/orchestrator/integrator.py` — review PR, on approval+green merge via PR, delete branch, move card to Done.
- *Done when:* a green, approved PR merges and the branch is cleaned up.
- *Verify:* full builder→reviewer→merge on a toy task.

**B1-6 · Human test guide + test env + Telegram gate**
- *Goal:* GUI verification by the human (spec §14b).
- *Deliverable:* `core/human/test_guide.py` — generate the 5-part guide (what/run/check/expect/if-wrong), boot an isolated `.venv` test env with seeded data, post to Telegram, collect pass/fail.
- *Done when:* a phase produces a guide + runnable env; human pass moves it to Done, fail opens an issue.
- *Verify:* human runs one real guide and reports it was clear.

**B1-7 · Board (3 vendors)**
- *Goal:* Cross-checked big decisions (spec §7).
- *Deliverable:* `core/board/` + `prompts/board_member.md` — rubric scoring (cost/security/maintainability, 1–10), mandatory floors, **prove-it-or-lose-it** vetoes, ADR output; convened only on §7.1 triggers.
- *Done when:* a flagged decision is scored by 3 vendors and resolved by thresholds; a veto without a patch is discarded.
- *Verify:* test with a planted "obviously worse" proposal (rejected) and a "needs a real alternative" veto.

**B1-8 · Watchdog + recovery (minimal)**
- *Goal:* Don't stall (spec §11).
- *Deliverable:* `core/watchdog/` — heartbeats, stale detection, recovery ladder (retry → failover via gateway → requeue → escalate to Telegram).
- *Done when:* a simulated provider outage fails over without human help; a truly stuck task escalates.
- *Verify:* fault-injection tests.

**B1-9 · Go-live gate**
- *Goal:* Human-approved release (spec §10).
- *Deliverable:* a deploy step that **blocks on explicit human approval** via Telegram before anything reaches users; staging deploy may be automatic.
- *Done when:* deploy to staging is automatic; prod/go-live requires a human tap.
- *Verify:* attempt go-live without approval (blocked); with approval (proceeds).

### Phase B2 — Pilot dry run

**B2-1 · End-to-end pilot**
- *Goal:* Prove the whole thing.
- *Deliverable:* run the framework end-to-end on the pilot toy idea start→finish; capture gaps in `docs/autonomous-agents/build/PILOT_REPORT.md`; fix blockers; list deferred items.
- *Done when:* the success criterion (§1) is met — a working tiny app reaches staging with only the 3 human touchpoints.
- *Verify:* the human completes the full journey and signs off the pilot report.

---

## 6. Decisions to capture as ADRs early

ADR-0001 Hermes integration (B0-1) · ADR-0002 state store schema · ADR-0003 tier→provider mapping & default models · ADR-0004 board rubric thresholds · ADR-0005 escalation thresholds (N failures, K deviations). Keep them short.

---

## 7. Beyond V1 (do NOT build now — leave seams)

Phase 2 parallel streams (git worktrees + file leases) · real merge queue · richer observability dashboards · planning polish (more visual A/B) · security hardening + runbooks · extracting Helm into its own repo. These map to `FRAMEWORK_SPEC §18` Phases 2–6.

---

## 8. Open inputs from the human (non-blocking — sensible defaults exist)

Provider keys (Anthropic/OpenAI/3rd) + Telegram bot token (via env secrets, not chat) · default models per tier + 3 board vendors · the pilot toy idea (or let the first planning run choose one) · escalation patience window. All have defaults in `config/settings.yaml`; the build proceeds on mocks until keys arrive.
