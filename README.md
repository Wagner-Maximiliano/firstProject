# AMA — Autonomous Multi-Agent Framework

AMA is a portable, Hermes-based framework for running software projects with clearer structure and more automation.

In simple terms, AMA makes a project work more like a disciplined delivery team:
- planning happens first
- tasks live in GitHub issues
- work is routed by labels
- one task uses one branch and one PR
- reviewers control merges
- safe parallel work is allowed
- humans are pulled in only at the right moments

This repository has two purposes:
1. it contains the AMA framework itself
2. it contains the docs and bootstrap assets for installing AMA into other repositories

## What AMA adds to a project

AMA is designed to be brought into either:
- a brand new repository
- an existing repository that needs better structure and project management

The default operating model is:
- AMA manages only AMA-labeled issues
- tasks are created automatically from an approved plan
- tasks are released in batches by phase
- dependencies are explicit
- parallel work is allowed, but overlap is checked first
- implementation work is branch-per-task and PR-based
- normal low-risk tasks can merge after green review and checks
- risky tasks go through an extra gate

## Core GitHub routing model

AMA uses two label families.

Owner labels:
- `ama:owner:orchestrator`
- `ama:owner:builder`
- `ama:owner:reviewer`
- `ama:owner:inverted-reviewer`
- `ama:owner:board`
- `ama:owner:human`

Tier labels:
- `ama:tier:t1`
- `ama:tier:t2`
- `ama:tier:t3`
- `ama:tier:board`

Every AMA-managed issue should have exactly:
- one owner label
- one tier label

See `docs/autonomous-agents/LABEL_ROUTING.md` for the routing contract.

## Installation

There are two layers of setup.

### 1. Install AMA into Hermes once

Clone this repository locally and switch to the build branch that currently carries the latest AMA packaging work:

```bash
git clone https://github.com/Wagner-Maximiliano/AMA-Autonomous_Multi-Agent_Framework.git
cd AMA-Autonomous_Multi-Agent_Framework
git checkout claude/autonomous-agent-framework-5MdEG
```

Register the tap with Hermes:

```bash
hermes skills tap add Wagner-Maximiliano/AMA-Autonomous_Multi-Agent_Framework
```

Run the AMA profile setup:

```bash
bash scripts/setup-ama-profiles.sh
```

That creates the dedicated AMA profiles and installs the AMA skills and bundles.

### 2. Bootstrap AMA into a project repo

New repository:

```bash
bash /path/to/AMA-Autonomous_Multi-Agent_Framework/scripts/bootstrap-ama-project.sh /path/to/your-project new
```

Existing repository:

```bash
bash /path/to/AMA-Autonomous_Multi-Agent_Framework/scripts/bootstrap-ama-project.sh /path/to/your-project existing
```

This adds a small AMA support layer to the target repo:
- `.ama/PROJECT_BRIEF.md`
- `.ama/STATE.md`
- `.ama/config.yaml`
- `.github/ama-labels.json`
- `.github/ISSUE_TEMPLATE/ama-task.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`

It does not copy the AMA framework itself into the project.

### 3. Create AMA labels in GitHub

Use the GitHub helper against the target repository:

```bash
export GITHUB_TOKEN=your_token
python3 scripts/bootstrap_github_labels.py --repo owner/repo
```

That creates or updates the AMA owner and tier labels used for routing.

## Using AMA in a project

1. Bootstrap the target repository.
2. Fill in `.ama/PROJECT_BRIEF.md`.
3. Review `.ama/config.yaml`.
4. Apply the GitHub labels.
5. Start planning:

```bash
hermes -p ama-planner /ama-plan
```

After the plan is approved, AMA can create GitHub issues in phase batches and start the branch-per-task workflow.

## Files and scripts added in this repository

Important operator assets:
- `docs/autonomous-agents/INSTALLATION.md`
- `docs/autonomous-agents/AMA_OPERATOR_RUNBOOK.md`
- `docs/autonomous-agents/LABEL_ROUTING.md`
- `scripts/bootstrap-ama-project.sh`
- `scripts/bootstrap_ama_project.py`
- `scripts/bootstrap_github_labels.py`
- `templates/project-ama/`

## Framework build status

This repository is also the multi-session build repo for AMA itself.

If you are contributing to the framework rather than using it in another project, start with:
- `docs/autonomous-agents/build/SESSION_PROTOCOL.md`
- `docs/autonomous-agents/build/BUILD_PLAN.md`
- `docs/autonomous-agents/build/STATE.md`
- `docs/autonomous-agents/FRAMEWORK_SPEC.md`
- `docs/autonomous-agents/OVERVIEW.md`

## Design docs

- `docs/autonomous-agents/OVERVIEW.md` — plain-English explanation
- `docs/autonomous-agents/FRAMEWORK_SPEC.md` — detailed technical specification
- `docs/autonomous-agents/INSTALLATION.md` — install and bootstrap guide
- `docs/autonomous-agents/AMA_OPERATOR_RUNBOOK.md` — operator guide for real projects
- `docs/autonomous-agents/LABEL_ROUTING.md` — label routing contract

## Current status

Packaging and project-bootstrap scaffolding are in place.
The remaining build work continues in the custom `core/` engine and validation tasks described in `docs/autonomous-agents/build/BUILD_PLAN.md`.
