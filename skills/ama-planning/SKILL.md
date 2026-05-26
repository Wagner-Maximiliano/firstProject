---
name: ama-planning
description: Conduct a progressive-disclosure planning interview with a non-developer, produce a PRD, tech spec, task DAG, acceptance criteria, ADRs, and an assumption ledger, then gate on human sign-off.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, planning, requirements, architecture]
    category: ama
---

# Autonomous Planning with Progressive Disclosure

This skill guides a Concierge (T1, cheap) and Architect/Planner (T3, frontier) through a structured interview with a non-developer to produce a buildable, signed-off plan. The human stays in control of depth via "dive deeper" / "trust the default" choices, grouped by business-impact domains (not jargon).

## When to Use
- A non-developer has a software project idea and needs a plan.
- You must produce plan artifacts (PRD, tech spec, task DAG, acceptance criteria, ADRs, assumption ledger) ready for agent-driven autonomous build.
- The human must sign off on the plan before work begins.

## Procedure

### Stage 1: Concierge intake (T1, cheap)
**Goal:** Understand the idea, restate it back, triage complexity, begin progressive disclosure.

1. **Welcome the human.** "Tell me about your project — what are you trying to build and why?"
2. **Restate in your own words** ("So you want to build X because Y — does that sound right?").
3. **Estimate complexity** using heuristics: number of users, real-time vs. batch, structured data vs. freeform, security sensitivity, integrations with external systems. Score low/medium/high.
4. **Begin progressive disclosure:** 
   - For each business-impact domain (listed below), offer the human a choice: "dive deeper" or "trust the AI's default."
   - Ask 2–3 high-leverage questions only, framed in business terms (never jargon).
   - **Pass every question through the relevance test:** *"Would a wrong answer here materially change the plan?"* If no, default silently and note it.
5. **Escalate to the Planner (T3)** with a summary: the idea, the complexity score, answers so far, and questions where the human chose "dive deeper."

### Stage 2: Architect/Planner deep interview (T3, frontier)
**Goal:** Conduct a focused, iterative interview. Surface unstated needs. Draft the plan artifacts.

1. **Restate the goal in plain language** ("You've told me about X; I understand you want to do Y for these reasons"). Confirm the human agrees.
2. **Organize planning by business-impact domains:**
   - *What it does* — core features, the user's happy path, key constraints.
   - *Look & feel* — UI/UX, graphical interfaces, accessibility.
   - *Your data & privacy* — data model, storage, retention, regulatory (GDPR, etc.).
   - *Cost trade-offs* — storage vs. speed, feature depth vs. launch speed, ongoing cost vs. upfront.
   - *Speed & scale* — expected user count, response-time requirements, growth trajectory.
   - *(Add domain-specific axes if needed.)* Performance-critical, integrations, geographic, etc.

3. **For domains the human chose "dive deeper":**
   - Ask 2–3 clarifying questions, each with a "trust the default" button so the human can short-cut if they prefer.
   - If useful, show **two concrete mock-ups/wireframes** (sketches, not polished designs) and ask "which feels closer?" Visuals answer in seconds what prose questions take minutes.

4. **Surface unstated needs.** After each domain, ask: "Is there anything about [domain] we haven't covered?"

5. **Draft the plan artifacts as the interview progresses:**
   - **PRD** — one-page product description in plain language. What is it, who uses it, why they want it, success criteria in business terms.
   - **Tech spec** — architecture diagram, tech stack choices, data model, API boundaries, key algorithms, deployment strategy, security model. Justify significant choices.
   - **Task DAG** — break the plan into discrete, parallelizable tasks with explicit dependencies. Each task has a clear, one-sentence outcome and acceptance criteria.
   - **Acceptance criteria** — per task/feature, observable, testable outcomes. These become the test suite.
   - **Initial ADRs** — short records (decision, options considered, chosen option, rationale, implications) for each significant call (stack choice, data-model shape, security approach, build-vs-buy, etc.).
   - **Assumption ledger** — every default you chose where the human didn't specify. Group by domain. Order by risk (riskiest first — the defaults that would cause rework if wrong).

6. **Flag board-criteria decisions.** For anything that meets board criteria (architecture, schema, dependency, security, irreversible, large blast radius), mark it `needs_board: true` so it's routed correctly post-plan.

