# AMA Operator Runbook

This is the plain-language guide for using AMA inside a real software project.

AMA has two separate jobs:
1. this repository builds and improves the AMA framework itself
2. AMA then gets installed into other repositories to improve how those projects are planned and managed

This runbook is for job 2.

## What AMA adds to a project

When AMA is installed into a project, it gives you:
- a standard planning flow
- GitHub issues as the source of task truth
- role-based labels so work is routed clearly
- one task per branch and one PR per task
- reviewer-controlled merges
- parallel work where it is safe
- simple human approval gates when a person is really needed

## The default operating rules

These are the defaults chosen for V1:
- AMA manages only issues that carry AMA labels
- AMA creates tasks automatically from an approved plan
- AMA releases tasks in batches by phase, not all at once
- AMA uses explicit dependency metadata, not guesswork alone
- AMA allows parallel work, but checks for likely overlap first
- AMA estimates overlap from issue text, labels, and repo structure, with manual override allowed
- human-owned tasks send reminders and keep waiting
- normal tasks can auto-merge after review and green checks; risky tasks require an extra gate
- a task is only done when it works, tests pass, and there is proof it met the goal
- V1 is code-first; non-code task management can be added later
- onboarding into an existing repo is balanced, not invasive: labels, templates, AMA config, automation, and helper scripts

## The label system

Every AMA-managed issue should have exactly:
- one owner label
- one tier label

### Owner labels
- `ama:owner:orchestrator`
- `ama:owner:builder`
- `ama:owner:reviewer`
- `ama:owner:inverted-reviewer`
- `ama:owner:board`
- `ama:owner:human`

### Tier labels
- `ama:tier:t1`
- `ama:tier:t2`
- `ama:tier:t3`
- `ama:tier:board`

### Default routing rules
- `ama:owner:builder` + `ama:tier:t2` = normal implementation task
- `ama:owner:reviewer` + `ama:tier:t2` = review / merge gate task
- `ama:owner:inverted-reviewer` + `ama:tier:t1` = adversarial critique task
- `ama:owner:board` + `ama:tier:board` = high-impact decision task
- `ama:owner:human` = wait for a person and send reminders
- `ama:owner:orchestrator` = planning, dependency, backlog, routing, and automation task

If labels are obviously fixable, AMA fixes them. If they conflict in a meaningful way, AMA blocks routing and asks for correction instead of guessing.

## Branch and PR model

For every implementation issue:
- one GitHub issue
- one task branch
- one PR

Branch name format:
- `task/<issue-number>-<slug>`

Examples:
- `task/42-add-login-button`
- `task/108-fix-sync-timeout`

Builders never work directly on `main` or `master`.
Reviewers and integrators merge via PR only.

## Parallel work model

AMA can run multiple builder tasks at the same time.

Before starting a task, the orchestrator checks:
- dependency metadata
- likely file or module overlap
- explicit manual overrides

If two tasks likely collide:
- AMA delays or requeues one of them
- AMA does not deliberately create chaos and "sort it out later"

This gives a speed/safety balance.

## Existing-project adoption

AMA is designed to work with a repository that already exists.

Default adoption boundary:
- AMA only touches issues that have AMA labels
- non-AMA issues are left alone

Balanced onboarding means AMA can add:
- `.ama/` project config and state files
- GitHub issue / PR templates
- GitHub label definitions
- helper scripts for label/bootstrap setup
- lightweight documentation for the repo team

It should not silently restructure the whole repository.

## New project vs existing project

### New repository
Use AMA when starting from a clean repo if you want:
- a standard planning flow
- tasks created from the approved plan
- labels and templates from day one

### Existing repository
Use AMA when you want better structure without throwing away the current project.
AMA should:
- inspect the repo
- install the standard project support files
- create AMA labels
- add task/PR templates
- leave current non-AMA issues untouched

## Human touchpoints

AMA should involve a person only when needed:
1. planning sign-off
2. GUI or product testing where human judgment matters
3. risky decision or release gate when rules say so
4. explicit `ama:owner:human` issues

## Recommended bootstrap flow

For a new or existing repo:
1. install AMA into Hermes once on the machine
2. run the project bootstrap helper against the target repo
3. optionally apply AMA labels to GitHub using the GitHub API helper
4. fill in `.ama/PROJECT_BRIEF.md`
5. start planning with the AMA planner profile
6. let AMA create phase-batched tasks in GitHub after the plan is approved

## Minimal files added to a project

Recommended project-local files:
- `.ama/PROJECT_BRIEF.md`
- `.ama/config.yaml`
- `.ama/STATE.md`
- `.github/ISSUE_TEMPLATE/ama-task.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ama-labels.json`

These files make the project AMA-aware without copying the framework into the repo.

## What this runbook does not cover yet

Not part of V1 operator rollout:
- full non-code work management
- rich dashboards
- advanced merge queues
- heavy repo restructuring during adoption

Those can be added later without changing the basic model above.
