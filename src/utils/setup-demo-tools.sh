#!/usr/bin/env bash
# =============================================================================
# setup-demo-tools.sh
#
# GAZ-270: Integration script for mifos-gazelle-demo-creator and
#          mifos-gazelle-demo-runtime companion repositories.
#
# Design principle: Gazelle is the central orchestrator. This script pulls
# the demo tooling INTO Gazelle, keeping all deployment control in one place.
# This aligns with the unified DPG strategy established in GAZ-269.
#
# Usage:   bash src/utils/setup-demo-tools.sh
# Idempotent: Yes — safe to run multiple times.
#
# Notes on each tool:
#   demo-creator  — Python 3 TUI (Textual). No requirements.txt; uses
#                   pyproject.toml. Install via: pip install -e .
#                   Entry point: .venv/bin/python main.py
#                   Requires sudo-cached credentials on first run (just run).
#
#   demo-runtime  — React + Vite (TypeScript). npm start === vite dev server.
#                   Served at http://localhost:5173
#                   Needs VITE_API_URL in .env (see .env.example).
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve the repo root regardless of where the script is called from
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEMO_CREATOR_REPO="https://github.com/openMF/mifos-gazelle-demo-creator.git"
DEMO_RUNTIME_REPO="https://github.com/openMF/mifos-gazelle-demo-runtime.git"

REPOS_DIR="${REPO_ROOT}/repos"
CREATOR_DIR="${REPOS_DIR}/mifos-gazelle-demo-creator"
RUNTIME_DIR="${REPOS_DIR}/mifos-gazelle-demo-runtime"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo "  [INFO]  $*"; }
success() { echo "  [OK]    $*"; }
header()  { echo; echo "▶ $*"; echo "$(printf '─%.0s' {1..60})"; }

check_dependency() {
  local cmd="$1"
  if ! command -v "${cmd}" &>/dev/null; then
    echo "  [ERROR] Required command not found: ${cmd}"
    echo "          Please install '${cmd}' and re-run this script."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
header "Pre-flight dependency checks"
check_dependency git
check_dependency python3
check_dependency npm
success "git, python3, and npm are all available."

# ---------------------------------------------------------------------------
# Step 1 — Ensure repos/ directory exists
# ---------------------------------------------------------------------------
header "Step 1 — Ensuring repos/ directory exists"
mkdir -p "${REPOS_DIR}"
success "repos/ directory ready at: ${REPOS_DIR}"

# ---------------------------------------------------------------------------
# Step 2 — Clone or update mifos-gazelle-demo-creator
# ---------------------------------------------------------------------------
header "Step 2 — mifos-gazelle-demo-creator"
if [ -d "${CREATOR_DIR}/.git" ]; then
  info "Repository already exists. Pulling latest changes from origin/main ..."
  git -C "${CREATOR_DIR}" pull origin main
else
  info "Cloning ${DEMO_CREATOR_REPO} ..."
  git clone "${DEMO_CREATOR_REPO}" "${CREATOR_DIR}"
fi
success "mifos-gazelle-demo-creator is up to date."

# ---------------------------------------------------------------------------
# Step 3 — Python venv + pip install for demo-creator
# ---------------------------------------------------------------------------
# demo-creator uses pyproject.toml (no requirements.txt).
# Dependencies (textual, jsonschema, requests) are declared under
# [project.dependencies] and installed via: pip install -e .
# ---------------------------------------------------------------------------
header "Step 3 — Python venv + dependencies for demo-creator"
VENV_DIR="${CREATOR_DIR}/.venv"

if [ ! -d "${VENV_DIR}" ]; then
  info "Creating Python 3 virtual environment at ${VENV_DIR} ..."
  python3 -m venv "${VENV_DIR}"
else
  info "Virtual environment already exists, skipping creation."
fi

info "Installing Python dependencies via pyproject.toml (pip install -e .) ..."
"${VENV_DIR}/bin/pip" install --quiet --upgrade pip
"${VENV_DIR}/bin/pip" install --quiet -e "${CREATOR_DIR}"
success "Python dependencies installed (textual, jsonschema, requests)."

# ---------------------------------------------------------------------------
# Step 4 — Clone or update mifos-gazelle-demo-runtime
# ---------------------------------------------------------------------------
header "Step 4 — mifos-gazelle-demo-runtime"
if [ -d "${RUNTIME_DIR}/.git" ]; then
  info "Repository already exists. Pulling latest changes from origin/main ..."
  git -C "${RUNTIME_DIR}" pull origin main
else
  info "Cloning ${DEMO_RUNTIME_REPO} ..."
  git clone "${DEMO_RUNTIME_REPO}" "${RUNTIME_DIR}"
fi
success "mifos-gazelle-demo-runtime is up to date."

# ---------------------------------------------------------------------------
# Step 5 — npm install for demo-runtime
# ---------------------------------------------------------------------------
header "Step 5 — npm install for demo-runtime"
if [ -f "${RUNTIME_DIR}/package.json" ]; then
  info "Running npm install (silent mode) ..."
  npm install --silent --prefix "${RUNTIME_DIR}"
  success "npm dependencies installed."
else
  info "No package.json found in demo-runtime — skipping npm install."
fi

# ---------------------------------------------------------------------------
# Done — print usage instructions
# ---------------------------------------------------------------------------
header "Setup complete"
echo
echo "  Both demo tools are installed under: ${REPOS_DIR}"
echo
echo "  ┌──────────────────────────────────────────────────────────────┐"
echo "  │  To start the Demo Creator (Python TUI):                     │"
echo "  │                                                              │"
echo "  │    cd repos/mifos-gazelle-demo-creator                       │"
echo "  │    source .venv/bin/activate                                 │"
echo "  │    python main.py                                            │"
echo "  │                                                              │"
echo "  │  NOTE: The TUI uses sudo internally on first run.            │"
echo "  │  Have your password ready. After authoring demos, run:       │"
echo "  │    just publish                                              │"
echo "  │  to sync demos into repos/mifos-gazelle-demo-runtime.        │"
echo "  │  (Requires 'just' CLI — see scripts/install_dependencies.sh) │"
echo "  │                                                              │"
echo "  │  To start the Demo Runtime (React/Vite, http://localhost:5173):│"
echo "  │                                                              │"
echo "  │    cd repos/mifos-gazelle-demo-runtime                       │"
echo "  │    cp .env.example .env   # then set VITE_API_URL            │"
echo "  │    npm start                                                 │"
echo "  │                                                              │"
echo "  └──────────────────────────────────────────────────────────────┘"
echo
success "GAZ-270 demo integration setup complete."

