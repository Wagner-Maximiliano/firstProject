# Human Runbook — Building the Autonomous Agent Framework Across Many Sessions

> **This is your home base.** You don't need to write code or understand it. Your job is to start sessions, paste the right prompt, answer the occasional plain-language question, test screens when asked, and approve go-live. Everything the AI needs to keep going is stored in the repo, so it can pick up across as many sessions as it takes.

---

## How this works (the big picture)

Building this framework is too big for one sitting, so it happens over a series of **sessions**. Each session:

1. You open a **new session** and paste a prompt.
2. The AI reads the project's progress file, does the next chunk of work, saves everything to the repo.
3. When it's done (or running low on room to think), it tells you, and leaves clear notes for the next session.
4. You start the **next** session and paste the same RESUME prompt. Repeat until it's built.

Because every session saves its progress to the repo, **it never forgets where it was** — even though each session starts fresh.

---

## One-time setup (before the first session)

1. **Keys & tokens** — the AI will eventually need your API keys (Anthropic, OpenAI, your third provider) and a Telegram bot token. **Do not paste these into the chat.** Put them in the session environment's *secrets / environment variables* settings (the AI will tell you the exact variable names it expects, e.g. `ANTHROPIC_API_KEY`). Until you add them, the AI builds and tests using a safe "pretend" provider — that's fine and expected for the early sessions.
2. **Telegram bot** — create a bot with Telegram's "BotFather" and get its token + your chat ID. (The AI can walk you through this in plain steps when it reaches that task.)
3. That's it. You don't need anything else to start.

---

## The two prompts

### ▶ KICKOFF prompt — paste this for the FIRST session only

```
You are the build agent for a multi-session project: building the autonomous agent framework
described in this repository (built on top of Hermes). This is session 1 of many.

Before doing anything else, read these files in full:
- docs/autonomous-agents/build/SESSION_PROTOCOL.md   (how every session must operate — follow it exactly)
- docs/autonomous-agents/build/BUILD_PLAN.md          (what to build, and in what order)
- docs/autonomous-agents/build/STATE.md               (live progress — your source of truth)
- docs/autonomous-agents/FRAMEWORK_SPEC.md and docs/autonomous-agents/OVERVIEW.md (the design)

Then follow the SESSION PROTOCOL exactly:
- Run the START checklist, then begin at the task named in STATE.md ("NEXT SESSION STARTS HERE" = B0-1).
- Work on the build branch; NEVER commit to master/main.
- Commit and push frequently; keep STATE.md current as you go.
- When the task is done OR your context is filling up, run the WRAP-UP checklist: leave the tree
  clean, push, update STATE.md, write a handoff note, and tell me the session is complete.

I am a non-developer. Ask me ONLY questions that genuinely block progress, in plain business
language with clear options. Put non-blocking questions in STATE.md instead. Start now by telling
me which task you'll tackle this session.
```

### ▶ RESUME prompt — paste this for EVERY session after the first (always the same)

```
You are the build agent continuing a multi-session build of the autonomous agent framework in this repo.
Assume NO memory of previous sessions — the repo is your memory.

First, read in full:
- docs/autonomous-agents/build/SESSION_PROTOCOL.md   (follow it exactly)
- docs/autonomous-agents/build/STATE.md               (where things stand — your source of truth)
- docs/autonomous-agents/build/BUILD_PLAN.md          (the roadmap)

Run the protocol's START checklist (check git state and that the build still passes its tests),
then continue from "NEXT SESSION STARTS HERE" in STATE.md. Work on the build branch, never master.
Commit and push frequently and keep STATE.md current. When the task is done or your context fills,
run the WRAP-UP checklist and leave a clean handoff.

I'm a non-developer — surface only blocking questions, in plain language with options. Begin by
telling me which task you're continuing and the current state of the build.
```

> Tip: keep both prompts saved somewhere handy (a note on your phone). You'll reuse the RESUME one many times.

---

## Your routine each session

1. Start a new session → paste the right prompt (KICKOFF first time, RESUME after).
2. Let it work. It'll give you a short plain-language update of what it's doing.
3. **If it asks you a question:** answer it. Questions will be in plain language with options — pick what fits. If unsure, ask it to explain the trade-off simply.
4. **If it asks you to test a screen:** follow the simple test sheet it gives you (what to run, what to check, what you should see). Tap/tell it **pass** or **didn't work** (with a quick note of what looked wrong).
5. **When it says "session complete":** that's your cue. Start a fresh session and paste the RESUME prompt to continue.

---

## Your three real decision moments

These are the only places your judgment is genuinely needed:

1. **Plan sign-off** — early on, you'll be guided through your project idea topic by topic and asked to approve the plan. Take your time here; this is the foundation.
2. **Screen testing** — when there's something visual, you try it and say pass/fail.
3. **Go-live approval** — nothing goes to real users until you explicitly approve it.

Everything else, the system handles.

---

## Troubleshooting

- **"The session seems lost or confused."** Just start a new session and paste the RESUME prompt. Because progress lives in the repo, a fresh session recovers cleanly. (This is by design.)
- **"It says tests are failing."** That's normal during building; the AI's job is to fix them. If it's stuck on the same failure repeatedly, it will write down the problem and hand off — a later session (or a more capable model) will pick it up.
- **"It's asking for a key I haven't set up."** Either add the key to the environment's secrets, or tell it to "keep using the mock provider for now" — it can keep building.
- **"It wants to do something big/irreversible (delete things, deploy to real users)."** It should always ask first. If a request seems off or unexpected, say no and ask it to explain.
- **"How do I know it's really done?"** The finish line is the pilot: from your idea, a working tiny app reaches a staging link, with you only signing off the plan, passing the screen test, and approving go-live. The AI will produce a short pilot report at the end.

---

## What NOT to do

- Don't paste API keys or tokens into the chat — use the environment's secret settings.
- Don't hand-edit the code or merge things into `master` yourself unless the AI asks you to.
- Don't worry about losing progress by ending a session — that's exactly what the progress file protects against.
