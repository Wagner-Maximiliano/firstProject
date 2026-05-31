# ADR-0003 — Adopt AMA into project repositories via GitHub-native routing and lightweight bootstrap

- Status: Accepted
- Date: 2026-05-31
- Relates to: ADR-0002 packaging as a Hermes tap; operator-facing rollout for new and existing repositories

## Context

The human clarified that the framework must not only be buildable in this repository. It must also be easy to bring into any target project so the project itself becomes better structured and better managed.

Three gaps were identified in the operator story:
1. there was no concrete onboarding path for an existing repository
2. there was no clear GitHub-native routing model for ownership, labels, branches, and PR flow
3. there was no project-local bootstrap package to make installation simple and repeatable

The human also chose the operating defaults for V1-style project usage:
- AMA manages only AMA-labeled issues
- tasks are created automatically from an approved plan
- tasks are released in batches by phase
- explicit dependency metadata is preferred
- parallel work is allowed, but overlap should be handled with a smart balance rather than strict locking or free-for-all collision
- implementation uses branch-per-task and reviewer-controlled merge
- label governance should be controlled: one owner label and one tier label per AMA-managed issue
- human-owned tasks send reminders and keep waiting
- existing-repo onboarding should be balanced, not invasive

## Decision

1. AMA adopts into a project through a lightweight project-local support layer, not by copying the full framework.

2. Every AMA-managed project gets a small bootstrap package:
- `.ama/PROJECT_BRIEF.md`
- `.ama/STATE.md`
- `.ama/config.yaml`
- `.github/ama-labels.json`
- `.github/ISSUE_TEMPLATE/ama-task.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`

3. GitHub becomes the routing contract for project execution:
- one AMA issue = one unit of work
- one implementation issue = one branch = one PR
- owner and tier labels determine who should act and at what capability lane

4. The required label families are:
- owner: `ama:owner:orchestrator|builder|reviewer|inverted-reviewer|board|human`
- tier: `ama:tier:t1|t2|t3|board`

5. Existing repositories are onboarded conservatively:
- AMA only manages issues with AMA labels
- non-AMA issues remain untouched
- the bootstrap adds support files and templates but does not silently restructure the repo

6. Parallel work is part of the project contract, but with overlap-aware scheduling:
- AMA may run multiple builder tasks in parallel
- before routing, the orchestrator should consider dependency metadata, issue text, labels, repo structure, and manual overrides
- when overlap is likely, AMA delays or requeues one task instead of allowing uncontrolled collision

7. Merge authority is risk-sensitive:
- normal tasks may auto-merge after review and green checks
- risky tasks require the additional gate defined by the broader framework rules

8. "Done" requires proof:
- a task is done only when the change works, tests pass, and evidence shows the intended outcome was met

## Consequences

Positive:
- installing AMA into a project becomes repeatable and simple
- existing repos get a safe adoption boundary
- GitHub issues and labels become a clear operating surface for both humans and agents
- the project contract becomes parallel-ready even before the full custom engine is finished

Negative / trade-offs:
- project onboarding now spans both Hermes-global setup and repo-local bootstrap
- the routing model adds label discipline that must be respected
- full autonomous parallel execution still depends on later `core/` implementation work; this ADR defines the operator contract and bootstrap assets, not the finished engine

## Follow-ups

- Keep README and installation docs aligned with this onboarding model.
- Build the corresponding `core/` orchestrator behavior that enforces the routing contract.
- Add validation and dry-run verification around the bootstrap helpers and label application flow.
