---
name: ama-session-handoff
description: Surviving across many sessions by treating the repo as memory, wrapping up cleanly, and writing handoff notes for the next agent.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, session, handoff, continuity]
    category: ama
---

# Session Handoff & Multi-Session Survival

The framework lives for days or weeks across many sessions. Each session must leave the repo in a state where a fresh agent can pick up exactly where the last one left off—because **the repo is the memory, and your context window is scratch paper.**

## When to Use

- **START of every session:** read this and SESSION_PROTOCOL.md in full, execute the START checklist.
- **END of every session (or when context fills up):** execute the WRAP-UP checklist and write the handoff note.
- **During work:** update STATE.md incrementally so a sudden cutoff still leaves an accurate picture.

## Procedure

### START checklist (first thing, every session)

1. **Read in full:**
   - This file (`ama-session-handoff/SKILL.md`).
   - `docs/autonomous-agents/build/SESSION_PROTOCOL.md`.
   - `STATE.md` (the current project state and last session's summary).
   - Skim `docs/autonomous-agents/FRAMEWORK_SPEC.md` for any area you're about to touch.

2. **Orient with git:**
   ```bash
   git status
   git log --oneline -10
   git branch
   ```
   Confirm you are on the project's designated **build/integration branch** (named in `PROJECT_BRIEF.md` or `STATE.md`), never `main`/`master`.

3. **Confirm the build is healthy:**
   - Run `scripts/setup.sh` (if it exists) to ensure dependencies are installed.
   - Run `pytest` or your test suite to confirm tests are green. If tests are red on arrival, your first job is to get them green or log the reason in `STATE.md`.
   - Do not pile new work on a broken base.

4. **Find your starting point:**
   - Read the **"NEXT SESSION STARTS HERE"** pointer in `STATE.md`. That is your task.
   - If it is ambiguous, re-derive it from `BUILD_PLAN.md`: find the first unchecked task whose dependencies are done.

5. **State your plan** plainly to the human (one short message): which task you are starting, what you intend to finish this session, and any major decisions you see ahead.

### WORK rules (while building)

1. **One task at a time** from `BUILD_PLAN.md`. Honour each task's *Done when* and *Verify* criteria.

2. **Commit early and often.** Every meaningful, working increment is a checkpoint that survives a crash or context cutoff. Push regularly:
   ```bash
   git push -u origin <build-branch>  # first push of the branch
   git push                            # subsequent pushes
   ```
   Use backoff on network errors; do not give up.

3. **Keep the suite green.** Add tests with the code. If CI/lint/type-check would fail, fix before moving on.

4. **Update `STATE.md` as you go,** not just at the end. Tick sub-progress so a sudden cutoff still leaves an accurate picture. Examples:
   - `- [x] task B0-5: built X`
   - `- [ ] task B0-6: stub Y (in progress, 60% done)`

5. **Record architectural decisions** as short ADRs in `docs/adr/` when you make a choice that affects the system. Reference them in commits and comments.

6. **Secrets:** Never commit keys, tokens, or credentials. If a key is missing, use a mock provider and log the blocker in `STATE.md` → *Open questions / blockers*.

7. **Don't overbuild.** Build the V1-pilot version of the task and leave clean seams for "Beyond V1." Resist gold-plating; focus on the *Done when* criteria.

8. **Scripts over models** for anything deterministic: git operations, linting, formatting, test runs, board moves, status checks. Reserve model calls for reasoning only.

### WRAP-UP checklist (when the task is done OR your context is filling up)

Wrap up **proactively**—do not run yourself to the edge of the context window and leave uncommitted work. The moment you sense you won't cleanly finish the next increment, stop and wrap.

1. **Leave the tree clean:** no uncommitted half-work. Either finish the increment and commit, or revert the incomplete bit. Tests green.

2. **Commit and push everything:**
   ```bash
   git add <specific files>
   git commit -m "feat: message"
   git push -u origin <build-branch>
   ```
   Use a clear, Conventional Commits style message.

3. **Update `STATE.md`:**
   - Tick completed tasks/sub-items in the checklist under `BUILD_PLAN.md` → Progress.
   - Rewrite **"LAST SESSION SUMMARY"** (3–5 bullets: what you did, what you learned, anything surprising).
   - Rewrite **"NEXT SESSION STARTS HERE"** (the exact next task + critical context the next agent needs).
   - Update *Open questions / blockers* and *Decisions log*.

4. **Write the handoff note** (template below) as the final part of `STATE.md`'s "LAST SESSION SUMMARY". Also write a 3–5 line plain-language summary in chat to the human (they are non-technical—say what got done and what's next, no jargon).

