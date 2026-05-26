#!/bin/bash
# Setup AMA dedicated profiles on this machine.
#
# This script creates six new Hermes profiles (ama-planner, ama-builder, ama-reviewer,
# ama-board-a, ama-board-b, ama-board-c) and installs the AMA framework skills and
# bundles into each. It NEVER modifies or touches your existing personal profiles.
#
# Before running, set the AMA tap repo (your fork of the framework):
#   export AMA_TAP_REPO="wagner-maximiliano/firstProject"
# Or let it default to that.
#
# Run:
#   bash scripts/setup-ama-profiles.sh

set -euo pipefail

# Run from the repo root so the relative paths below (profiles/, skill-bundles/)
# resolve no matter where the script is invoked from.
cd "$(dirname "$0")/.."

# ============================================================================
# Configuration
# ============================================================================

# Hermes tap repo (where the framework skills and bundles live).
# Override by setting AMA_TAP_REPO in the environment.
TAP_REPO="${AMA_TAP_REPO:-wagner-maximiliano/firstProject}"

# Profile definitions: name, description, model tier (from config/settings.yaml)
declare -A PROFILES=(
  [ama-planner]="AMA Planner (architect, planning workflows)|T3"
  [ama-builder]="AMA Builder (implementation, task execution)|T2"
  [ama-reviewer]="AMA Reviewer (code review, gatekeeper)|T2"
  [ama-board-a]="AMA Board Seat A (Anthropic lens, decisions)|BOARD"
  [ama-board-b]="AMA Board Seat B (OpenAI lens, decisions)|BOARD"
  [ama-board-c]="AMA Board Seat C (OpenRouter lens, decisions)|BOARD"
)

# Tier to model mapping (must match config/settings.yaml)
declare -A TIER_MODELS=(
  [T3]="anthropic/claude-opus-4-1"
  [T2]="anthropic/claude-sonnet-4-20250514"
  [T1]="openrouter/nvidia/nemotron-mini"
)

# Board seat to model mapping (must match config/settings.yaml)
declare -A BOARD_MODELS=(
  [seat_a]="anthropic/claude-opus-4-1"
  [seat_b]="openai/gpt-4o"
  [seat_c]="openrouter/anthropic/claude-opus"
)

# ============================================================================
# Helpers
# ============================================================================

log() {
  echo "[AMA Setup] $*" >&2
}

log_ok() {
  echo "[AMA Setup] OK: $*" >&2
}

log_warn() {
  echo "[AMA Setup] WARNING: $*" >&2
}

log_error() {
  echo "[AMA Setup] ERROR: $*" >&2
  exit 1
}

# Check if a Hermes profile already exists.
profile_exists() {
  local profile_name="$1"
  # VERIFY: Hermes profile home location may differ per version; usually ~/.hermes/profiles/<name>
  if [ -d "$HOME/.hermes/profiles/$profile_name" ]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Main
# ============================================================================

log "Starting AMA profile setup..."
log "Tap repo: $TAP_REPO"

# Verify Hermes is installed.
if ! command -v hermes &> /dev/null; then
  log_error "hermes not found. Install Hermes first: https://github.com/NousResearch/hermes-agent"
fi

log "Hermes found: $(hermes --version 2>&1 || echo 'version unknown')"

# Create each AMA profile.
for profile_name in "${!PROFILES[@]}"; do
  IFS="|" read -r description tier <<< "${PROFILES[$profile_name]}"

  log ""
  log "Setting up profile: $profile_name"
  log "  Description: $description"
  log "  Tier: $tier"

  # Check if profile already exists.
  if profile_exists "$profile_name"; then
    log_warn "$profile_name already exists; skipping creation (will update config and bundles)"
  else
    log "Creating profile $profile_name..."
    # VERIFY: hermes profile create syntax may vary; check `hermes profile --help`
    hermes profile create "$profile_name" --description "$description" || \
      log_error "Failed to create profile $profile_name"
    log_ok "Created profile $profile_name"
  fi

  # Set the model.default in the profile's config.
  if [ "$tier" = "BOARD" ]; then
    # Board seats: map by seat name (e.g., ama-board-a → seat_a → model)
    seat_key="${profile_name#ama-board-}"
    seat_key="seat_$seat_key"
    model="${BOARD_MODELS[$seat_key]}"
  else
    # Regular profiles: tier → model
    model="${TIER_MODELS[$tier]}"
  fi

  log "Setting $profile_name model to: $model"
  # VERIFY: hermes config set syntax for per-profile config
  hermes -p "$profile_name" config set model.default "$model" || \
    log_warn "Failed to set model for $profile_name; continue anyway"

  # Copy SOUL.md from repo into the profile's home.
  soul_src="profiles/$profile_name/SOUL.md"
  soul_dst="$HOME/.hermes/profiles/$profile_name/SOUL.md"
  if [ -f "$soul_src" ]; then
    log "Copying SOUL.md into profile home..."
    mkdir -p "$(dirname "$soul_dst")"
    cp "$soul_src" "$soul_dst"
    log_ok "SOUL.md copied"
  else
    log_warn "SOUL.md not found at $soul_src; skipping"
  fi

  # Copy skill bundles into the profile's home.
  # VERIFY: Exact bundle directory location in profile home; usually ~/.hermes/profiles/<name>/bundles/
  bundles_dst="$HOME/.hermes/profiles/$profile_name/bundles"
  mkdir -p "$bundles_dst"
  if [ -d "skill-bundles" ]; then
    log "Copying skill bundles..."
    cp -v skill-bundles/*.yaml "$bundles_dst/" || log_warn "Some bundles failed to copy"
    log_ok "Bundles copied"
  fi
done

# Add the tap and install skills for each profile.
log ""
log "Installing AMA tap and skills..."

# Add the tap globally (once is enough).
log "Adding tap: $TAP_REPO"
# VERIFY: hermes skills tap add syntax
hermes skills tap add "$TAP_REPO" || \
  log_warn "Tap add failed; may already be installed"

# Install skills into each profile.
for profile_name in "${!PROFILES[@]}"; do
  log "Installing skills into $profile_name..."
  # VERIFY: hermes -p <profile> skills install syntax
  hermes -p "$profile_name" skills install ama-planning ama-build-task ama-review ama-board \
    ama-github-workflow ama-session-handoff ama-human-testing ama-quota-guard || \
    log_warn "Some skills failed to install into $profile_name"
done

log ""
log_ok "AMA profile setup complete!"
log ""
log "Next steps:"
log "  1. Verify Hermes CLI commands match your version: hermes --help, hermes profile --help, hermes skills --help"
log "  2. For each profile, verify model config: hermes -p <profile-name> config show"
log "  3. Set your API keys in the environment:"
log "     export ANTHROPIC_API_KEY=<your-key>"
log "     export OPENAI_API_KEY=<your-key>"
log "     export OPENROUTER_API_KEY=<your-key>"
log "  4. Kick off a build session with the Planner:"
log "     hermes -p ama-planner /ama-plan"
log ""
