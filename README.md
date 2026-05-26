# AMA — Autonomous Multi-Agent Framework

**AMA is a portable, Hermes-based framework for driving software projects from idea to ship with minimal human involvement.** Delivered as a global Hermes tap (installed once per machine), it orchestrates a team of AI agents through planning, building, review, and approval—the human is only needed at three touchpoints: planning sign-off, GUI testing, and go-live approval.

*AMA is a working name (avoiding "Ask Me Anything" collision).*

## How it's delivered

AMA is a **Hermes tap** — a reusable skill package installed globally on your machine (in `~/.hermes/`) and never copied into individual projects. It consists of:

- **Skills** (`skills/`) — focused, reusable procedures (e.g., planning, building, review, quota guard).
- **Bundles** (`skill-bundles/`) — YAML compositions that load multiple skills at once under single slash commands (`/ama-plan`, `/ama-build`, etc.) with setup instructions.
- **Profiles** (`profiles/`) — six dedicated AMA identities (`ama-planner`, `ama-builder`, `ama-reviewer`, `ama-board-a/b/c`) with their own `SOUL.md` (role identity), never touching your existing Hermes profiles.
- **Configuration** (`config/settings.yaml`) — tier-to-model routing and board seat assignments.
- **Setup script** (`scripts/setup-ama-profiles.sh`) — one-time bootstrap: creates the profiles, installs skills/bundles, sets model tiers.

Real project instructions live in the **project's own repo** as a small `PROJECT_BRIEF.md` file (from `templates/`), not in the framework.

Repo structure:

```
skills/                    # 8 focused skills (planning, build, review, board, GitHub, session handoff, testing, quota)
profiles/                  # 6 dedicated SOUL.md files (Planner, Builder, Reviewer, Board A/B/C)
skill-bundles/             # 5 bundles: ama-plan, ama-build, ama-review, ama-board, ama
config/                    # settings.yaml (tier→model, board seats)
scripts/                   # setup-ama-profiles.sh (one-time machine setup)
templates/                 # PROJECT_BRIEF.md (template for each new project repo)
docs/autonomous-agents/    # design & build docs
prompts/                   # starter agent prompts (used in skills)
```

## Install (one-time, per machine)

### Prerequisites

1. **Hermes** installed: https://github.com/NousResearch/hermes-agent
2. **API keys** set as environment variables (never committed):
   - `ANTHROPIC_API_KEY` — Anthropic
   - `OPENAI_API_KEY` — OpenAI
   - `OPENROUTER_API_KEY` — OpenRouter (for free + 3rd-vendor models)
   - `TELEGRAM_BOT_TOKEN` — Telegram bot token
   - `TELEGRAM_CHAT_ID` — your Telegram chat ID

### Steps

1. Add the AMA framework as a Hermes tap:
   ```bash
   hermes skills tap add <owner>/<repo>
   # Example: hermes skills tap add wagner-maximiliano/firstProject
   ```

2. Run the setup script to create dedicated profiles and install skills:
   ```bash
   bash scripts/setup-ama-profiles.sh
   ```
   This creates the six AMA profiles, configures their model tiers from `config/settings.yaml`, and installs the skills/bundles into each.

   **Note:** The script contains `# VERIFY:` markers because exact Hermes CLI commands may vary by version. Check `hermes --help`, `hermes profile --help`, and `hermes skills --help` to confirm the commands match your Hermes version.

## Use AMA on a new project

AMA uses a **repeatable flow** for each project:

1. **Create or clone your project's own repository.** (AMA never touches it; you own it.)

2. **Copy the template brief into your project:**
   ```bash
   cp templates/PROJECT_BRIEF.md /path/to/your-project/
   cd /path/to/your-project/
   ```

3. **Fill in the brief** with your idea, constraints, and go-live criteria. (This is your one input; the agents read it first.)

4. **Create a working branch** (never `main` or `master`):
   ```bash
   git checkout -b claude/build-project-v1
   ```

5. **Kick off planning:**
   ```bash
   hermes -p ama-planner /ama-plan
   ```
   The Planner reads your `PROJECT_BRIEF.md`, runs a progressive-disclosure planning interview, produces a plan (PRD + tech spec + task DAG + acceptance criteria), and pauses for your sign-off via Telegram/CLI.

6. **Once you approve the plan,** building proceeds through the other profiles (`/ama-build`, `/ama-review`, etc.) until go-live.

**Your project repo stays clean:** only the brief, a `STATE.md` the agents maintain, and the code they build. The AMA framework itself stays in `~/.hermes/` on your machine.

## The agents (profiles) and what they load

