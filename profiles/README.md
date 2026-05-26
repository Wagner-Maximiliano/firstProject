# AMA Framework Profiles — Identity Drafts

This directory contains the `SOUL.md` identity drafts for the AMA (Autonomous Multi-Agent Framework) dedicated Hermes profiles.

## What is in here

These are not meant to be read by end users. They define the **identity** (the "who") of each agent: role, model tier, stance, hard rules, and which AMA skills/bundle each profile loads.

## How they are used

A setup script copies these `SOUL.md` files into newly-created Hermes profiles (`ama-planner`, `ama-builder`, `ama-reviewer`, `ama-board-a`, `ama-board-b`, `ama-board-c`). The AMA framework is then installed as a Hermes tap, and each profile's config sets its model tier and vendor key. **The human's existing personal or working profiles are never read or modified.**

## Structure

Each profile:
- **Defines the agent's identity.** What role is this agent? What is its mission? What is its stance?
- **Points to skills, not procedures.** The step-by-step "how to plan," "how to build," etc. lives in the `/skills/` directory (`ama-planning`, `ama-build-task`, `ama-review`, `ama-board`, etc.). The SOUL.md says which skills to load; the skills carry the procedures.
- **Enforces hard rules.** Non-negotiable constraints: e.g., builders never touch main, reviewers escalate board decisions, board members score blind and provide proof when rejecting.

## Vendor separation

The three board seats (A, B, C) are identical in structure but differ by vendor:
- **Seat A** — Anthropic vendor (claude-opus-4-1 or equivalent high-reasoning model).
- **Seat B** — OpenAI vendor (gpt-4 or equivalent).
- **Seat C** — Third vendor (via OpenRouter or similar).

This ensures the board's decision is not blind to a single vendor's model biases or capability gaps.
