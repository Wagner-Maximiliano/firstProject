---
name: ama-quota-guard
description: Managing per-vendor rolling 5-hour usage windows, routing to free models first, and auto-pausing on exhaustion without human alert.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, quota, cost, budget, windows]
    category: ama
---

# Quota Guard — Staying Within Subscription Windows

You have no dollar budget—you have **rolling usage windows** (typically ~5 hours of usage per vendor on paid tiers). The Quota Guard manages these windows so you never get throttled mid-flight, never waste a paid window on cheap work, and auto-resume when a window resets.

## When to Use

- At the start of each day or session: check remaining window headroom.
- When routing a new task: consult the guard to pick a vendor/model tier.
- When a vendor hits a soft threshold (70% used): switch high-volume work to free models.
- When a window exhausts: pause that vendor's tier and continue on free/other vendors.
- Continuously (the guard runs in the background): the orchestrator calls it before spawning any expensive agent.

## Procedure

### 0. Prerequisites

The **Quota Guard meter** lives in `core/watchdog/quota.py` — part of AMA's own engine. A minimal or early install may not have it yet; in that case you track windows manually or via scripts. This skill describes *how you'd use the meter when present*, and what to do when it isn't.

**What the meter tracks (when it exists):**
- Per vendor (Anthropic, OpenAI, OpenRouter, etc.): tokens/requests used in the current rolling 5-hour window.
- Current window start time and reset timestamp.
- Remaining headroom (% used, time until reset).

### 1. Before starting a task: check headroom

**If core/watchdog/quota.py exists:**
```bash
python core/watchdog/quota.py status
```
Output example:
```
Anthropic (paid): 68% of window used, resets in 3h 22m
OpenAI (paid): 45% of window used, resets in 2h 45m
OpenRouter (free): unlimited
```

**If the meter doesn't exist yet:** manually check:
- Look at your last session's `STATE.md` or logs (estimate remaining headroom).
- Assume conservatively: if unsure, treat as "high risk" and default to free models.

### 2. Route tasks based on headroom (free-first policy)

**Default routing decision tree:**

```
if vendor_headroom > 80%:
    # Plenty of time in this window — spend freely
    route to paid tier (T2/T3)

elif vendor_headroom 70–80%:
    # Approaching soft threshold
    # Only T3/Board work or the very highest-value T2 tasks
    # Everything else: free tier
    
elif vendor_headroom < 70%:
    # Soft threshold CROSSED
    # ONLY T3 (Board, planning, hard debugging) gets this vendor
    # All T1/T2 work: route to free model (Haiku on free tier, OpenRouter OSS, etc.)
    
elif window_exhausted:
    # DO NOT USE this vendor until it resets
    # Route all work to alternate vendors or free models
    # Log the pause; no human alert
    # Resume automatically at reset time
```

**Example routing decisions:**

| Scenario | Task | Decision |
|---|---|---|
| Anthropic window 50% used, task is T1 (summarize PR) | T1 work | Route to OpenRouter free (OpenNemotron, Llama, etc.) |
| OpenAI window 85% used, task is T3 (Board vote on arch) | T3 work | Use OpenAI's frontier model; it's worth the window spend; OR use Anthropic if its window is better |
| All windows ≥70%, work queue deep with T1 tasks | Bulk T1 work | Batch all T1 on free tier; save paid windows for T2+ only |
| Anthropic window resets in 5 min; OpenAI window exhausted | Mix of T1/T2 work | Queue work; T1 routes to free immediately; pause OpenAI-bound work; T2 uses Anthropic once it resets |

### 3. When the soft threshold is crossed (70% used)

1. **Log the crossing** in `STATE.md` → *Open questions / blockers*:
   ```
   - Anthropic window crossed soft threshold (71% used) at 2026-05-26 14:30 UTC
     - Draining high-value work only until reset (approx 2026-05-26 19:45 UTC)
     - All T1/T2 routing now to free models
   ```

2. **Switch task routing** (see decision tree above):
   - T0 scripts: continue (no model calls).
   - T1 (summaries, PR text, triage): route to **free tier** (OpenRouter free OSS, Claude Haiku free tier if available, or a free/cheap OpenAI model).
   - T2 (real coding, reviews): route to **alternate vendor** with headroom, OR defer to free tier if quality allows.
   - T3 (planning, Board, hard debugging): still use the paid vendor if needed; quality matters more than cost at this tier.

3. **No human alert.** This is *expected operation*, not a failure. The system is designed to hit soft thresholds and degrade gracefully.

4. **Deferrable tasks queue** until the window resets. Non-urgent T2 work (e.g., refactoring, documentation polish) can wait a few hours; urgent blocking work (e.g., fixing a broken test) uses remaining headroom.

### 4. When a window exhausts (100%)

1. **The meter emits:** "Anthropic window exhausted, reset at 2026-05-26 19:45 UTC."

2. **Pause that vendor's tier:**
   - If the orchestrator is about to spawn a T2 Builder on Anthropic, pause that task and re-queue it.
   - Mark the vendor in the state store as `paused_until=<reset_timestamp>`.

3. **Continue on other vendors or free models:**
   - Builders in-flight on that vendor pause, but don't fail. They resume when the window resets.
   - New tasks are routed to OpenAI, OpenRouter, or free tiers.
   - The rest of the project keeps moving—no stall, no human alert.