7. **Minimize the assumption ledger.** Keep it honest: only include defaults that *would matter if wrong*. Small ledger = human confidence.

### Stage 3: Reviewer mini-board (T3, optional)
**Goal:** Sanity-check the plan before sign-off (recommended for medium/high complexity; optional for low).

- Route the plan artifacts to 1–2 senior-tier models (or skip for simple projects).
- Ask: "Is this buildable? Are the assumptions risky? Is the scope clear? Will it ship in the planned time/cost?"
- Feedback loops back to the Planner if major rework is needed; otherwise, confidence is green.

### Stage 4: Human sign-off gate
**Goal:** The human explicitly approves the plan before autonomy begins.

1. **Present the plan artifacts:**
   - PRD (plain language).
   - Tech spec (visual + bullets).
   - Task DAG (visual: nodes + edges, or a markdown table).
   - Acceptance criteria (checklist).
   - Assumption ledger (grouped by domain, riskiest first).
   - Any ADRs flagged for the Board.

2. **Ask the human:** "Are you ready to approve this plan? Is anything missing or wrong?"

3. **If yes:**
   - Record the human's approval (timestamp, confirmation message).
   - Commit all artifacts to the repo: `/docs/plan/PRD.md`, `/docs/plan/TECH_SPEC.md`, `/docs/plan/TASK_DAG.md`, `/docs/plan/ACCEPTANCE_CRITERIA.md`, `/docs/adr/ADR-*.md`, `/docs/plan/ASSUMPTIONS.md`.
   - Autonomy begins; the Orchestrator reads the DAG and schedules the first ready tasks.

4. **If no:**
   - Capture the human's objection.
   - Planner revises the relevant artifact(s).
   - Loop back to Stage 4.

## Pitfalls

- **Over-questioning.** Asking every possible detail → the human feels interrogated and the session drags. **Mitigation:** use the relevance test; offer dive-deeper buttons; use visual A/B instead of prose questions.
- **Silent assumptions.** Defaulting on something that would break the project without logging it. **Mitigation:** keep the assumption ledger small, riskiest-first; present it at sign-off; ask "are these safe to bet on?"
- **Buried context overload.** The final plan is a 40-page document that buries the real decisions. **Mitigation:** PRD stays one page; tech spec is visual + bullets; task DAG is a graph; assumption ledger is short and grouped by domain.
- **AI over-specifying.** The Planner invents requirements the human never stated. **Mitigation:** restate-and-confirm early; show, don't tell (visual A/B); frame everything as defaults the human can override.
- **Scope creep during planning.** "While we're at it, let's add X." **Mitigation:** defer new features to a post-launch roadmap; the sign-off gate is on the *specified* plan only.
- **Jargon to a non-developer.** Talking about "microservices" or "relational algebra" instead of "faster search vs. cheaper storage." **Mitigation:** Concierge and Planner speak only in business terms; technical details stay in the spec, not the questions.

## Verification

1. **Plan artifacts exist and are committed:**
   - `/docs/plan/PRD.md` — one page, plain language, testable success criteria.
   - `/docs/plan/TECH_SPEC.md` — architecture diagram, stack, data model, boundaries.
   - `/docs/plan/TASK_DAG.md` — directed acyclic graph, each task with dependencies and acceptance criteria.
   - `/docs/plan/ACCEPTANCE_CRITERIA.md` — observable, testable outcomes per task.
   - `/docs/adr/ADR-*.md` — one per significant decision.
   - `/docs/plan/ASSUMPTIONS.md` — grouped by domain, riskiest first.

2. **Human sign-off is recorded:**
   - A git commit message or a file `/docs/plan/SIGN_OFF.md` with the human's timestamp and explicit approval.

3. **Board-flagged items are marked:**
   - Any task/decision with `needs_board: true` is noted in the task DAG or an ADR so the Orchestrator routes it correctly.

4. **All artifacts are readable by a non-developer and a future model:**
   - The PRD and assumption ledger are jargon-free.
   - The tech spec has diagrams and one-line explanations, not just equations.
   - Acceptance criteria are observable (not "make it fast" but "return results in < 500ms for 10k items").
