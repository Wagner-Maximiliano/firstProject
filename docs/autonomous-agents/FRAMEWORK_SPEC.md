# Autonomous Agent Delivery Framework — Detailed Technical Specification

> **Status:** Draft v0.1 — for review
> **Audience:** Technical. This is the exhaustive version. A plain-language companion lives in `OVERVIEW.md`.
> **Goal:** A reusable system ("the machine that builds projects") in which a team of AI agents takes a software project from idea to shipped product with the human involved *only* during planning and sign-off.

---

## 1. Design principles (the non-negotiables)

These are the rules every part of the system must obey. They are derived directly from the project brief.

1. **Human touches only the plan.** After the plan is signed off, the system runs autonomously. Humans are pulled back in *only* when an issue is genuinely unrecoverable or a guardrail demands it.
2. **Trunk is sacred.** No agent ever commits to `main`/`master`. All work happens on branches; trunk changes only via reviewed, approved, CI-green pull requests through a merge queue.
3. **Scripts before models.** Any task that can be done deterministically by code (git ops, linting, formatting, test runs, board moves, status checks, health pings) is done by code — never by a model call. Models are reserved for reasoning.
4. **Cheapest capable model wins.** Work is routed to the lowest-cost model that can do it well. Escalation to expensive models is the exception, triggered by measured complexity/risk — not the default.
5. **Big decisions are never made alone.** High-impact or irreversible decisions go to a multi-vendor **Approval Board** where independent models from different vendors cross-check each other.
6. **The system must not stall.** Heartbeats, watchdogs, and recovery logic keep work flowing through disconnections, rate limits, token exhaustion, and stuck PRs — without waking the human.
7. **Quality is not sacrificed for cost.** Cost optimization stops at the line where product quality would suffer.
8. **Everything is legible.** Code is commented for handover (the *why*, not the *what*), decisions are recorded as ADRs, and the repo is the single source of truth.
9. **Portability.** The orchestration core is decoupled from any single vendor or hosting platform via a model-gateway abstraction. We focus on one implementation now, but lock-in is avoided by design.

---

## 2. Glossary

| Term | Meaning |
|---|---|
| **Agent** | A configured role = (system prompt + tools + model tier + budget + guardrails). Not a model. |
| **Model tier** | A cost/capability band (T0 scripts → T3 frontier reasoning). |
| **Stream** | An independent line of work (e.g. "auth", "billing UI") that can progress in parallel. |
| **Board** | The multi-vendor panel that approves high-impact decisions. |
| **ADR** | Architecture Decision Record — a short markdown file capturing a decision + rationale. |
| **Lease** | A short-lived lock an agent holds on a file/area to prevent concurrent edits. |
| **Heartbeat** | A periodic scripted health check that emits a signal and triggers recovery on silence. |
| **Gateway** | The model-router abstraction; the only component that knows vendor SDKs/keys. |

---

## 3. System architecture (overview)

```
                        ┌──────────────────────────────────────────────┐
   HUMAN (planning only) │  PLANNING PHASE                              │
        │                │  Concierge (T1) ⇄ Architect/Planner (T3)     │
        ▼                │  → Plan artifacts + human sign-off gate      │
  ┌───────────┐          └───────────────────────┬──────────────────────┘
  │ Concierge │                                  │ signed-off plan
  └───────────┘                                  ▼
                          ┌─────────────────────────────────────────────┐
                          │  ORCHESTRATOR (mostly scripts + T1 model)    │
                          │  • reads plan → builds task DAG              │
                          │  • schedules streams, assigns work           │
                          │  • owns Kanban + merge queue                 │
                          └───┬───────────────┬───────────────┬─────────┘
                              │               │               │
                  ┌───────────▼──┐   ┌────────▼─────┐  ┌──────▼────────┐
                  │ Builder(s)   │   │ Reviewer(s)  │  │ QA / Tester   │
                  │ T1–T2        │   │ T2           │  │ T0 scripts+T1 │
                  └──────┬───────┘   └──────┬───────┘  └──────┬────────┘
                         │                  │                 │
                         ▼ (big decision?)  ▼                 ▼
                  ┌──────────────────────────────────────────────────┐
                  │  APPROVAL BOARD (multi-vendor: Anthropic / OpenAI │
                  │  / OpenRouter-OSS) — independent cross-check vote │
                  └──────────────────────────────────────────────────┘

      ╔══════════════════════════════════════════════════════════════╗
      ║  ALWAYS-ON: Watchdog/Heartbeat (scripts) + Budget Guard +      ║
      ║  Model Gateway (vendor abstraction) + Telemetry/Audit log      ║
      ╚══════════════════════════════════════════════════════════════╝
```

