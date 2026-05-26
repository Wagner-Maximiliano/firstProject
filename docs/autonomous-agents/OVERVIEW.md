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
For the important, hard-to-undo choices, we don't trust a single AI. We ask **three different AIs from three different companies** (one from Anthropic, one from OpenAI, one from a third) to each weigh in *independently*, then challenge each other's reasoning. If they agree, we proceed with confidence. If they're split, that's a signal we *aren't* sure — so we either dig deeper or ask you one clear question. Different companies' AIs have different blind spots, so a mixed panel catches mistakes a single one would miss. (Three is the sweet spot: enough to cross-check, and an odd number so there's never a tied vote.)

### The work never goes stale
A tireless "night watch" constantly checks the pulse of every part of the project. If a worker gets stuck, a connection drops, a service hits its usage limit, or a task has been sitting too long — it steps in automatically: retry, switch to a different provider, restart the task, or call in a more capable expert. It only ever pings *you* (on **Telegram**) as an absolute last resort, and when it does, it hands you the full story — usually as a simple tap-to-answer question — so you can decide in seconds.

### It remembers everything, across days and many sessions
The crew's memory doesn't live in any one conversation — it lives in the project's own files and a shared logbook. That means you can switch the whole thing off and turn it back on tomorrow and it picks up exactly where it left off, with nothing forgotten and nothing "overflowing." No single chat ever has to hold the entire project in its head, so it never gets overwhelmed no matter how big or long-running the project becomes.

---

## How we keep it within your limits (without making it worse)

You're on the **cheapest subscription for every AI service**, so the real limit isn't money — it's *how much you can use in a given window of time* (these services cap usage every few hours). The system is built around that:

1. **Let plain software do the boring jobs.** Running tests, moving cards, tidying up, health checks — none of that needs an "AI brain," so we use ordinary scripts. Instant, and they use none of your allowance.
2. **Lean on free AIs first.** The everyday, simple thinking is sent to **free models**, so your paid allowance is barely touched. It's like not flying in a specialist surgeon to put on a plaster.
3. **Save the paid allowance for what matters.** The premium AIs are used only for planning, genuinely hard problems, and the Board — and the system watches each service's usage window so it never gets cut off mid-task. If one service is running low, it quietly shifts work to free models and picks the paid one back up once the window resets.

**Important:** we never cut corners in a way that hurts the result. The premium experts are always *available* the moment a task gets hard — they're just not the default. And you can always see how much of each service's allowance is left.

---

## Built to be handed over

Everything is written so another team — human or AI — could pick it up later and understand it:

- The code is **commented to explain *why* things were done**, not just what (the "why" is the part that's hard to rediscover later).
- Every big decision is **written down with its reasoning**, stored right alongside the code.
- The tests double as a description of how things are *supposed* to behave.

So the project never becomes a mysterious black box.

---

## Your other small job: trying out the screens

A computer can test whether the *plumbing* works, but it can't yet look at a screen and tell you "this feels right" the way a person can. So whenever your project has something you can actually see and click, **you** give it a quick try — and the system makes that effortless:

- At the end of each stage, you get a **dead-simple test sheet** written in plain English, with five parts:
  1. **What we built** this stage.
  2. **How to start it** — the exact thing to click or run.
  3. **What to check** — a short checklist.
  4. **What you should see** — so you know what "correct" looks like.
  5. **If it looks wrong** — tap one button to tell us; we'll fix it and send you a fresh sheet.
- It comes with a **ready-to-go little test version** of your project that just runs — no setup headaches, no risk to anything real.
- You tap **pass** or **didn't work** for each item. A pass moves the stage to "done"; a fail sends the crew straight back to fix it.

That's the whole job. A few minutes of tapping, no technical knowledge needed.

---

## What runs the whole thing

Under the hood we use a tool called **Hermes** — think of it as the foreman's control panel. It can talk to every AI service you have (and the free ones), switch between them automatically if one is busy or down, remember things between sessions, and keep each worker pointed at the right AI for its job. Importantly, our own "rules of the company" sit *above* Hermes, so we're never locked in — if something better comes along later, we can swap the engine without rebuilding the company.

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
5. Try the screens 👆      →     (only when there's something to see;
   (tap pass / didn't work)      a simple test sheet guides you)
6. Approve go-live ✅      →     Nothing reaches real users without
                                your okay
   (otherwise, you relax)  →     Finished software, with you only
                                pulled in if something truly needs you
```

---

## What's settled, and the last few things I need

**Settled from our chat:** Hermes is the engine • no money budget, we live within your usage windows and lean on free AIs • Telegram is how it reaches you • a 3-company board • nothing goes live without your okay • you test the screens each stage with a simple sheet • it survives across as many sessions as you like.

**Last few small things, whenever you're ready:**

1. **Favourite AIs for each job** — which AI you'd like as the cheap/free everyday worker, which for real coding, and which three companies sit on the board.
2. **How many questions** is too many during planning — 5? 8?
3. **How long the "night watch" should wait** for you to answer a Telegram message before it parks that piece of work and carries on with the rest (an hour? a day?).
4. **What your projects are built in** — mostly Python, or also web/JavaScript or others? (Just so the little test versions are set up the right way.)
5. **Telegram details** — the bot/channel to use (we'll wire this up first).

Answer those whenever you're ready and I'll lock the plan down.

---

*Want the deep technical detail? It's all in `FRAMEWORK_SPEC.md`.*