4. **Auto-resume at reset:**
   - The meter detects the reset timestamp has passed (`datetime.now() >= reset_time`).
   - Unpause the vendor and re-route new work to it.
   - Resume any paused tasks from their last checkpoint.

5. **Log it in STATE.md:**
   ```
   - Anthropic window exhausted at 2026-05-26 17:30; paused T2 routing
   - Resumed at 2026-05-26 19:45 when window reset
   - No impact on build timeline (other vendors covered the gap)
   ```

### 5. Per-vendor metering and Board fallback

The beauty of separate vendor keys (Anthropic, OpenAI, OpenRouter) is that **you always have a backup.**

- If Anthropic window is exhausted, Board votes still happen—they use OpenAI or a third vendor.
- Builders waiting for a reset can work on other streams or defer non-critical tasks.
- Quality is protected because a cheaper alternative exists; cost is the tiebreaker, not the constraint.

**Practical example:**

```
Tuesday 10:00 — Anthropic 60% used, OpenAI 40% used
  → T2 Builder starts coding on Anthropic (plenty of headroom)
  
Tuesday 15:00 — Anthropic hits 71% (soft threshold crossed)
  → New T1 work routes to free models
  → T2 Builder continues on Anthropic (already in-flight; too expensive to pause)
  
Tuesday 18:00 — Anthropic exhausted, reset in 1h 45m
  → Pause new Anthropic T2 work
  → High-value T2 tasks reroute to OpenAI (40% → 65% window)
  → Wait-and-see: if OpenAI reaches soft threshold too, free tier absorbs the rest
  
Tuesday 19:45 — Anthropic resets
  → Unpause, resume; next tasks use Anthropic again
```

### 6. Telemetry: tracking usage over time

**If core/watchdog/quota.py exists and logs usage:**

1. Review dashboards/logs weekly to spot patterns:
   - Which vendor is being drained fastest?
   - Are T1 tasks correctly routing to free models, or is there waste?
   - Is soft-threshold triggering too often (indicating need to route more T1 to free)?

2. Adjust soft-threshold values (default 70%) based on real patterns:
   - If windows frequently hit exhaustion with no warning, lower the threshold (e.g., 65%).
   - If you're too conservative (windows reset with 40% unused), raise it (e.g., 75%).

3. Update the decision tree in `core/watchdog/quota.py` (or this skill's procedure section) if you find a better routing strategy.

### 7. Behavior when the meter is absent (V1 without core/watchdog/)

If you're building before the meter exists:

1. **Track windows manually in STATE.md:**
   ```
   ### Quota status (tracked manually, updated each session)
   - Anthropic: ~60% used, reset 2026-05-26 19:30 UTC (est.)
   - OpenAI: ~40% used, reset 2026-05-26 18:00 UTC (est.)
   ```

2. **Route conservatively:**
   - Always assume the worst (70% used, approaching soft threshold).
   - T1 work: **always** to free models.
   - T2 work: free tier if quality allows; else cheapest paid (T1 tier models if possible).
   - T3 work: best model available (quality > cost).

3. **Once the meter is present:**
   - Remove manual tracking from STATE.md.
   - Call `core/watchdog/quota.py status` instead.
   - The routing logic becomes automated in the orchestrator.

## Pitfalls

**Spending paid windows on T1 work:** The whole design is built on free-first routing. If T1 summaries are using paid Anthropic tokens, you're bleeding the window. Check the routing logic (in Hermes or the orchestrator) and fix it.

**Exhausting a window without pausing.** If you keep sending tasks to a vendor after its window is exhausted, they'll fail with 429 (too many requests) and burn context trying to retry. The guard must pause the vendor the moment exhaustion is detected.

**Manually forcing a model tier despite low headroom.** If the orchestrator says "Anthropic window at 90%, but I'm forcing T3," you will exhaust it before the day ends. Trust the routing decision; if you need T3 quality, use an alternate vendor.

**Forgetting to log the threshold crossing.** If a window hits soft threshold and you don't mention it in STATE.md, the next session won't know to route conservatively. Update STATE.md immediately when it happens.

**Assuming the meter is always correct.** Hermes/the meter estimate usage from token counts or API calls, but it's not 100% precise. Always leave a 5–10% safety margin (treat "80% used" as if it's already at soft threshold).

**Waiting for a window reset instead of using an alternate vendor.** Builds on T1 work can usually be done on a free model in parallel while waiting for a paid window to reset. Don't stall waiting; route around it.

## Verification

- **Headroom is known:** `quota status` (or manual estimate) is current and logged in STATE.md.
- **T1 routing is to free models:** Check the orchestrator logs or Hermes config—T1 tasks are not burning paid windows.
- **Soft threshold is respected:** When a window crosses 70% used, new T1 work is rerouted (not still hitting the expensive vendor).
- **Exhausted vendor is paused:** New tasks do not attempt to use a vendor that hit 100%; instead, they use backups.
- **No human alerts for window behavior:** Soft thresholds and resets are silent; only genuine failures (vendor outage, unrecoverable error) alert the human.
- **Usage is logged:** STATE.md or dashboards show per-vendor usage so you can spot trends and retune thresholds over time.
