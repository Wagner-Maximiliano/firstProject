# The Autonomous Build Team — In Plain English

> This is the friendly, no-jargon version. The full technical blueprint lives next door in `FRAMEWORK_SPEC.md`.
> **The big idea:** build a team of AI workers that takes your idea and turns it into finished software — and you only need to show up at the start, to agree on the plan.

---

## Think of it like a construction company

You don't pour concrete or wire the electrics yourself. You meet the architect, describe the house you want, answer a few good questions, approve the blueprint — and then a whole crew builds it while a site manager keeps everything on track.

This system is that company, staffed by AI:

- **The Greeter** welcomes you and figures out what you're really after.
- **The Architect** turns your idea into a solid blueprint.
- **The Site Manager** runs the day-to-day so nothing stalls.
- **The Builders** do the actual work, in parallel.
- **The Inspectors** check every piece before it's accepted.
- **The Review Board** — experts from *different firms* — sign off on the big, risky decisions together.
- **The Night Watch** never sleeps: it notices when something breaks and fixes it before you'd ever know.

You only ever talk to the Greeter and the Architect, and only at the planning stage.

---

## Your one job: get the plan right

Everything depends on a great plan, so that's where your time goes — and we make it painless:

- **A friendly, cheap assistant talks to you first.** It handles the simple stuff itself and only pulls in the senior "architect" brain for the questions that really shape your project. (This also keeps costs down — we don't put an expensive expert on small talk.)
- **We never overload you with questions.** There's a strict limit. Every question has to earn its place by passing one test: *"If you answered this wrong, would the project actually come out different?"* If not, we make a sensible choice and just tell you what we assumed.
- **You answer by choosing, not by writing tech-speak.** Questions come as simple options with a recommended pick, so you never need to know any jargon.
- **We make sure we understood you — not just your words.** Before building, the Architect plays your idea back to you in plain language, sometimes with a quick mockup or example, so we catch any "that's not quite what I meant" *before* a single thing is built.
- **You give one final thumbs-up.** That sign-off is the moment autonomy begins. After that, the crew runs on its own.

---

## How the crew works once you've approved

### They work in parallel, like a real crew
Different parts of your project are built at the same time by different builders, each in their own workspace so they never trip over each other. The Site Manager figures out what can happen now and what has to wait for something else to finish first.

### Nothing risky happens to the "real" version
There's always one clean, working copy of your project that's protected. Builders work on *copies*. A change only joins the real version after it's been tested, inspected, and (if it's a big deal) approved by the Board. It's mechanically impossible for a worker to mess up the master copy — the rules are enforced by the system, not by trust.

### Everything is tracked on a visible board
Just like sticky notes on a wall: **To Do → Doing → In Review → Done.** Every task is a card, and the cards move automatically. You (or anyone) can glance at it any time and see exactly where things stand.

### Big decisions go to a "board of experts" from different companies
For the important, hard-to-undo choices, we don't trust a single AI. We ask **three or four different AIs from different companies** (one from Anthropic, one from OpenAI, one from another provider, etc.) to each weigh in *independently*, then challenge each other's reasoning. If they strongly agree, we proceed with confidence. If they're split, that's a signal we *aren't* sure — so we either dig deeper or ask you one clear question. Different companies' AIs have different blind spots, so a mixed panel catches mistakes a single one would miss.

### The work never goes stale
A tireless "night watch" constantly checks the pulse of every part of the project. If a worker gets stuck, a connection drops, a service runs out of credit, or a task has been sitting too long — it steps in automatically: retry, switch to a different provider, restart the task, or call in a more capable expert. It only ever wakes *you* up as an absolute last resort, and when it does, it hands you the full story so you can decide quickly.

---

## How we keep it affordable (without making it worse)

Three simple ideas do the heavy lifting:

1. **Let plain software do the boring jobs.** Running tests, moving cards, tidying up, health checks — none of that needs an "AI brain," so we use ordinary scripts. They're instant and free.
2. **Match the worker to the job.** Simple, repetitive thinking goes to cheap (or free) AIs. The expensive, brilliant ones are saved for planning, hard problems, and the Board. It's like not flying in a specialist surgeon to put on a plaster.
3. **Only spend big when it matters.** The expensive multi-company Board only meets for genuinely big decisions — not everyday work.

**Important:** we never cut costs in a way that hurts the result. The expensive experts are always *available* the moment a task gets hard — we just don't use them by default. You'll also be able to see exactly where the money goes.

---

## Built to be handed over

Everything is written so another team — human or AI — could pick it up later and understand it:

- The code is **commented to explain *why* things were done**, not just what (the "why" is the part that's hard to rediscover later).
- Every big decision is **written down with its reasoning**, stored right alongside the code.
- The tests double as a description of how things are *supposed* to behave.

So the project never becomes a mysterious black box.

---

## Where you fit, start to finish

```
   YOU                          THE AI CREW
   ───                          ───────────
1. Describe your idea     →     Greeter listens, asks only what matters
2. Answer a few questions →     Architect drafts the blueprint
3. React to the playback  →     Plan is sanity-checked by the expert board
4. Give final sign-off ✅  →     ── autonomy begins ──
                                Builders build (in parallel)
                                Inspectors check everything
                                Board approves the big calls
                                Night watch keeps it all alive
   (you relax)            →     Finished software, with you only
                                pulled in if something truly needs you
```

---

## A few things I need from you to finalize

Quick decisions that will make the plan exact (these are also listed in the technical doc):

1. **"Hermes"** — did you mean a specific AI *model* (I can use it), or a *platform* by that name? I've built the design so either answer fits.
2. **Spending limits** — a monthly or per-project cap you'd like the system to respect?
3. **How to reach you** — for the rare "we really need a human" moment, where should it ping you, and how long can it wait?
4. **Board size** — 3 experts (cheaper, breaks ties naturally) or 4 (more diverse, costs a bit more)?
5. **Going live** — should putting your project in front of real users always need your okay, or can the system handle a "practice" version on its own?

Answer those whenever you're ready and I'll lock the plan down.

---

*Want the deep technical detail? It's all in `FRAMEWORK_SPEC.md`.*
