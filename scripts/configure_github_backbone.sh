#!/usr/bin/env bash
set -euo pipefail

# Configure the GitHub backbone for AMA on a target repository.
# Requires: gh auth login already done, repository admin rights.
# Usage:
#   scripts/configure_github_backbone.sh owner/repo

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <owner/repo>" >&2
  exit 1
fi

REPO="$1"
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABELS_JSON="$ROOT_DIR/.github/ama-labels.json"

if [[ ! -f "$LABELS_JSON" ]]; then
  echo "missing labels file: $LABELS_JSON" >&2
  exit 1
fi

echo "Applying AMA labels to $REPO"
python3 "$ROOT_DIR/scripts/bootstrap_github_labels.py" --repo "$REPO" --labels "$LABELS_JSON"

echo "Applying branch protection for main"
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$NAME/branches/main/protection" \
  -f required_status_checks.strict=true \
  -F required_status_checks.contexts[]='lint-type-test' \
  -f enforce_admins=true \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -f required_pull_request_reviews.require_code_owner_reviews=false \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false \
  -f block_creations=false \
  -f required_conversation_resolution=true

echo "Backbone configuration complete for $REPO"
