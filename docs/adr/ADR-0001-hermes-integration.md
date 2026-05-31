# ADR-0001 — Hermes integration boundary for AMA core

- Status: Accepted
- Date: 2026-05-31
- Relates to: FRAMEWORK_SPEC §16, ADR-0002 (tap+profiles), ADR-0003 (project bootstrap+routing)

## Context

B0-1 requires replacing assumptions with verified Hermes behavior and deciding, module-by-module, what AMA should build itself vs defer to Hermes.

The spec already intends Hermes as substrate, but some statements were still assumption-level (for example “8 specialized task slots” and “hermes models list”). We verified against a real local install in this session.

Verified environment:
- Hermes installed and runnable: `Hermes Agent v0.15.1 (2026.5.29)`
- CLI families present: `profile`, `skills`, `bundles`, `config`, `sessions`, `cron`, `gateway`, etc.
- Profile isolation exists and is visible via `hermes profile show` (per-profile path, model, .env, SOUL.md, skills)
- Config supports per-profile writes: `hermes -p <profile> config set ...`
- Skill taps supported: `hermes skills tap add <owner/repo>`
- Context compression is native and enabled (shown in `hermes config show`)
- Session persistence is native (`sessions` command family + persisted profile home)

Deltas discovered vs spec/script assumptions:
1) The command `hermes models list` is not available in v0.15.1. Model selection appears under `hermes model` (interactive) and current defaults can be read from `hermes config show`.
2) `hermes skills install` accepts one identifier per invocation, not a space-separated list of eight skill names in one call.
3) Bundle location assumptions in setup script are uncertain. Hermes has first-class `hermes bundles` management; copying YAML manually to `~/.hermes/profiles/<name>/bundles` should be treated as fallback only.
4) “8 specialized task slots” is not directly exposed as a CLI concept in current help output; treat that as implementation detail, not a hard contract for AMA design.

## Decision

Use Hermes-native capabilities wherever they already solve the concern; keep custom AMA logic only where business rules are unique to AMA.

### Build-vs-defer by planned module

1) `core/gateway/` (routing/provider wiring)
- Defer to Hermes for provider abstraction, default model selection, per-profile isolation, retries/fallback primitives, compression/session handling.
- Build a thin AMA adapter only: role/tier intent -> Hermes invocation/config contract, plus explicit validation that required profiles/models are configured.
- Rationale: avoid recreating a model gateway Hermes already provides.

2) `core/agents/` (role behavior)
- Defer agent runtime execution to Hermes (skills + profiles + tool runtime).
- Build custom AMA role contracts/prompts and routing policy (owner/tier labels, separation-of-duties checks).
- Rationale: Hermes runs agents; AMA defines orchestration rules.

3) `core/orchestrator/` (DAG, scheduling, GitHub flow)
- Build custom.
- Rationale: task DAG semantics, label routing contract, branch/PR choreography, and phase batching are AMA-specific business logic.

4) `core/board/` (3-vendor decision system)
- Build custom.
- Rationale: rubric scoring thresholds, prove-it-or-lose-it veto protocol, and ADR emission are not Hermes-native.

5) `core/quality/` (T0 checks + adversarial gate)
- Build custom with script-first execution.
- Rationale: escalation triggers and skepticism scoring policy are framework rules.

6) `core/watchdog/` (heartbeats/recovery)
- Hybrid.
- Defer transport-level retry/failover primitives to Hermes where available.
- Build custom project-level watchdog policy (stale task detection, GitHub inactivity logic, circuit-breakers, escalation policy).

7) `core/watchdog/quota.py` (5-hour window guard)
- Build custom (priority custom area).
- Rationale: per-vendor rolling-window budgeting and free-first policy are central AMA requirements not guaranteed by Hermes defaults.

8) `core/human/telegram.py` and `core/human/test_guide.py`
- Hybrid.
- Defer interactive messaging in-session to Hermes-native Telegram bridge where possible.
- Build custom test-guide generation, pass/fail semantics, and per-phase GUI verification workflow.
- Keep a narrow fallback path for out-of-band watchdog notifications if Hermes session/channel constraints require it.

9) `core/state/` (SQLite durable runtime state)
- Build custom.
- Rationale: AMA needs explicit DAG/lease/heartbeat/quota/event schemas independent of chat transcript state.

10) `scripts/` and GitHub automation
- Build custom deterministic scripts (T0 backbone).
- Rationale: this is the model-free spine of the framework and project contract.

## Consequences

Positive:
- Smaller core surface area and less duplicate infrastructure.
- Faster delivery for B0-B1 because routing/session/compression concerns are delegated to Hermes.
- Cleaner portability story: AMA rules remain independent while runtime substrate can change later.

Trade-offs:
- Setup script must be revised to real Hermes CLI behavior (especially skill install loops and model discovery UX).
- Some Hermes internals are intentionally abstracted; AMA must validate capability by observed commands rather than assuming hidden internals.

## PKG-1 / PKG-2 status from this session

- Real Hermes install is available (confirmed).
- PKG-1 partially advanced by CLI reconciliation (verified command families and mismatches above).
- PKG-2 not fully executed in this session because end-to-end installation (tap add + profile provisioning + skill installs) still depends on updating the setup script to the verified command behavior first.

## Follow-ups

1) Update `scripts/setup-ama-profiles.sh` to remove/resolve current `# VERIFY` assumptions:
   - replace `hermes models list` usage
   - install skills one-by-one (or via fully verified alternative)
   - prefer `hermes bundles` management over guessed bundle-copy paths
2) After script patch, execute full PKG-1/PKG-2 end-to-end validation.
3) Begin B0-2 project skeleton with the Hermes boundary above as implementation constraint.