The shaded always-on band is pure infrastructure: it has no "intelligence" of its own beyond cheap classification, and it keeps the intelligent parts alive and on-budget.

---

## 4. Agent roles & responsibilities

Each role is a *configuration*, not a fixed model. The "Default tier" is the starting point; the router can escalate per-task.

| Role | Default tier | Responsibilities | May escalate to | Talks to human? |
|---|---|---|---|---|
| **Concierge** | T1 (cheap, e.g. Haiku/OSS) | First contact in planning. Interprets request, scores complexity, answers simple things directly, escalates complex ones. Manages the *question budget*. | T3 Planner | **Yes** (planning only) |
| **Architect / Planner** | T3 (frontier) | Turns the conversation into a sound plan: PRD, tech spec, task DAG, acceptance criteria, ADRs. Decides architecture. | Board for big calls | Indirectly, via Concierge |
| **Orchestrator / PM** | Scripts + T1 | Runs the build loop. Builds/maintains task DAG, schedules streams, assigns issues, manages Kanban + merge queue, enforces WIP limits. Almost no reasoning — mostly deterministic. | T2 for ambiguous scheduling | No |
| **Builder** | T1–T2 | Implements a single task on a feature branch: code + tests + docs. Simple tasks T1, real coding T2. | T3 for hard problems | No |
| **Reviewer** | T2 | Reviews PRs for correctness, style, security, test coverage. Distinct model instance from the Builder (no self-review). | T3 / Board | No |
| **QA / Tester** | Scripts + T1 | Runs the test suite, linters, type-checks, builds, and (where possible) drives the app to verify behavior. Reports pass/fail with evidence. | T2 to interpret failures | No |
| **Integrator** | Scripts + T2 | Owns the merge queue: rebases, resolves trivial conflicts, merges green/approved PRs, deletes branches. | Board for risky merges | No |
| **Approval Board** | T3 × multiple vendors | Independent review + vote on high-impact decisions. | Human (last resort tie-break) | No |
| **Watchdog** | Scripts + T1 | Heartbeats every agent/stream, detects stalls/failures, triggers recovery, enforces budgets. | Escalates to human if unrecoverable | Alerts only |

> **Separation-of-duties rule:** the model instance that *writes* code is never the same instance that *approves* it. Builder ≠ Reviewer ≠ Board member, even if they share a tier.

---

## 5. Model routing & cost tiers

### 5.1 Tiers

| Tier | Use for | Example models (you have keys; final choice configurable) |
|---|---|---|
| **T0** | Deterministic work — git, lint, format, tests, board moves, health checks, regex/AST edits | *No model.* Pure scripts. |
| **T1** | Triage, classification, summarization, complexity scoring, simple/templated edits, commit messages, PR descriptions | Claude Haiku; free OpenRouter OSS (e.g. Nvidia Nemotron-free, Llama/OSS, Nous Hermes) |
| **T2** | The bulk of real coding, code review, test authoring, moderate debugging | Claude Sonnet; GPT-class mid models |
| **T3** | Planning, architecture, hard debugging, security-sensitive design, Board votes, tie-breaks | Claude Opus; GPT frontier; one strong OpenRouter model |

### 5.2 The router

The router is **mostly deterministic**, with a cheap model only for fuzzy classification:

```
route(task):
    if task.type in DETERMINISTIC_SET:          # tests, lint, git, board moves
        return T0_SCRIPT
    score = complexity_score(task)               # see §6, T0 heuristics + optional T1
    if task.risk == HIGH or task.irreversible:   # see §7 board criteria
        return BOARD                             # multi-vendor, regardless of score
    if score <= LOW_THRESHOLD:   return T1
    if score <= MID_THRESHOLD:   return T2
    return T3
```

### 5.3 Escalation ladder (within a running task)

