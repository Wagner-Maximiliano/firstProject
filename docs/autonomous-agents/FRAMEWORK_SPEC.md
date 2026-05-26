# Autonomous Agent Delivery Framework — Detailed Technical Specification

> **Status:** Draft v0.2 — for review. v0.2 incorporates an external NotebookLM critique (objective board rubric + actionable vetoes; empirical/adversarial escalation instead of self-reported confidence; progressive-disclosure planning).
> **Audience:** Technical. This is the exhaustive version. A plain-language companion lives in `OVERVIEW.md`.
> **Goal:** A reusable system ("the machine that builds projects") in which a team of AI agents takes a software project from idea to shipped product with the human involved *only* during planning and sign-off.

---

## 1. Design principles (the non-negotiables)

These are the rules every part of the system must obey. They are derived directly from the project brief.

1. **Human touchpoints are few and defined.** There are exactly three: **(a)** planning + sign-off, **(b)** hands-on testing of any graphical UI, per phase, and **(c)** go-live approval. Beyond these, the system runs autonomously and pulls the human back in *only* when an issue is genuinely unrecoverable or a guardrail demands it.
2. **Trunk is sacred.** No agent ever commits to `main`/`master`. All work happens on branches; trunk changes only via reviewed, approved, CI-green pull requests through a merge queue.
3. **Scripts before models.** Any task that can be done deterministically by code (git ops, linting, formatting, test runs, board moves, status checks, health pings) is done by code — never by a model call. Models are reserved for reasoning.
4. **Cheapest capable model wins.** Work is routed to the lowest-cost model that can do it well. Escalation to expensive models is the exception, triggered by measured complexity/risk — not the default.
5. **Big decisions are never made alone.** High-impact or irreversible decisions go to a multi-vendor **Approval Board** where independent models from different vendors cross-check each other.
6. **The system must not stall.** Heartbeats, watchdogs, and recovery logic keep work flowing through disconnections, rate limits, token exhaustion, and stuck PRs — without waking the human.
7. **Quality is not sacrificed for cost.** Cost optimization stops at the line where product quality would suffer.
8. **Everything is legible.** Code is commented for handover (the *why*, not the *what*), decisions are recorded as ADRs, and the repo is the single source of truth.
9. **Portability.** The orchestration core is decoupled from any single vendor or hosting platform via a model-gateway abstraction. We focus on one implementation now (Hermes — see §16), but lock-in is avoided by design.
10. **Go-live is human-gated.** Nothing reaches real users without explicit human approval (rule #1c). The system may build, test internally, and stage freely — but the final release switch is the human's.
11. **GUIs are always human-tested.** Anything with a graphical interface is verified by a human, because machines can't yet judge a UI the way a user does. Every phase ships a plain-language **human test guide** plus an isolated, ready-to-run **test environment** (rule #1b).
12. **The project must survive many sessions.** No single conversation/context window holds the project together. All durable state lives in the repo and an external store, so the system can be stopped, resumed, or moved without losing the plot or overflowing context.
13. **Live within subscription limits.** There is no dollar budget; there are *quota windows* (notably rolling 5-hour usage caps on paid Anthropic/OpenAI tiers). The system prefers free/cheap models and actively manages those windows so it never gets throttled mid-flight.

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
| **Gateway** | The model-router abstraction; the only component that knows vendor SDKs/keys. **Played by Hermes** (§16). |
| **Quota window** | A vendor's rolling usage cap (e.g. the ~5-hour caps on paid Anthropic/OpenAI tiers). The scarce resource we manage instead of dollars. |

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
      ║  ALWAYS-ON: Watchdog/Heartbeat (scripts) + Quota Guard +       ║
      ║  Hermes (model routing/gateway) + Telegram + Telemetry/Audit   ║
      ╚══════════════════════════════════════════════════════════════╝
```

The shaded always-on band is pure infrastructure: it has no "intelligence" of its own beyond cheap classification, and it keeps the intelligent parts alive and on-budget.

---

## 4. Agent roles & responsibilities

Each role is a *configuration*, not a fixed model. The "Default tier" is the starting point; the router can escalate per-task.

| Role | Default tier | Responsibilities | May escalate to | Talks to human? |
|---|---|---|---|---|
| **Concierge** | T1 (cheap, e.g. Haiku/OSS) | First contact in planning. Interprets request, scores complexity, answers simple things directly, escalates complex ones. Drives *progressive disclosure* (§13.2). | T3 Planner | **Yes** (planning only) |
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

An agent does **not** silently struggle — and crucially, **escalation is never triggered by a model's self-reported confidence.** Models are poor at gauging their own correctness zero-shot (the "ask a toddler if it's tired" problem — they confidently emit broken code), so self-assessment would silently bypass the safety net. Triggers are *empirical and external*:

1. **Empirical failure (primary).** T0 QA — compile/build/tests/lint/type-check — fails **N times in a row** (default N=3). The environment, not the model's opinion, declares confidence functionally zero → escalate one tier. It doesn't matter if the model claims 99% confidence; the test suite says otherwise.
2. **Adversarial reviewer flags it.** A cheap **inverted reviewer** (§5.4) scores the builder's output against the acceptance criteria and finds ≥K critical deviations (default K=3) → escalate. This breaks the self-assessment echo chamber by judging output externally.
3. **Touches a board-criteria area** (see §7) → go to Board, skip tiers.
4. **Quota Guard says "downgrade"** (paid window nearly spent) → forced de-escalation to a free model (with a flag that quality risk was accepted) or defer until the window resets.

Escalation always carries the full context bundle (task, attempts, errors, reviewer findings) so the higher tier doesn't restart from zero.

### 5.4 The inverted reviewer (cheap adversarial critic)

A deliberately *cheaper* T1 model is pointed at the (more capable) T2 builder's output with one job: **hunt for flaws** against the acceptance criteria. This works because of the **generation-vs-verification asymmetry** — writing correct code needs heavy reasoning, but spotting a missing edge case or broken contract needs far less, so a small, fast, often-free model is an effective critic.

- Input: the builder's diff + the strict acceptance criteria. Prompt: find deviations, don't be agreeable.
- Output: a **skepticism score** + a list of concrete deviations.
- The score is an *escalation trigger* (§5.3), not a merge gate — the T2 Reviewer and T0 CI remain the gates. It is cheap insurance that catches the "confidently wrong" case the builder won't catch itself.
- Defense in depth: empirical (T0) **and** adversarial (T1) triggers run together, so a blind spot in one is caught by the other.

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

You asked for high confidence before acting. We operationalize it **empirically** — never by trusting a model's own claim of confidence (§5.3):

- **Planning confidence:** the Planner surfaces questions via progressive disclosure (§13.2) until the design is grounded, then the human confirms at the sign-off gate — so "98%" is *verified by a human*, not self-graded by the model.
- **Decision confidence:** for Board decisions, confidence = rubric scores clearing objective thresholds (§7.4), not subjective agreement. Genuine, evidence-backed divergence (a low score defended by a working alternative patch) is the rare real signal that warrants human input.
- **Build confidence:** a task is "done" only when external evidence backs it — green T0 tests/build, a clean inverted-reviewer pass (§5.4), and (for GUIs) human verification (§14b). Confidence is *demonstrated*, never *claimed*.

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

**Three** independent seats, each a frontier model from a **different vendor** (using your separate keys). Three is deliberate: it's the minimum for real cross-checking, it breaks ties naturally (no deadlock from an even split), and it's the cheapest configuration that still gives vendor diversity.

- Seat A: Anthropic frontier (e.g. Opus)
- Seat B: OpenAI frontier
- Seat C: a strong third-vendor model of a different lineage (via OpenRouter or direct)

Vendor diversity is the point: correlated blind spots within one vendor are reduced when reviewers come from different training lineages.

### 7.3 Protocol (cross-check, both directions)

```
1. PROPOSE   — proposing agent writes a decision brief (problem, options,
               recommendation, rationale, risks), pre-mapped to the rubric
               axes (§7.4) → an ADR draft.
2. SCORE     — each member independently and *blind* scores the proposal on
   (blind)     the fixed rubric (cost / security / maintainability, 1–10)
               with a one-line justification per axis. Members argue on
               *identical axes*, not personal style — this stops drift.
3. ACTIONABLE VETO ("prove it or lose it") — any sub-threshold ("no") score
               MUST ship with a concrete, compiling code-level alternative or
               pseudo-code patch proving the objection is fixable. A veto with
               no actionable alternative is discarded as noise.
4. CROSS-CHECK — members see each other's scores + patches and may revise
               (defend / concede / revise). "A checks B, B checks A", over 3.
5. RECONCILE — a T0 script applies the math thresholds (§7.4); the outcome is
               computed, not debated.
6. RECORD    — the finalized ADR (scores, surviving objections, any adopted
               patch) is committed to /docs/adr.
```

### 7.4 Scoring rubric & thresholds (objective, not subjective)

**Why not raw voting:** different model lineages have different coding philosophies baked in by their training (one favours terse DRY abstraction, another verbose explicitness). Asking them merely to "agree" makes a *split the default state* — they deadlock on style, not substance, and keep waking the human, breaking rule #6. So the board does **not** vote on agreement; it **scores against a shared rubric**, and approval is a **math function of the scores.**

**The rubric (tri-factor, configurable, 1–10 each):**

| Axis | What each member scores |
|---|---|
| **Cost** | Build/run/maintenance cost and quota-window impact of this choice. |
| **Security** | Risk to data, secrets, auth, users. |
| **Maintainability** | Readability, handover, blast radius, reversibility. |

(A project may add one axis, e.g. *performance*, but the set is fixed *before* scoring so nobody invents bespoke criteria mid-debate.)

**Thresholds (example, tuned from outcomes over time):**

| Outcome | Rule |
|---|---|
| **Approved** | Mean of each axis ≥ 7 **and** no mandatory floor breached. |
| **Mandatory floor** | For security/data/irreversible changes, **every** member's Security score must be ≥ 8; any sub-floor score blocks regardless of the mean. |
| **Approved w/ conditions** | Passes thresholds but carries surviving (patch-backed) objections → those become must-fix conditions on the task. |
| **Evidence-backed divergence** | Scores straddle a threshold *and* a sub-threshold vote is backed by a working alternative patch → the real signal: escalate to the **human** (Telegram, §11.5) with the competing patches attached. Rare by design. |
| **Rejected** | Below threshold → returns to Planner/Builder with the consolidated scores + the best alternative patch. |

Because the outcome is computed from scores, a *stylistic* disagreement (a member dislikes an abstraction but can't produce a better compiling patch) no longer halts anything — its veto is discarded (§7.3 step 3). Only **substantive, demonstrable** disagreement reaches the human. The board is an evidence-based checkpoint, not a debate club.

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
    quota_guard.tick()

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
| Model/vendor disconnect | API error / timeout | **Failover** to alternate vendor in same tier via Hermes (§16) |
| Rate limit hit | 429 / quota error | Backoff + reroute to a **free** model or alternate vendor; queue task |
| **5-hour window nearing cap** | Quota & Rate Guard meter (§11.4) | Drain remaining paid-tier budget toward only the highest-value work; route everything else to free models; defer deferrable tasks until the window resets |
| **Window exhausted** | 429 / window-reset timestamp | Pause that vendor's tier until reset; continue on free/other-vendor models; no human alert (expected, not a failure) |
| Stuck PR | Idle > threshold | Nudge reviewer / reassign / rebase |
| Failing CI loop | N consecutive red | Escalate tier; if still red, mark Blocked + open diagnostic issue |
| Infinite/oscillating fix loop | Repeated near-identical diffs | Circuit-breaker: stop, escalate to T3/Board |
| Whole-project idle | No card movement in window | "Nudge" pass re-evaluates backlog, re-schedules |

### 11.3 Recovery ladder (cheapest first)

```
retry (same model, backoff)
   → failover (alternate vendor, same tier)        # Hermes
   → re-route to a free model where quality allows  # quota-aware
   → re-queue (return task to Ready, fresh worktree)
   → escalate tier (more capable model)
   → circuit-break + open diagnostic issue
   → human alert via Telegram (LAST resort, with full context)
```

### 11.4 Quota & Rate Guard (you have no $ budget — you have *windows*)

You run the **cheapest subscription tier on every vendor**, so the real constraint isn't dollars, it's **rolling usage windows** (notably the ~5-hour caps on paid Anthropic/OpenAI tiers) plus free-model availability. The guard manages *windows*, not spend:

- **Tracks usage per vendor against its rolling window** (tokens/requests used in the current 5-hour bucket, and time until reset). Hermes' provider layer (§16) surfaces the signals; the guard meters them.
- **Free-first routing.** Default the high-volume T1 work to free models (OpenRouter free tier, free NVIDIA models, local/Ollama OSS) so paid windows are conserved.
- **Window-budgeting.** Each paid vendor's window is a scarce resource spent only on work that genuinely needs that tier (T2/T3, Board). The guard reserves headroom so a window is never fully drained by low-value work.
- **Soft threshold** (e.g. 70% of a window used) → stop sending anything but the highest-value tasks to that vendor; everything else goes free/other-vendor.
- **Window hit** → pause that vendor's tier, keep working on free/other models, and resume automatically when the window resets — **no human alert**, because this is expected operation, not a failure.
- **Per-vendor metering** (separate keys) so each provider's window is tracked independently and the Board can always be assembled from whichever vendors still have headroom.

### 11.5 Human escalation channel: Telegram

The single channel for the rare "we need a human" moment is **Telegram** (the same kind of messaging bridge Hermes/OpenClaw already support). The Watchdog and the planning agents post to it. Each escalation message is self-contained so you can decide from your phone:

- **What/why:** one line on what's blocked and why a human is needed.
- **Context:** links to the issue/PR/ADR and the relevant log excerpt.
- **The ask:** a specific question, ideally as tappable options (approve / reject / pick A or B), not an open essay prompt.
- **Patience window:** the Watchdog knows how long it may safely wait (a config you set) before pausing the affected stream — so escalations don't silently rot, and the rest of the project keeps moving meanwhile.

Used for: split Board on an irreversible call (§7.4), GUI test sign-off (§14b), go-live approval (§10), and unrecoverable failures only.

---

## 12. Token & cost optimization

| Technique | What it does |
|---|---|
| **Scripts-first (rule #3)** | The single biggest saver. No model call for anything deterministic. |
| **Tiered routing (§5)** | Cheap/free models do the high-volume low-reasoning work. |
| **Free-first + window-aware routing (§11.4)** | Default to free models; spend scarce paid 5-hour windows only on T2/T3/Board work. |
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

### 13.2 Progressive disclosure, not a hard cap

A rigid numerical cap (the old "5–8 questions") is the wrong tool: complex software involves *discovering unstated needs*, and capping questions forces the AI to silently invent defaults for everything unasked — producing a large assumption ledger a non-technical human will rubber-stamp, authorizing downstream technical debt they never understood. (The "architect pours the concrete after you picked only the door colour" problem.)

Instead, planning uses **progressive disclosure organised by business-impact domain:**

- **Cluster by domain, framed in business terms — never jargon.** e.g. *what it does* (core logic), *look & feel* (UI), *your data & privacy*, *cost trade-offs*, *speed & scale*. Ask "search speed vs storage cost", not "database indexing strategy."
- **2–3 high-leverage questions per domain**, then two buttons: **"dive deeper"** or **"trust the AI's default"** — the human controls the pacing and spends attention only where they care (deep on privacy, default on colours).
- **Complexity-scaled (§6.1):** simple projects surface few domains and stay short; complex ones expand *only* in the domains that matter — no artificial floor or ceiling.
- **The relevance test still gates everything:** *"Would a wrong answer here materially change the plan?"* If not, default silently.
- **Smaller, safer assumption ledger:** whatever is defaulted is still logged, but it's far smaller, grouped by domain, and presented riskiest-first at the sign-off gate.

### 13.3 "What they asked" vs "what they actually want"

To close the alignment gap:

- **Restate-and-confirm:** the Planner restates the goal in plain language + concrete examples before building the plan.
- **Show, don't tell — let visuals replace questions.** Present **two wireframes/mockups** and ask "which feels closer to your vision?" Humans read visuals far faster than prose, and an A/B choice surfaces implicit preferences *without* spending an explicit question or feeling like an interrogation.
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

## 14b. Human testing & per-phase test guides

Machines can run tests, but they cannot yet *judge a graphical interface the way a user does*. So anything with a GUI is verified by a human — this is human touchpoint (b) from rule #1. The system's job is to make that as painless and foolproof as humanly possible.

### 14b.1 An isolated test environment per project

Every project ships a **ready-to-run, isolated test environment** so a non-developer can launch it without setup pain:

- A self-contained environment (e.g. a Python **`.venv`** for Python projects; the equivalent isolated, pinned environment for other stacks) with all dependencies pinned and installable by **one script**.
- A single **`run-test-env`** entry script that sets up (if needed) and launches the thing-to-test.
- Seeded sample data / fixtures so the human sees something realistic, not an empty shell.
- The environment is disposable and reproducible — it never touches production or real data.

### 14b.2 A test guide for every phase

At the end of every phase, the system generates a **plain-language test guide** (mostly assembled by T0/T1 from the phase's tasks and acceptance criteria — cheap to produce). Each guide has exactly these sections:

1. **What was done** — in plain language, what this phase added or changed.
2. **How to run it** — the literal command(s)/clicks to start the test environment.
3. **What to check** — a short checklist of things to look at or do.
4. **What you should see** — the expected result for each check (screenshots/examples where useful).
5. **If it doesn't match** — what to do when reality differs: how to report it (one tap in Telegram), what info to include, and that the system will diagnose and re-fix automatically.

The guide is written for someone with **no development skills**: no jargon, numbered steps, and a clear pass/fail for each item.

### 14b.3 The GUI verification loop

```
phase build complete (non-GUI checks already green)
  → system generates test guide + boots the test environment
  → posts guide to the human via Telegram (§11.5): "Phase X ready to test"
  → human follows steps, taps PASS or FAIL(+note) per checklist item
  → PASS → phase accepted, Kanban → Done, next phase scheduled
  → FAIL → the human's note becomes an issue; Builder/Reviewer diagnose,
            fix, re-verify automation, regenerate guide, re-request test
```

Non-GUI behavior is still verified automatically (tests, builds) and does *not* require this loop — only the human-perceivable UI does. This keeps the human's involvement bounded to exactly what only a human can judge.

---

## 15. State, memory, multi-session survival & observability

### 15.1 Single source of truth

- **The repo + GitHub:** issues (tasks), PRs (work), Projects board (status), ADRs (decisions), plan docs (intent). An agent can be killed and respawned and rebuild its understanding from these.
- **Orchestrator state store:** lightweight DB/file for the DAG, leases, heartbeats, quota meters, event log. Append-only event log = full audit trail.

### 15.2 Surviving many sessions without context overload (rule #12)

No conversation/context window is allowed to *be* the project's memory — windows are treated as disposable scratch space. This is what lets the system run for days/weeks across countless sessions:

- **Externalized state.** Everything durable lives in the repo + state store above, never only in a chat transcript. Any agent, any session, reconstructs context by *reading*, not by *remembering*.
- **Per-task context, freshly assembled.** When a task starts, the orchestrator hands the agent a small, purpose-built context pack (the task, the relevant files/diffs, the relevant ADRs) — not the whole history. Most tasks fit comfortably in a small window.
- **Compression + session persistence via Hermes.** Hermes natively compresses long conversations and persists sessions (§16); long-running agents summarize-and-checkpoint rather than letting raw history grow unbounded.
- **Rolling summaries / handoff notes.** Each stream keeps a short, current "state of this stream" note (regenerated cheaply by T1) so a resumed or replacement agent is oriented in one read.
- **Checkpoint & resume.** Progress is committed frequently (draft PRs, WIP commits) so an interrupted task resumes from the last checkpoint, not from scratch — essential given the 5-hour windows (§11.4) that *will* pause work mid-stream.
- **Idempotent, resumable steps.** Re-running a step after a restart is safe and doesn't duplicate work.

The test: **you could shut the whole system off and turn it back on tomorrow, and it would pick up exactly where it left off — because nothing important ever lived only in a model's head.**

### 15.3 Observability

Dashboards for stream status, quota-window headroom per vendor, board decisions, recovery events, and pending human asks. Everything an operator needs to trust the system without intervening.

---

## 16. Tech stack — Hermes as the substrate

**Confirmed:** "Hermes" = **Nous Research's `hermes-agent`** — an orchestration "saddle" that sits on top of the models (the same category as OpenClaw). This is a strong fit and becomes our chosen substrate. What Hermes gives us out of the box maps almost one-to-one onto this spec:

| This spec needs… | Hermes provides… |
|---|---|
| Model Gateway / vendor abstraction (§5, portability) | Provider selection across 100+ models / 200+ providers (Anthropic, OpenAI, OpenRouter, xAI, Gemini, Ollama, vLLM, llama.cpp, LM Studio…) |
| Role/tier routing (§4–5) | A primary reasoning model **+ 8 specialized task slots**, each pointing at its own provider/model/credentials — map our tiers/roles onto these slots |
| Watchdog failover (§11.2–11.3) | Built-in retries + fallback logic |
| Multi-session survival, no context overload (§12, §15.2) | Conversation **compression** + **session persistence** |
| Multi-vendor Board (§7) | Trivial — Hermes already speaks to every vendor; the 3 seats are just 3 provider configs |
| Human channel (§11.5) | Messaging bridges (Telegram), as with OpenClaw |
| Agent configuration (§4) | Personality files + skills + memory + context assembly per agent |

**How the layers stack:**

1. **Hermes = the agent/runtime + gateway layer.** Vendor keys, model routing, per-task slots, retries/fallback, compression, session persistence, messaging — all configured here. Agents are Hermes configs (personality + skills + slot routing + guardrails).

2. **Our orchestration logic sits *above* Hermes.** Hermes runs and routes individual agents; it does **not** know about our DAG scheduling, file leases, merge queue, Kanban automation, quota-window guard, or Board voting. Those are *our* scripts/state machine driving Hermes. Keeping this thin layer ours is what prevents lock-in: if we ever outgrow Hermes, only the runtime swaps — the business rules stay.

3. **GitHub = the model-free backbone** for trunk protection, PRs, Projects/Kanban, and CI.

**On "one place now, not stuck there":** Hermes itself is multi-provider by design, so committing to it does **not** lock you to any one model vendor — and because our orchestration rules live above it, even the runtime is replaceable later. You get a single place to focus today with the portability you asked for baked in.

> **Validation to do during Phase 0:** confirm Hermes' 8-slot model is enough granularity for our role set (it should map cleanly: primary→Planner/Builder, slots→Reviewer/QA/triage/summarize/etc.), and confirm its session-persistence format is something our state store can checkpoint against.

---

## 17. Security & safety guardrails

- **Least privilege:** agent tokens scoped narrowly; no direct `main` push; secrets never in prompts or logs (secret-scanning in CI).
- **Sandboxed execution:** builders run in isolated, ephemeral environments.
- **Human-required boundaries:** go-live/production deploys (§10), spending real money, deleting data, and external communications require explicit human authorization (via Telegram, §11.5) regardless of Board confidence.
- **Audit trail:** every decision and action is logged and attributable.
- **Prompt-injection defense:** treat repo content, issue/PR text, and tool output as untrusted; the gateway/agents flag suspicious instructions rather than obeying them.

---

## 18. Phased build roadmap

| Phase | Deliverable | Proves |
|---|---|---|
| **0. Foundations** | Repo, trunk protection, CI, Kanban automation, **Hermes set up** (vendors + slots), state store + checkpoint/resume, quota-window guard, Telegram bridge, telemetry | Scripts-first backbone + durable state + multi-vendor routing work |
| **1. Single-stream autonomy** | Planner → DAG → one Builder → Reviewer → QA → merge, on one stream; **per-phase test guide + `.venv` test environment**; human GUI-test loop over Telegram | The core loop ships code safely *and* a non-dev can test a phase |
| **2. Parallelism** | Worktrees, leases, merge queue, multiple streams | Parallel work without collisions |
| **3. The Board** | 3-vendor approval on flagged decisions + ADRs | High-stakes decisions are cross-checked |
| **4. Self-healing** | Heartbeats, watchdog, failover, recovery ladder, 5-hour-window handling | Survives disconnects/window resets/stalls unattended |
| **5. Planning polish** | Concierge triage, progressive disclosure by domain, visual A/B, alignment tooling, sign-off gate | Great non-developer experience |
| **6. Hardening** | Cost/window tuning, security review, observability, runbooks, go-live gate | Production-grade, trustworthy |

Each phase is independently demonstrable and adds one capability — so the system is useful early and de-risked incrementally.

---

## 19. Failure modes & mitigations

| Failure mode | Mitigation |
|---|---|
| Agent commits to `main` | Mechanically impossible (branch protection + scoped token). |
| Two builders edit same file | File leases + worktrees + merge-queue re-validation. |
| Vendor outage / rate limit | Hermes failover to alternate vendor; backoff + requeue. |
| 5-hour window exhausted | Quota Guard: pause that vendor's tier, continue on free/other models, auto-resume on reset (no alert). |
| Endless fix loop | Circuit-breaker on repeated diffs → escalate/Block. |
| Board stylistic deadlock | Objective rubric scoring (§7.4) + "prove it or lose it" vetoes; only patch-backed divergence reaches a human. |
| Model confidently ships broken code | Escalation is empirical (T0 test failures) + adversarial (inverted reviewer, §5.4) — never self-reported confidence. |
| Over- or under-questioning human | Progressive disclosure by business domain + dive-deeper/trust buttons + visual A/B (§13.2–13.3); relevance test. |
| Silent misalignment | Restate-and-confirm + visual A/B + smaller domain-grouped assumption ledger + acceptance criteria at sign-off. |
| GUI ships without human eyes | Per-phase human test guide + `.venv` test env + Telegram sign-off gate before phase accepted. |
| Context overload across sessions | Externalized state, per-task context packs, Hermes compression/persistence, checkpoint & resume. |
| Unreadable handover | Why-comments + ADRs + module docs enforced in CI. |
| Cost creep | Scripts-first + free-first routing + per-vendor window telemetry. |
| Project goes stale | Nudge loop + stale-PR sweeper + heartbeat-driven recovery. |
| Correlated model blind spot | 3-vendor Board (different training lineages). |

---

## 20. Decisions — resolved & still open

**Resolved (baked into this spec):**

| # | Decision | Where |
|---|---|---|
| Platform | Hermes (Nous `hermes-agent`) as substrate | §16 |
| Cost model | No $ budget; manage 5-hour quota windows; free-first routing | §11.4 |
| Human channel | Telegram | §11.5 |
| Board size | 3 seats, 3 vendors | §7.2 |
| Go-live | Always human-gated | §10, §17 |
| GUI testing | Human-tested per phase, with test guide + `.venv` env | §14b |
| Durability | Survive many sessions; externalized state + checkpoints | §15.2 |

**Still open (small, can be set before/while building Phase 0):**

1. **Per-tier model picks** — your default choices for T1 (free), T2, and T3, and the 3 Board vendors, from the keys you hold.
2. **Planning domains & rubric** — happy with the default business-impact domains (§13.2) and the board's tri-factor rubric/thresholds (§7.4), or want to tweak the axes/floors? (Sensible defaults already set; this is fine to leave.)
3. **Escalation patience window** — how long may the Watchdog wait on a Telegram ask before pausing the affected stream (e.g. 1h, 8h, 24h)?
4. **Project stacks** — which languages/stacks will projects use? (Drives the test-environment templates; `.venv` covers Python — we'll want equivalents for any JS/other stacks.)
5. **Telegram setup** — bot token + chat/channel ID (operational, needed at Phase 0).

---

## 21. Illustrative cost intuition (not a quote)

You have no dollar budget — you have **subscription windows**. The economics work because of *mix*, not magic:

- The vast majority of operations are **T0 scripts** = zero model usage.
- High-volume reasoning (triage, summaries, simple edits, PR text) is **T1** routed to **free** models = no window consumed.
- Real coding/review is **T2** — spends paid windows, but only when needed.
- Only **planning, hard problems, and Board votes** hit **T3** — rare, and where a paid window is well spent.

The Quota & Rate Guard + telemetry mean you see exactly how much of each vendor's 5-hour window is left and can retune thresholds — **quality is protected because escalation is always *available*; it's just not the *default*, and free models soak up the volume so paid windows last.**

---

*End of detailed specification. See `OVERVIEW.md` for the plain-language version.*
