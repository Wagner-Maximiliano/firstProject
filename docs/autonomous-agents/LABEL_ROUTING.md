# AMA Label Routing Spec

This file is the routing contract for AMA-managed GitHub issues.

## Required labels

Every AMA-managed issue must have:
- exactly one `ama:owner:*` label
- exactly one `ama:tier:*` label

If either is missing, the orchestrator can repair the obvious default.
If labels conflict, the orchestrator blocks the issue and asks for correction.

## Owner labels

### `ama:owner:orchestrator`
Meaning:
- coordination, planning, dependency, release, routing, backlog, or automation work

Actor:
- orchestrator

Default tier:
- `ama:tier:t1`

### `ama:owner:builder`
Meaning:
- code, tests, docs, or implementation work

Actor:
- builder

Typical tiers:
- `ama:tier:t1` for trivial work
- `ama:tier:t2` for normal implementation
- `ama:tier:t3` for hard implementation or debugging

Branch rule:
- must use `task/<issue-number>-<slug>`

### `ama:owner:inverted-reviewer`
Meaning:
- adversarial check against the acceptance criteria

Actor:
- inverted reviewer

Default tier:
- `ama:tier:t1`

Branch rule:
- normally no branch required

### `ama:owner:reviewer`
Meaning:
- formal review and merge gate

Actor:
- reviewer / integrator

Default tier:
- `ama:tier:t2`

Rule:
- reviewer must not be the same model instance that built the task

### `ama:owner:board`
Meaning:
- high-impact decision task

Actor:
- 3-seat board flow

Required tier:
- `ama:tier:board`

### `ama:owner:human`
Meaning:
- explicit human input or action required

Actor:
- human

Reminder policy:
- remind after the configured interval, then keep waiting

## Tier labels

### `ama:tier:t1`
Use for:
- triage
- summaries
- simple edits
- adversarial checks
- lightweight orchestration

### `ama:tier:t2`
Use for:
- standard coding
- standard review
- normal debugging

### `ama:tier:t3`
Use for:
- hard debugging
- architecture-level implementation
- complex reasoning tasks

### `ama:tier:board`
Use for:
- board-only decisions

## Default lifecycle

1. Issue created from an approved plan
- owner: `ama:owner:orchestrator`
- tier: `ama:tier:t1`

2. Ready to implement
- owner: `ama:owner:builder`
- tier: usually `ama:tier:t2`

3. Builder opens PR
- owner: `ama:owner:inverted-reviewer`
- tier: `ama:tier:t1`

4. Adversarial pass clears
- owner: `ama:owner:reviewer`
- tier: `ama:tier:t2`

5. Review and checks clear
- merge PR
- close issue or mark done in the board workflow

6. Risk trigger hit
- owner: `ama:owner:board`
- tier: `ama:tier:board`

7. Human action required
- owner: `ama:owner:human`
- send reminder on schedule and wait

## Board triggers

Send a task to the board when any of these apply:
- security, auth, or secrets
- schema or data migration
- infrastructure or deployment change
- new dependency with meaningful impact
- irreversible or high-blast-radius change

## Parallel work rules

Parallel builder tasks are allowed when:
- dependencies are satisfied
- likely overlap is low enough
- no manual override blocks parallel execution

Overlap detection uses:
- issue text
- labels
- repo structure
- manual override where supplied

When overlap is likely:
- the orchestrator delays or requeues one task
- it does not allow uncontrolled collision by default

## Done criteria

A task is done only when:
- the change works
- tests pass
- there is proof it met the goal

Examples of proof:
- acceptance checklist completed
- test output
- screenshots for UI work
- concise reviewer-ready summary