An agent does **not** silently struggle. It escalates on explicit triggers:

1. **Self-confidence below threshold** (agent reports `confidence < 0.7` on its own output) → escalate one tier.
2. **N failed attempts** (default N=2: e.g. tests still red after 2 fix cycles) → escalate one tier.
3. **Touches a board-criteria area** (see §7) → go to Board, skip tiers.
4. **Budget guard says "downgrade"** → forced de-escalation (with a flag that quality risk was accepted) or pause.

Escalation always carries the full context bundle (task, attempts, errors) so the higher tier doesn't restart from zero.

---

## 6. Complexity & confidence model

### 6.1 Complexity score (cheap to compute)

A 0–100 score computed primarily by **T0 heuristics**, with an optional T1 sanity check:

| Signal | Weight | Source |
|---|---|---|
| Files/modules touched | + | git/AST (T0) |
| Lines changed (estimate) | + | T0 |
| Crosses module/stream boundary | + | DAG metadata (T0) |
| Touches security/auth/payments/data-migration | +++ | path + keyword rules (T0) |
| New dependency / infra / schema change | +++ | manifest diff (T0) |
| Ambiguity in spec | ++ | T1 classifier |
| Prior failures on this task | ++ | state log (T0) |

Thresholds (`LOW`, `MID`) are configurable and tuned over time from outcome data.

### 6.2 Confidence and the "98%" idea

You asked for high confidence before acting. We operationalize this:

- **Planning confidence:** the Planner keeps asking (within the question budget) until its self-assessed understanding clears a configurable bar (your "98%"). It states the bar and its current estimate to the human at the sign-off gate.
- **Decision confidence:** for Board decisions, confidence = agreement among independent vendors (see §7.4). A split board *is* low confidence and forces either more analysis or human input.
- **Build confidence:** a task is "done" only when QA evidence (green tests, passing build, optional runtime check) backs it — confidence is *demonstrated*, not *claimed*.

---

## 7. The multi-vendor Approval Board

### 7.1 What counts as a "big decision" (Board triggers)

The Board convenes automatically when a proposal does any of:

- Changes architecture, public API contracts, or the data schema.
- Adds/removes a dependency, or changes infrastructure/CI/CD.
- Touches security, auth, secrets, payments, or personal data.
- Is irreversible or hard to undo (data migration, deletion, release/tag).
- Exceeds a blast-radius threshold (e.g. > N files or > M streams affected).
- Exceeds a single-action cost threshold.
- Is flagged `risk: HIGH` by the router.

Everything else proceeds without the Board — most day-to-day coding does **not** convene it (cost control).

### 7.2 Board composition

3–4 **independent** members drawn from **different vendors** (using your separate keys):

- Seat A: Anthropic frontier (e.g. Opus)
- Seat B: OpenAI frontier
- Seat C: a strong OpenRouter model (different lineage)
- (Optional) Seat D: a 4th vendor / open model for odd-numbered quorum and diversity

Vendor diversity is the point: correlated blind spots within one vendor are reduced when reviewers come from different training lineages.

### 7.3 Protocol (cross-check, both directions)

```
1. PROPOSE   — proposing agent writes a decision brief (problem, options,
               recommendation, rationale, risks) → an ADR draft.
2. INDEPENDENT REVIEW — each board member reviews the brief *blind* to the
               others' verdicts. Output: {verdict, confidence, objections}.
3. CROSS-CHECK — members now see each other's objections and respond
               (defend / concede / revise). This is the "A checks B and B
               checks A" loop, generalized to N members.
4. RECONCILE — a neutral tally (T0 script) computes the outcome (§7.4).
5. RECORD    — the finalized ADR (with dissents) is committed to /docs/adr.
```

### 7.4 Voting & tie-breaks

| Outcome | Rule |
|---|---|
| **Approved** | Quorum met (e.g. ≥3 seats) **and** supermajority agree (e.g. ≥75%). |
| **Approved w/ conditions** | Majority approve but raise must-fix objections → conditions attached to the task. |
| **Split / low-confidence** | No supermajority → escalate: (a) one more analysis round with more context, then (b) if still split, **human** is asked a single, well-framed question. |
| **Rejected** | Supermajority against → proposal returns to Planner/Builder with the consolidated objections. |