5. **Tell the human the session is complete** and that they can start a new session whenever they choose (reference the RESUME prompt in `HUMAN_RUNBOOK.md` if it exists).

### Handoff note template

Paste this into `STATE.md` under "LAST SESSION SUMMARY":

```
### Handoff — <date> — session <n>
- **DONE:** <bullets of what was completed>
  - task B0-2: set up repo structure
  - task B0-3: drafted ama-planning skill
  - etc.
- **STATE:** build branch `<name>`, tests <green/red>, last commit `<sha>` — `<msg>`
- **LEARNED / GOTCHAS:** <anything the next agent must know to avoid redoing work or hitting the same wall>
  - Found that X assumes Y; be careful when Z happens
  - ADR-0003 explains why we chose approach A over B
  - etc.
- **NEXT:** start with task <ID> — <one precise line on exactly what to do first>
  - e.g., "task B0-4: author the ama-board skill, following the template at docs/skills/templates/SKILL.md"
- **BLOCKERS / WAITING ON HUMAN:** <none | bulleted list>
  - e.g., "awaiting list of preferred T2 models for OpenAI"
```

### During development: keeping STATE.md current

Update `STATE.md` incrementally as you work—don't wait until wrap-up. Examples of what to update:

- **Progress checklist:** tick off completed sub-tasks as you finish them.
- **Open questions:** if you hit a decision point, add it immediately.
- **Decisions log:** record why you chose approach A instead of B, so the next agent understands the trade-off.
- **Working state:** if you're mid-task and context is running low, write a bullet under "NEXT SESSION STARTS HERE" with the exact line of code or file you were editing.

This makes interruptions survivable and keeps the repo the single source of truth.

## Pitfalls

**Forgetting to read SESSION_PROTOCOL.md:** It contains rules about branches, commits, and state that are enforced by GitHub. Read it first every session to avoid surprises.

**Leaving uncommitted work:** If a session ends and there is uncommitted code, the next agent has no way to resume or understand what you were doing. Always commit before wrapping.

**Vague "NEXT SESSION STARTS HERE":** Avoid "continue with the build" or "finish the skills." Instead: "task B0-5 is next. It requires implementing the ama-quota-guard skill (see FRAMEWORK_SPEC.md §11.4 for the requirements). The stub is at skills/ama-quota-guard/SKILL.md—start by writing §Procedure."

**Updating STATE.md only at the end:** If context fills up or the session crashes, intermediate work is lost. Update as you go.

**Missing ADRs for decisions:** If you choose approach A over B and the next session asks "why didn't we do C?", the only way they know is if it's recorded in an ADR or a comment. Write it down.

**Not confirming tests pass before wrapping:** A red test left behind for the next session wastes their time. Fix it, or log it as a blocker.

## Verification

- **Repository state:** `git status` shows a clean working tree (no uncommitted files except `.env` / secrets).
- **Tests pass:** `pytest` (or your suite) shows all tests green, or you've logged why they're red in STATE.md.
- **Last commit is recent:** `git log -1` shows a commit from this session with a clear message.
- **Branch is correct:** `git branch` shows you on the build branch, never `main`.
- **STATE.md is updated:** "LAST SESSION SUMMARY" describes what you did; "NEXT SESSION STARTS HERE" is specific and actionable.
- **Handoff note is in STATE.md:** Follows the template above.
- **Human knows session is complete:** You've posted a 3–5 line summary in chat.
