# ADR-0002 — Distribute the framework as a Hermes tap + dedicated profiles

- **Status:** Accepted
- **Date:** 2026-05-26
- **Supersedes / relates to:** sets the packaging model the whole build now targets; the Hermes-capability reconciliation (ADR-0001, task B0-1) feeds into it.

## Context

The framework (working name **AMA — Autonomous Multi-Agent Framework**) must be **portable**: usable across many *different* projects, not entangled with this repo and not copy-pasted into each project. The original docs implicitly assumed "you build your project inside this repo," which does not match that goal.

We verified against the real Nous `hermes-agent` docs that Hermes already provides, natively:

- **Skills** — `SKILL.md` + YAML frontmatter, progressive disclosure (index → full body → reference files), installable from a **tap** (any GitHub repo with a top-level `skills/` directory: `hermes skills tap add <owner>/<repo>`), from a URL, or the hub. Skills live globally in `~/.hermes/skills/`.
- **Bundles** — a YAML alias (`~/.hermes/skill-bundles/<slug>.yaml`) that loads several skills at once under one slash command and carries a freeform `instruction:` string.
- **Profiles** — separate Hermes home directories, each with its own `config.yaml` (model/tier), `.env` (vendor key), `SOUL.md` (identity), skills, sessions, memory, cron, state DB. `hermes update` syncs skills to all profiles **without overwriting user-modified content**.
- Model **routing/fallback, session persistence, and conversation compression** are Hermes-native.

What this repo currently contains is a **finished design + build plan + six starter agent prompts** — not yet running code.

Decisions taken with the human (a non-developer, who will operate this):
- V1 = **skills + a custom `core/` engine** (not skills-only).
- Distribution = **a tap with an `/ama` bundle** (not a single mega-skill).
- Agent identities = **dedicated AMA profiles**, created new — **never reuse or modify the human's existing personal/working profiles**.

The human raised a real risk: profile `SOUL.md` files are tuned over time from their own feedback, so the framework must never overwrite a `SOUL.md` it doesn't own.

## Decision

1. **This repo becomes a Hermes tap.** A top-level `skills/` directory holds the framework's skills; users install with `hermes skills tap add <owner>/<repo>`. The framework therefore lives globally under `~/.hermes/`, never copied into a project.

2. **Decompose the framework into ~8 focused skills** (progressive disclosure — keep them small, not consolidated):
   `ama-planning`, `ama-build-task`, `ama-review`, `ama-board`, `ama-github-workflow`, `ama-session-handoff`, `ama-human-testing`, `ama-quota-guard`. Skills carry the *how* (shared procedures). Thin skills that wrap deterministic logic call scripts in `core/` rather than reimplementing it inline.

3. **Per-role bundles compose the skills.** `/ama-plan`, `/ama-build`, `/ama-review`, `/ama-board` each load the relevant skills and carry an `instruction:` that points the agent at `PROJECT_BRIEF.md` + `STATE.md` and the session-handoff procedure.

4. **Role identity lives in the `SOUL.md` of new, dedicated AMA profiles** — `ama-planner` (T3), `ama-builder` (T2), `ama-reviewer` (T2, ≠ builder model), `ama-board-a/b/c` (three vendors). A setup step **creates** these profiles (`hermes profile create … --description …`), sets each one's model tier in `config.yaml`, and installs the tap/bundles. **We author only these new profiles' `SOUL.md`. The human's existing profiles are never read or written.** Because identity sits in profiles we own and procedures sit in skills, `hermes update` can refresh the framework without ever clobbering the human's tuning.

5. **Keep the custom `core/` engine.** Skills/profiles are the *interface and instructions*; `core/` is the *engine* (gateway, state store, watchdog, quota guard, orchestrator, human/Telegram). Where a planned `core/` piece overlaps a Hermes-native feature (routing, sessions, compression), the overlap is reconciled in ADR-0001 (task B0-1) — prefer Hermes-native, build custom only for genuine gaps (e.g. the rolling 5-hour quota guard).

6. **Project-specific instructions are an input, not part of the framework.** Each *project* repo carries a small `PROJECT_BRIEF.md` (what to build, constraints, preferences) and a `STATE.md` the agents maintain. A one-time kickoff prompt tells the agent to load `/ama`, read the brief, and follow the framework. The framework stays out of the project tree — it isn't "littered" with framework files.

7. **Branch & promotion.** Build on `claude/autonomous-agent-framework-5MdEG`; never commit to `master`. When ready, the human promotes the branch so `main` presents the clean, digestible tap; ongoing build work stays on a branch. (A PR is opened only when the human asks.)

## Consequences

**Positive**
- Truly portable: one tap, installed once per machine; new projects need only a tiny brief.
- Vendor isolation for the board is real — three profiles, three `.env` keys.
- Framework updates never overwrite human-tuned `SOUL.md` (identity is in *our* profiles + skills, which `hermes update` preserves when user-modified).
- Leans on Hermes for routing/sessions/compression, shrinking what `core/` must build.

**Negative / risks**
- More moving parts to set up (several profiles). Mitigated by a setup script.
- Hub/URL-installed skills are security-scanned (exfil / injection / destructive commands); skills must be written to read clean or they'll be quarantined. Design constraint, not a blocker.
- `core/` vs Hermes-native overlap must be reconciled (ADR-0001) before building B0-4/B0-5 to avoid rebuilding what Hermes gives us.
- Working name "AMA" collides with "Ask Me Anything" — naming is the human's call; flagged, not decided here.

## Follow-ups (turned into build tasks)
- Reconcile `core/` scope against Hermes-native features (ADR-0001 / B0-1).
- Author the `skills/` (8 SKILL.md), the `skill-bundles/ama-*.yaml`, and the profile setup script; refactor the six starter `prompts/` into skill bodies (the *how*) and new-profile `SOUL.md` drafts (the *who*).
- Add a "Using AMA on a new project" guide (tap install + `PROJECT_BRIEF.md` template + kickoff prompt) to the README.