A split board is a *feature*: it is the system honestly reporting "we are not confident," which is exactly when a human (or more thought) is warranted.

### 7.5 Cost control for the Board

- Board only convenes on real triggers (§7.1).
- Briefs are concise and cached; members get the brief + relevant diff, not the whole repo.
- Reviews run in **parallel** across vendors.
- A cheap T1 pre-screen can reject obviously-broken proposals before spending T3 board time.

---

## 8. Git & GitHub workflow

### 8.1 Trunk protection (rule #2, enforced mechanically)

- Branch protection on `main`: no direct pushes, require PR, require CI green, require ≥1 review (Board approval for flagged PRs), require linear history, require up-to-date branch.
- Agents authenticate with a token that **lacks** direct-push rights to `main`. The rule is enforced by GitHub, not by agent goodwill.

### 8.2 Branching model

- `main` — always releasable.
- `stream/<name>` — long-lived integration branch per parallel stream (optional, for big streams).
- `task/<issue-#>-<slug>` — short-lived, one per task/issue. Deleted after merge.
- Convention enforced by a T0 script; non-conforming branches are auto-renamed or rejected.

### 8.3 PR lifecycle

```
draft PR opened (Builder)
   → CI runs (tests, lint, type, build, security scan)   [T0]
   → QA agent attaches verification evidence              [T0 + T1]
   → Reviewer agent review (≠ Builder model)              [T2]
   → if board-flagged: Approval Board                     [T3 multi-vendor]
   → Integrator: rebase, merge via merge queue            [T0/T2]
   → branch deleted, issue moved to Done, ADRs updated    [T0]
```

- **Conventional Commits** + semantic PR titles (enforced by T0 lint).
- PR description auto-generated (T1) from the diff + linked issue.
- Stale-PR sweeper (T0, see §11) nudges or reassigns PRs idle past a threshold.

### 8.4 Kanban (GitHub Projects v2)

Board columns and the automation that moves cards (all **scripted**, no model needed):

| Column | Enter when | Exit when |
|---|---|---|
| **Backlog** | Issue created from plan DAG | Dependencies satisfied |
| **Ready** | All blocking deps merged | Builder assigned |
| **In Progress** | Branch opened | Draft PR opened |
| **In Review** | PR ready for review | Approved + green |
| **Blocked** | Dep missing / failing / awaiting Board | Unblocked |
| **Done** | Merged to `main` | — |

- Every task = one GitHub Issue. Labels encode `stream:*`, `tier:*`, `risk:*`, `complexity:*`.
- WIP limits per column prevent the system from fanning out beyond budget/parallelism caps.

---

## 9. Parallel work streams

### 9.1 Dependency DAG

The Planner emits the plan as a **directed acyclic graph** of tasks with explicit dependencies. The Orchestrator topologically sorts it and runs all independent frontier nodes concurrently, up to a configured parallelism cap.

### 9.2 Isolation: git worktrees

Each active stream/task runs in its own **git worktree** (separate working directory, shared repo). This lets multiple Builders work truly in parallel without stepping on each other's files.

### 9.3 Conflict avoidance: file leases

- Before editing, a Builder requests a **lease** on the files/dir it will touch (a lightweight record in orchestrator state).
- Overlapping lease requests are serialized or the tasks are re-sequenced.
- Leases expire (anti-deadlock) and are reaped by the Watchdog.

### 9.4 Merge queue

- Integrator merges one PR at a time against the latest `main`, re-running CI on the *combined* result to catch semantic conflicts that textual merges miss.
- On merge-queue conflict, the affected task is rebased and re-validated automatically; only persistent conflicts escalate.

---

## 10. The orchestration loop (pseudocode)

```python
# Runs continuously after plan sign-off. Mostly T0; T1 only for fuzzy bits.
while project.not_complete():
    refresh_state_from_repo()              # issues, PRs, CI, board — source of truth

    # 1. unblock and schedule
    for task in dag.newly_ready():
        move(task, "Ready")
    for task in pick_ready(up_to=WIP_LIMIT - active_count()):
        agent = spawn_builder(tier=route(task))      # §5
        lease = acquire_lease(task.files)            # §9.3
        assign(task, agent, worktree=new_worktree())

    # 2. advance in-flight work (event-driven, not polled in tight loop)
    handle_pr_events()      # CI done → QA → review → board? → merge
    handle_review_outcomes()
    handle_board_outcomes()

    # 3. health + budget (delegated to always-on watchdog, see §11)
    watchdog.tick()
    budget_guard.tick()

    sleep_until_next_event()   # event-driven; no busy-wait, no wasted tokens
```

