# Agent Job Descriptions (system prompts)

These are **starter drafts** of the instructions each AI worker in Helm follows. The build sessions will refine them as the code that calls them takes shape (task B1-1 onward) — but starting from these keeps every agent aligned with the design in `../docs/autonomous-agents/FRAMEWORK_SPEC.md` instead of inventing behaviour from scratch.

| File | Worker | Tier | Governed by (spec §) |
|---|---|---|---|
| `concierge.md` | Greets the human, triages, paces planning | T1 (cheap) | §13, §4 |
| `planner.md` | Architect — turns the idea into a buildable plan | T3 | §13, §6 |
| `builder.md` | Implements one task on a branch | T1–T2 | §4, §8 |
| `inverted_reviewer.md` | Cheap adversarial critic (drives escalation) | T1 | §5.3–5.4 |
| `reviewer.md` | Reviews PRs as a merge gate (≠ builder model) | T2 | §4, §8 |
| `board_member.md` | One seat on the 3-vendor approval board | T3 | §7 |

**Conventions for all agents:**
- The repo is the source of truth; read what you need, don't assume memory.
- Comment the *why*, not the *what* (§14). Keep output handover-readable.
- Never rely on your own self-reported confidence to decide quality — that's judged externally (§5.3).
- Stay within the task you were given; flag, don't silently expand scope.
- `{{double_brace}}` tokens are placeholders the calling code fills in at runtime.
