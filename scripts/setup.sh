#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required (python3 -m venv is unavailable in this environment)" >&2
  exit 1
fi

if [ ! -d ".venv" ]; then
  uv venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

uv pip install -e ".[dev]"

echo "Setup complete. Activate with: source .venv/bin/activate"