Key point: the loop is **event-driven and script-driven**. It consumes GitHub webhooks/CI events rather than burning model calls to "check if anything happened."

---

## 11. Anti-staleness & self-healing

This is the always-on layer that satisfies "the project doesn't get stale" and "proactively continue on issues."

### 11.1 Heartbeats

- Every active agent/stream emits a heartbeat (last-activity timestamp) to orchestrator state.
- A **scripted** sweeper runs on an interval (cron/loop). On silence past a threshold it triggers recovery — no model needed to notice silence.

### 11.2 What the Watchdog detects

| Symptom | Detection (T0) | Recovery |
|---|---|---|
| Agent silent / hung | Heartbeat stale | Kill + re-spawn task with saved context |
| Model/vendor disconnect | API error / timeout | **Failover** to alternate vendor in same tier via Gateway (§16) |
| Rate limit hit | 429 / quota error | Backoff + reroute to alternate vendor; queue task |
| **Token/budget exhaustion** | Budget Guard meter | Downgrade tier where safe; pause low-priority streams; alert if hard cap |
| Stuck PR | Idle > threshold | Nudge reviewer / reassign / rebase |
| Failing CI loop | N consecutive red | Escalate tier; if still red, mark Blocked + open diagnostic issue |
| Infinite/oscillating fix loop | Repeated near-identical diffs | Circuit-breaker: stop, escalate to T3/Board |
| Whole-project idle | No card movement in window | "Nudge" pass re-evaluates backlog, re-schedules |

### 11.3 Recovery ladder (cheapest first)

```
retry (same model, backoff)
   → failover (alternate vendor, same tier)        # Gateway
   → re-queue (return task to Ready, fresh worktree)
   → escalate tier (more capable model)
   → circuit-break + open diagnostic issue
   → human alert (LAST resort, with full context)
```

### 11.4 Budget Guard

- Tracks spend per task / stream / phase / project against caps.
- Soft cap → prefer cheaper tiers, throttle parallelism.
- Hard cap → pause non-critical streams, alert human.
- Per-vendor spend tracked separately (you have separate keys) for cost attribution.

---

## 12. Token & cost optimization

