# AMA Installation and Project Bootstrap

This guide explains two different setup layers:
1. install AMA into Hermes once on your machine
2. bootstrap AMA support into a specific repository

They are not the same thing.

## 1. Install AMA into Hermes once

From a local clone of this repository:

```bash
git clone https://github.com/Wagner-Maximiliano/AMA-Autonomous_Multi-Agent_Framework.git
cd AMA-Autonomous_Multi-Agent_Framework
git checkout claude/autonomous-agent-framework-5MdEG
```

Register the tap with Hermes:

```bash
hermes skills tap add Wagner-Maximiliano/AMA-Autonomous_Multi-Agent_Framework
```

Then run the AMA profile setup:

```bash
bash scripts/setup-ama-profiles.sh
```

This creates the AMA profiles and installs the skills and bundles used by AMA.

## 2. Bootstrap AMA into a project repo

AMA should feel simple in both a new repo and an existing repo.

### New repository

```bash
bash /path/to/AMA-Autonomous_Multi-Agent_Framework/scripts/bootstrap-ama-project.sh /path/to/your-project new
```

### Existing repository

```bash
bash /path/to/AMA-Autonomous_Multi-Agent_Framework/scripts/bootstrap-ama-project.sh /path/to/your-project existing
```

This adds only the small project-local AMA files:
- `.ama/PROJECT_BRIEF.md`
- `.ama/STATE.md`
- `.ama/config.yaml`
- `.github/ama-labels.json`
- `.github/ISSUE_TEMPLATE/ama-task.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`

It does not copy the framework into the project.

## 3. Create AMA labels in GitHub

If you want AMA issue routing to work in GitHub, create the labels in the target repository.

```bash
export GITHUB_TOKEN=your_token
python3 scripts/bootstrap_github_labels.py --repo owner/repo
```

This reads `.github/ama-labels.json` and creates or updates:
- `ama:owner:orchestrator`
- `ama:owner:builder`
- `ama:owner:reviewer`
- `ama:owner:inverted-reviewer`
- `ama:owner:board`
- `ama:owner:human`
- `ama:tier:t1`
- `ama:tier:t2`
- `ama:tier:t3`
- `ama:tier:board`

## 4. Fill in the project brief

Inside the project repo:

```bash
cd /path/to/your-project
```

Edit:
- `.ama/PROJECT_BRIEF.md`
- `.ama/config.yaml`

At minimum, confirm:
- whether this is a new or existing repo
- which branch AMA should work from
- the main outcome for the phase
- any constraints or no-go areas

## 5. Start AMA planning

Once the project brief is filled in, start planning with the AMA planner profile:

```bash
hermes -p ama-planner /ama-plan
```

After plan approval, AMA can create phase-batched GitHub issues with AMA labels and start the branch-per-task workflow.

## What happens in an existing repo

AMA is intentionally conservative in an existing repository.

Default behavior:
- AMA only manages issues with AMA labels
- non-AMA issues remain untouched
- parallel work is allowed only when dependencies and overlap checks say it is safe
- one implementation issue becomes one branch and one PR

## What happens in a new repo

AMA installs the same small support layer, but the repo can start cleanly with AMA-managed tasks from day one.

## Related docs

- `README.md`
- `docs/autonomous-agents/AMA_OPERATOR_RUNBOOK.md`
- `docs/autonomous-agents/LABEL_ROUTING.md`
