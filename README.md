# Helm — Autonomous Agent Framework (V1 Pilot)

This repository contains the design and build plan for **Helm**, a multi-agent orchestration system that drives software projects from idea to shipping with minimal human involvement.

## Quick Start

If you're starting a fresh build session, read:

1. **`docs/autonomous-agents/build/HUMAN_RUNBOOK.md`** — your (non-developer) guide. Contains the copy-paste prompts to kick off a build.
2. **`docs/autonomous-agents/build/SESSION_PROTOCOL.md`** — the rules every build session must follow (so progress survives across sessions).
3. **`docs/autonomous-agents/build/STATE.md`** — the live progress file. This is where the build agent reads "what's next" and writes "what I did."

## The Design

If you want to understand the framework itself (not building it, just reading it):

- **`docs/autonomous-agents/OVERVIEW.md`** — plain-English explanation (no jargon).
- **`docs/autonomous-agents/FRAMEWORK_SPEC.md`** — the full technical spec (all details, all trade-offs).

## For Build Sessions

### Starting a new session

Paste the appropriate prompt from `HUMAN_RUNBOOK.md` (§2):
- **First session ever:** KICKOFF prompt
- **Every session after:** RESUME prompt

The agent will guide itself from there using the files above.

### Configuration (tier→model mapping)

Once building starts, you'll have a `config/helm.yaml` file that maps model tiers to actual providers:

```yaml
tiers:
  T1:                    # cheap, high-volume: triage, summaries, adversarial review
    provider: "openrouter"
    model: "nvidia/nemotron-mini"  # free tier
  T2:                    # mid-range: real coding, code review
    provider: "anthropic"
    model: "claude-sonnet-4-20250514"
  T3:                    # frontier: planning, hard problems
    provider: "anthropic"
    model: "claude-opus-4-1"

board:                   # 3-vendor approval board
  seat_a:
    provider: "anthropic"
    model: "claude-opus-4-1"
  seat_b:
    provider: "openai"
    model: "gpt-4o"
  seat_c:
    provider: "openrouter"
    model: "anthropic/claude-opus"  # routed through OpenRouter
```

**To adjust tiers** (e.g. upgrade builders to T2–T3, make Planner/Board T4):
1. Edit `config/helm.yaml` — change the model names and which roles use which tiers.
2. Restart the agents; they'll pick up the new routing automatically.
3. No code changes needed — the tiers are configuration, not hardcoded.

**Environment variables** (never commit these):
- `ANTHROPIC_API_KEY` — your Anthropic key
- `OPENAI_API_KEY` — your OpenAI key
- `OPENROUTER_API_KEY` — your OpenRouter key (for free + 3rd-vendor models)
- `TELEGRAM_BOT_TOKEN` — Telegram bot token
- `TELEGRAM_CHAT_ID` — your Telegram chat ID

Set these in your session environment's secret settings, not in the repo.

## Project Structure

```
docs/autonomous-agents/
  OVERVIEW.md              # Plain-English design
  FRAMEWORK_SPEC.md        # Full technical specification
  build/
    BUILD_PLAN.md          # What to build, in what order
    SESSION_PROTOCOL.md    # How every session must operate
    HUMAN_RUNBOOK.md       # Non-dev guide + copy-paste prompts
    STATE.md               # Live progress (source of truth)
    PILOT_REPORT.md        # (created after V1 pilot completes)

prompts/
  README.md                # Agent job descriptions guide
  concierge.md             # Greeter: triages + paces planning
  planner.md               # Architect: turns idea into plan
  builder.md               # Worker: implements one task
  inverted_reviewer.md     # Cheap critic: finds flaws
  reviewer.md              # Gatekeeper: PR approval
  board_member.md          # One of three board seats

helm/                      # (created during build)
  gateway/                 # Model routing over Hermes
  agents/                  # Agent implementations
  orchestrator/            # Task scheduling, Kanban sync
  board/                   # Board voting + scoring
  quality/                 # Tests, linting, escalation
  watchdog/                # Heartbeats, recovery, quota guard
  human/                   # Planning, testing, Telegram
  state/                   # SQLite store, event log
  
config/
  helm.yaml                # Tier→model mapping (created during build)
  
tests/                     # (created during build)
scripts/                   # (created during build)
```

## Building the Framework

The build happens across multiple sessions (you can't do it all at once).

**What each session does:**
1. Reads `STATE.md` to find the next task.
2. Works on that task, committing often.
3. Updates `STATE.md` with progress + the next task's starting point.
4. When done or context-full, wraps up cleanly and hands off.

**To continue building after a session:**
- Start a fresh session and paste the RESUME prompt.
- It reads `STATE.md`, picks up where the last one left off, and continues.
- No context is lost because everything lives in the repo.

See `BUILD_PLAN.md` for the full task list and phase breakdowns.

## Testing & CI

Once the skeleton exists, CI (GitHub Actions) will run:
- `ruff` — linting
- `mypy` — type checking
- `black` — code formatting
- `pytest` — tests

These must all be green on the build branch before merging to `main`.

## Questions?

- **About the design:** read `FRAMEWORK_SPEC.md` or `OVERVIEW.md`.
- **About building it:** read `SESSION_PROTOCOL.md` and `BUILD_PLAN.md`.
- **About running a session:** read `HUMAN_RUNBOOK.md`.

---

**Status:** Planning & design complete. Ready for V1 pilot build. Start with the KICKOFF prompt in `HUMAN_RUNBOOK.md`.