| Technique | What it does |
|---|---|
| **Scripts-first (rule #3)** | The single biggest saver. No model call for anything deterministic. |
| **Tiered routing (§5)** | Cheap/free models do the high-volume low-reasoning work. |
| **Prompt caching** | Cache stable context (system prompts, repo conventions, plan) across calls. |
| **Context minimization** | Agents get only the files/diffs they need (retrieval), never the whole repo. |
| **Event-driven loop** | No polling-by-model; the orchestrator waits on webhooks/CI events. |
| **Result caching** | Re-use prior analysis/decisions (ADRs) instead of recomputing. |
| **Batching** | Group small T1 classifications into single calls where possible. |
| **Board frugality (§7.5)** | Frontier multi-vendor calls only on real triggers, run in parallel, on concise briefs. |
| **Telemetry** | Per-tier/per-vendor spend dashboards to find and cut waste over time. |

---

## 13. Human-in-the-loop: the planning phase

The *only* place the human is required. It must feel effortless to a non-developer and still produce a rigorous plan.

### 13.1 Flow

```
Human idea
  → Concierge (T1): interprets, scores complexity, answers easy stuff,
                     escalates the substantive design questions
  → Architect/Planner (T3): conducts a focused interview, drafts:
        • PRD (what & why, in plain language)
        • Tech spec (architecture, stack, data model)
        • Task DAG (the buildable breakdown)
        • Acceptance criteria (how we know it's right)
        • Initial ADRs (key decisions + rationale)
  → Plan reviewed by a mini-Board (sanity + feasibility + cost estimate)
  → HUMAN SIGN-OFF GATE  ← the one mandatory approval
  → autonomy begins
```

### 13.2 The question budget (don't overload the human)

- A **hard cap** on number of questions per session (configurable, e.g. 5–8), plus a complexity-gated escape hatch.
- Concierge (cheap) handles trivial clarifications; only design-critical questions reach the human.
- Questions are **batched** and offered as **multiple-choice with a recommended default** wherever possible, so a non-developer can answer by picking, not by typing technical prose.
- Each question must pass a test: *"Would a wrong answer here materially change the plan?"* If not, the system picks a sensible default and notes the assumption for sign-off.

### 13.3 "What they asked" vs "what they actually want"

To close the alignment gap:

- **Restate-and-confirm:** the Planner restates the goal in plain language + concrete examples before building the plan.
- **Show, don't tell:** where useful, generate a mockup, sample output, or user-story walkthrough for the human to react to.
- **Acceptance criteria as contract:** the human signs off on *observable outcomes*, not jargon.
- **Assumption ledger:** every default/assumption is listed at the gate so silent misalignment surfaces early.

### 13.4 Which model talks to the human?

Per your question — **yes, a cheap model (T1/Haiku-class) is the front door.** Its job is interpretation + triage + complexity scoring. It answers what it can and escalates only design-critical, high-complexity turns to the T3 Planner. This keeps the high-volume conversational tokens cheap and spends frontier tokens only on the moments that shape the plan.

---

## 14. Code quality, documentation & handover

(Your explicit requirement: code must be readable by another model later.)

- **Comment the *why*, not the *what*.** Explain constraints, invariants, trade-offs, and non-obvious decisions — not restatements of the code. (What-comments rot and add noise; why-comments are the ones a future model needs.)
- **Module/interface docs** at boundaries (what this module is for, its contract).
- **ADRs** record every significant decision + rationale in `/docs/adr` — the project's reasoning is versioned alongside its code.
- **Tests are documentation:** acceptance criteria become tests; tests describe intended behavior.
- **CI gates** enforce these (lint for comment/doc presence at boundaries, coverage thresholds) so quality isn't optional.
- **Handover README** per module, auto-maintained (T1) from the code + ADRs.

---

## 15. State, memory & observability

- **Source of truth = the repo + GitHub:** issues (tasks), PRs (work), Projects board (status), ADRs (decisions), plan docs (intent). An agent can be killed and respawned and rebuild its understanding from these.
- **Orchestrator state store:** lightweight DB/file for the DAG, leases, heartbeats, budget meters, event log. Append-only event log = full audit trail.
- **Observability:** dashboards for stream status, cost per tier/vendor/phase, board decisions, recovery events. Everything an operator needs to trust the system without intervening.

---

## 16. Recommended tech stack (my advice on "Hermes" / portability)

> **Open question — please confirm:** by "Hermes" did you mean **Nous Research's Hermes models** (which I'd slot in as a capable T1/T2 or a Board seat via OpenRouter), or a specific **orchestration platform** named Hermes? My recommendation below is designed so that either answer fits without rework.

**Recommendation — a thin portable core + a vendor gateway:**

1. **Model Gateway (the key to portability).** A single abstraction layer (e.g. a LiteLLM-style router, or a small custom adapter) is the *only* component that holds vendor SDKs and keys. Every agent calls "give me a T2 model," not "call OpenAI." This delivers:
   - **No lock-in** — swap vendors/models via config, satisfying "don't want to be stuck in one place."
   - **Failover** — the Watchdog reroutes across vendors automatically (§11.2).
   - **Multi-vendor Board** — trivial, since the gateway already speaks to all of them.

2. **Orchestration core.** Keep it small and own the critical logic (DAG, scheduling, leases, merge queue, heartbeats). You may build this on a lightweight existing framework for the state-machine/graph parts, but the *business rules above* should be yours so you're not captive to a framework's roadmap.

3. **Execution substrate.** Run agents wherever you like; the gateway makes the choice reversible. For "focus in one place for now," pick a single host/runtime and a single repo for the orchestrator — breadth can come later precisely because the gateway abstracts it.

4. **GitHub** for trunk protection, PRs, Projects/Kanban, and CI — these are the scripted, model-free backbone.

The spirit of your constraint ("one place for now, but not stuck there") is satisfied structurally: **one implementation, zero lock-in, because vendor/runtime choices live behind the gateway.**