| Profile | Role | Tier | Bundle |
|---------|------|------|--------|
| `ama-planner` | Architect (planning) | T3 | `/ama-plan` |
| `ama-builder` | Engineer (implementation) | T2 | `/ama-build` |
| `ama-reviewer` | Gatekeeper (code review) | T2 | `/ama-review` |
| `ama-board-a` | Board seat (Anthropic lens) | T3 | `/ama-board` |
| `ama-board-b` | Board seat (OpenAI lens) | T3 | `/ama-board` |
| `ama-board-c` | Board seat (OpenRouter lens) | T3 | `/ama-board` |

Each profile has its own `SOUL.md` (identity) and loads the skills it needs via its bundle.

## The skills

| Skill | Purpose |
|-------|---------|
| `ama-planning` | Conduct progressive-disclosure planning interviews, produce PRD/spec/DAG/criteria |
| `ama-build-task` | Implement a single task: write code + tests + why-comments, open draft PR |
| `ama-review` | Review PRs for correctness, safety, and fit before merging to trunk |
| `ama-board` | Multi-vendor scoring + "prove it or lose it" veto on flagged decisions |
| `ama-github-workflow` | Deterministic GitHub operations: create/move issues, branches, PRs, merge |
| `ama-session-handoff` | Checkpoint progress, hand off to next session, resume from latest checkpoint |
| `ama-human-testing` | Generate per-phase test guides, boot isolated test envs, collect pass/fail via Telegram |
| `ama-quota-guard` | Monitor rolling 5-hour vendor quotas, downgrade to free tier, auto-resume |

Skills carry the *how* (shared procedures). Agent identity (the *who*) lives in profile `SOUL.md` files.

## Configuration (tier→model)

Model tiers are configured in `config/settings.yaml`. Adjust them without code changes:

```yaml
tiers:
  T1:
    provider: "openrouter"
    model: "nvidia/nemotron-mini"  # cheap, high-volume
  T2:
    provider: "anthropic"
    model: "claude-sonnet-4-20250514"  # mid-range: real coding, review
  T3:
    provider: "anthropic"
    model: "claude-opus-4-1"  # frontier: planning, hard decisions

board:
  seat_a:
    provider: "anthropic"
    model: "claude-opus-4-1"
  seat_b:
    provider: "openai"
    model: "gpt-4o"
  seat_c:
    provider: "openrouter"
    model: "anthropic/claude-opus"
```

To retune tiers:
1. Edit `config/settings.yaml` — change model names or which tiers use which providers.
2. Restart the agents; they pick up the new routing automatically.
3. No code changes needed — tiers are configuration, not hardcoded.

**Environment variables** (never commit):
- `ANTHROPIC_API_KEY` — Anthropic API key
- `OPENAI_API_KEY` — OpenAI API key
- `OPENROUTER_API_KEY` — OpenRouter API key (free tier + 3rd-vendor models)
- `TELEGRAM_BOT_TOKEN` — Telegram bot token
- `TELEGRAM_CHAT_ID` — your Telegram chat ID

Set these in your session environment's secret settings, not in the repo.

## Developing the AMA framework itself

This section is for contributors who are **improving the AMA framework**, not for people using it to build projects. If you're using AMA to build a project, you can skip this section.

Framework development happens on a dedicated build branch (never `main` or `master`) and is guided by:

- **`docs/autonomous-agents/build/SESSION_PROTOCOL.md`** — the rules every build session must follow (so progress survives across sessions).
- **`docs/autonomous-agents/build/BUILD_PLAN.md`** — detailed tasks, phases, and success criteria.
- **`docs/autonomous-agents/build/STATE.md`** — live progress file; agents read "what's next" and write "what I did."
- **`docs/adr/ADR-0002-distribution-as-hermes-tap-and-profiles.md`** — the decision record for this tap + bundles + profiles packaging model.

When you want to contribute to AMA:
1. Read the design in `docs/autonomous-agents/OVERVIEW.md` (plain English) and `docs/autonomous-agents/FRAMEWORK_SPEC.md` (full spec).
2. Check `docs/autonomous-agents/build/BUILD_PLAN.md` for the next task to work on.
3. Follow `docs/autonomous-agents/build/SESSION_PROTOCOL.md` so your work survives across sessions.
4. Commit to the build branch, not `main`; the human promotes when ready.

## Design docs

- **`docs/autonomous-agents/OVERVIEW.md`** — plain-English explanation of how the framework works (start here).
- **`docs/autonomous-agents/FRAMEWORK_SPEC.md`** — full technical specification (all details, all trade-offs).

## Status

**V1 packaging scaffold in place:**
- Tap + skills + profiles + bundles structure (ADR-0002).
- 8 skills with progressive-disclosure bodies.
- 6 dedicated AMA profiles with starter `SOUL.md` files.
- Config tier→model routing.
- Setup script and project-brief template.

**Still to come (see `docs/autonomous-agents/build/BUILD_PLAN.md`):**
- Custom core/ engine (gateway, state store, orchestrator, board, watchdog, quality checks, human/Telegram).
- End-to-end V1 pilot on a tiny real project (idea → plan sign-off → build → testing → go-live).
