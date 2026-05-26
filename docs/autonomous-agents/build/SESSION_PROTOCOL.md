# Session Protocol — How Every Build Session Must Operate

> **Audience: the build agent (you, in a fresh session).** Read this in full at the start of every session and follow it exactly.
> **Why this exists:** building Helm spans many sessions. No session remembers the last one. This protocol makes the repo — not your chat history — the memory, so any fresh session can pick up cleanly and nothing is lost.

---

## 0. Prime directive

**The repo is the memory. Your context window is scratch paper.**
Never assume you remember anything from a previous session. Everything that matters must be *read from* and *written to* the repo: code, commits, `STATE.md`, ADRs, and the handoff note. If it isn't committed and pushed, it didn't happen.

---

## 1. START checklist (do this first, every session)

1. **Read** in full: this file, `BUILD_PLAN.md`, `STATE.md`. Skim `../FRAMEWORK_SPEC.md` for any area you're about to touch.
2. **Orient with git:** `git status`, `git log --oneline -10`, and confirm which branch you're on. You must be on the **build branch** (§4) — never `master`/`main`.
3. **Confirm the build is healthy:** run the setup + test suite (`scripts/setup.sh` then `pytest`, once they exist). If it's red on arrival, your first job is to get it green or record why in `STATE.md` — do not pile new work on a broken base.
4. **Find your starting point:** read the **"NEXT SESSION STARTS HERE"** pointer in `STATE.md`. That is your task. If it's ambiguous, re-derive it from the task checklist (first unchecked task whose dependencies are done).
5. **State your plan** for this session in one short message to the human (which task, what you intend to finish).

---

## 2. WORK rules (while building)

- **One task at a time**, from `BUILD_PLAN.md`. Honour each task's *Done when* / *Verify*.
- **Commit early and often** — every meaningful, working increment. Small green commits are checkpoints that survive a crash or context cutoff. Push regularly (`git push -u origin <build-branch>`, retry with backoff on network errors).
- **Keep the suite green.** Add tests with the code. If CI/lint/type would fail, fix before moving on.
- **Update `STATE.md` as you go**, not just at the end — tick sub-progress so a sudden cutoff still leaves an accurate picture.
- **Record decisions** as short ADRs in `docs/adr/` when you make an architectural choice.
- **Secrets:** never commit keys. If a key is missing, use the mock provider and add a line under `STATE.md` → *Open questions / blockers*.
- **Don't overbuild.** Build the V1-pilot version of the task and leave clean seams for "Beyond V1." Resist gold-plating.
- **Scripts over models** for anything deterministic.

---

## 3. WRAP-UP checklist (when the task is done OR your context is filling up)

Wrap up **proactively** — do not run yourself to the edge of the context window and leave half-finished, uncommitted work. The moment you sense you won't cleanly finish the next increment, stop and wrap up.

1. **Leave the tree clean:** no uncommitted half-work. Either finish the increment and commit, or revert the incomplete bit. Tests green.
2. **Commit & push** everything, with a clear message.
3. **Update `STATE.md`:**
   - Tick completed tasks/sub-items in the checklist.
   - Rewrite **"LAST SESSION SUMMARY"** (what you did, what you learned, anything surprising).
   - Rewrite **"NEXT SESSION STARTS HERE"** (the exact next task + any context the next agent needs to not repeat your discovery work).
   - Update *Open questions / blockers* and *Decisions log*.
4. **Write the handoff note** (template below) as the final part of `STATE.md`'s "LAST SESSION SUMMARY", and also post a 3–5 line plain-language summary to the human in chat (they are a non-developer — say what got done and what's next, no jargon).
5. **Tell the human the session is complete** and that they can start a new session with the RESUME prompt (see `HUMAN_RUNBOOK.md`).

---

## 4. Branch & merge rules

- Work on the **build branch**. Use the branch named in your session's own instructions if one is given; otherwise use **`build/v1-pilot`** (create it from `master` if it doesn't exist). Push there.
- **Never commit directly to `master`/`main`.** Once B0-3 sets up trunk protection, this is also enforced by GitHub.
- At milestone boundaries (end of a phase), you may open a PR from the build branch into `master` for the human to merge — mention it in your summary. Do **not** auto-merge to `master`.

---

## 5. Handling questions & blockers

- **Blocking question** (can't proceed without the human): ask in chat, in **plain business language with clear options** (the human is non-technical). Also log it under *Open questions / blockers* in `STATE.md` so it isn't lost if the session ends.
- **Non-blocking question:** record it in `STATE.md`; keep working; surface it in your end-of-session summary.
- **Stuck/looping:** if you've tried the same fix ~3 times without progress, stop, write the diagnosis into `STATE.md`, and hand off — don't burn the session in a loop.

---

## 6. Handoff note template (paste into STATE.md → LAST SESSION SUMMARY)

```
### Handoff — <date> — session <n>
- DONE this session: <bullets>
- STATE: build branch <name>, tests <green/red>, last commit <sha/msg>
- LEARNED / GOTCHAS: <anything the next agent must know to avoid redoing work>
- NEXT: start with task <ID> — <one line on exactly what to do first>
- BLOCKERS / WAITING ON HUMAN: <none | list>
```

---

## 7. The minimum every session leaves behind

A fresh agent who reads only `STATE.md` (plus the code and `BUILD_PLAN.md`) must be able to continue **without you**. If that's true when you stop, the protocol worked.
