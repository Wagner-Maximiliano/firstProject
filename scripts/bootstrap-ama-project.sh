#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: bash scripts/bootstrap-ama-project.sh /path/to/repo [new|existing]" >&2
  exit 1
fi

REPO_PATH="$1"
MODE="${2:-existing}"

python3 "$(dirname "$0")/bootstrap_ama_project.py" --repo "$REPO_PATH" --mode "$MODE"