---

## 17. Security & safety guardrails

- **Least privilege:** agent tokens scoped narrowly; no direct `main` push; secrets never in prompts or logs (secret-scanning in CI).
- **Sandboxed execution:** builders run in isolated, ephemeral environments.
- **Human-required boundaries:** production deploys, spending real money, deleting data, and external communications require explicit human authorization regardless of Board confidence.
- **Audit trail:** every decision and action is logged and attributable.
- **Prompt-injection defense:** treat repo content, issue/PR text, and tool output as untrusted; the gateway/agents flag suspicious instructions rather than obeying them.

---

## 18. Phased build roadmap

| Phase | Deliverable | Proves |
|---|---|---|
| **0. Foundations** | Repo, trunk protection, CI, Kanban automation, Model Gateway, telemetry, budget guard | Scripts-first backbone works |
| **1. Single-stream autonomy** | Planner → DAG → one Builder → Reviewer → QA → merge, on one stream | The core loop ships code safely |
| **2. Parallelism** | Worktrees, leases, merge queue, multiple streams | Parallel work without collisions |
| **3. The Board** | Multi-vendor approval on flagged decisions + ADRs | High-stakes decisions are cross-checked |
| **4. Self-healing** | Heartbeats, watchdog, failover, recovery ladder | Survives disconnects/limits/stalls unattended |
| **5. Planning polish** | Concierge triage, question budget, alignment tooling, sign-off gate | Great non-developer experience |
| **6. Hardening** | Cost tuning, security review, observability, runbooks | Production-grade, trustworthy |

Each phase is independently demonstrable and adds one capability — so the system is useful early and de-risked incrementally.

---

## 19. Failure modes & mitigations

| Failure mode | Mitigation |
|---|---|
| Agent commits to `main` | Mechanically impossible (branch protection + scoped token). |
| Two builders edit same file | File leases + worktrees + merge-queue re-validation. |
| Vendor outage / rate limit | Gateway failover to alternate vendor; backoff + requeue. |
| Token budget blown | Budget Guard: tier downgrade, throttle, hard-cap pause + alert. |
| Endless fix loop | Circuit-breaker on repeated diffs → escalate/Block. |
| Board deadlock | More-context round, then a single human question. |
| Over-questioning human | Question budget + "would a wrong answer change the plan?" test. |
| Silent misalignment | Restate-and-confirm + assumption ledger + acceptance criteria at sign-off. |
| Unreadable handover | Why-comments + ADRs + module docs enforced in CI. |
| Cost creep | Scripts-first + tiered routing + per-vendor telemetry. |
| Project goes stale | Nudge loop + stale-PR sweeper + heartbeat-driven recovery. |
| Correlated model blind spot | Multi-vendor Board (different training lineages). |

---

## 20. Open questions / decisions I need from you

1. **"Hermes" meaning** (see §16) — model family or platform?
2. **Budget caps** — per-project and/or monthly hard caps for the Budget Guard?
3. **Human availability** — when the system *must* escalate, what's the contact channel and expected latency (so the Watchdog knows how long it may safely wait)?
4. **Board size** — 3 or 4 seats? (3 is cheaper and breaks ties naturally; 4 adds diversity at higher cost.)
5. **Deploy authority** — are production deploys always human-gated, or may the system deploy to staging autonomously and prod on schedule?
6. **Preferred per-tier models** — your default picks for T1/T2/T3 from the vendors you hold keys for.
7. **Question-budget size** — your comfort level for max questions during planning (e.g. 5 vs 8).

---

## 21. Illustrative cost intuition (not a quote)

The economics work because of *mix*, not magic:

- The vast majority of operations are **T0 scripts** = $0 in model cost.
- High-volume reasoning (triage, summaries, simple edits, PR text) is **T1** = cheap/often free.
- Real coding/review is **T2** = moderate.
- Only **planning, hard problems, and Board votes** hit **T3** — rare, but where the money is well spent.

The Budget Guard + telemetry mean you see exactly where spend goes and can retune thresholds — quality is protected because escalation is always *available*; it's just not the *default*.

---

*End of detailed specification. See `OVERVIEW.md` for the plain-language version.*
