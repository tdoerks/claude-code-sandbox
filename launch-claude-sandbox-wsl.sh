#!/bin/bash
#
# Claude Sandbox Launcher with Auto-Update — WSL2 edition
#
# For running inside a WSL2 Linux distro (e.g. Ubuntu) with Docker provided either
# by Docker Desktop's WSL integration or by a native docker engine in the distro.
#

set -e

# Resolve the script's own directory BEFORE any cd, so we can find the local build.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve which claude-sandbox CLI to run. Prefer the repo's local build (it has the
# latest features like --skills / --network); the globally-installed npm package is
# often stale. Sets the CLI_CMD array.
resolve_cli() {
    if [ -f "$SCRIPT_DIR/dist/cli.js" ]; then
        CLI_CMD=(node "$SCRIPT_DIR/dist/cli.js")
    elif [ -d "$SCRIPT_DIR/node_modules" ] && [ -f "$SCRIPT_DIR/package.json" ]; then
        echo "🔨 Building claude-sandbox from source (first run)..."
        (cd "$SCRIPT_DIR" && npm run build)
        CLI_CMD=(node "$SCRIPT_DIR/dist/cli.js")
    else
        echo "⚠️  Using globally installed 'claude-sandbox' (may be outdated)."
        echo "    For the latest features run: (cd \"$SCRIPT_DIR\" && npm install && npm run build)"
        CLI_CMD=(claude-sandbox)
    fi
}
resolve_cli

echo "════════════════════════════════════════════════════════════"
echo "🤖 Claude Sandbox Launcher (WSL2)"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Directory selection ────────────────────────────────────────
# Ask which project directory to launch from (default: current dir).
# If a directory is passed as the first argument, use it without prompting.
TARGET_DIR=""
if [ -n "$1" ] && [ -d "$1" ]; then
    TARGET_DIR="$1"
    shift
else
    read -e -r -p "📂 Project directory to launch from [$(pwd)]: " TARGET_DIR
    TARGET_DIR="${TARGET_DIR:-$(pwd)}"
fi
# Expand a leading ~ to $HOME
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory does not exist: $TARGET_DIR"
    exit 1
fi
cd "$TARGET_DIR"
echo "   Using: $(pwd)"
echo ""

# ── Git check ──────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    echo "   Please choose a directory that is a git repository."
    exit 1
fi

PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
echo "📁 Project: $PROJECT_NAME"
echo "🌿 Branch: $BRANCH"
echo ""

# ── Docker check (WSL2) ────────────────────────────────────────
# In WSL2, Docker is usually provided by Docker Desktop's WSL integration. If that's
# the case, the `docker` command works once Docker Desktop is running on Windows.
# Some users instead run a native docker engine inside the distro — try to start it.
if ! docker info > /dev/null 2>&1; then
    echo "⚠️  Docker is not available in this WSL distro."
    echo "    • If you use Docker Desktop: make sure it's running on Windows and that"
    echo "      WSL integration is enabled for this distro"
    echo "      (Docker Desktop → Settings → Resources → WSL integration)."
    echo "    • If you use a native docker engine: attempting to start it..."
    sudo service docker start 2>/dev/null || true
    sleep 2
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker still not available. Start Docker and re-run."
        exit 1
    fi
fi
echo "✅ Docker is available."
echo ""

# ── Pull latest image ──────────────────────────────────────────
echo "🔍 Checking for Docker image updates..."
echo "   Image: ghcr.io/tdoerks/claude-code-sandbox:latest"
echo ""

if docker pull ghcr.io/tdoerks/claude-code-sandbox:latest; then
    echo ""
    echo "✅ Docker image up to date!"
    # Re-tag so claude-sandbox finds it under its expected local name
    docker tag ghcr.io/tdoerks/claude-code-sandbox:latest claude-code-sandbox:latest
else
    echo ""
    echo "⚠️  Failed to pull latest image, using cached version"
fi

echo ""
echo "ℹ️  Claude Code version in Docker image:"
docker run --rm ghcr.io/tdoerks/claude-code-sandbox:latest claude --version 2>/dev/null || echo "   (version check skipped)"
echo ""

# ── Skills (optional) ──────────────────────────────────────────
# Inject Claude skills (distributed as .zip) into the container at launch.
# These go into the container only and are never added to your repo.
EXTRA_ARGS=()
read -e -r -p "🧩 Path to a folder of skill .zip files (blank to skip): " SKILLS_DIR
SKILLS_DIR="${SKILLS_DIR/#\~/$HOME}"
if [ -n "$SKILLS_DIR" ]; then
    if [ -d "$SKILLS_DIR" ]; then
        EXTRA_ARGS+=(--skills "$SKILLS_DIR")
        echo "   Skills will be injected from: $SKILLS_DIR"
    else
        echo "   ⚠️  Skills path not found, skipping: $SKILLS_DIR"
    fi
fi
echo ""

# ── Network restriction (optional) ─────────────────────────────
echo "🌐 Network access:"
echo "   1) Full internet (default)"
echo "   2) Allowlist only (Anthropic API + GitHub) — sandboxed"
read -r -p "   Choose [1/2]: " NET_CHOICE
if [ "$NET_CHOICE" = "2" ]; then
    EXTRA_ARGS+=(--network allowlist)
    echo "   Network: allowlist (Anthropic + GitHub only)"
else
    echo "   Network: full internet"
fi
echo ""

echo "════════════════════════════════════════════════════════════"
echo "🚀 Launching Claude Sandbox..."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "   Web UI: http://localhost:3456"
echo "   ⓘ  In WSL the browser may not open automatically — if it doesn't,"
echo "      open http://localhost:3456 in your Windows browser."
echo "   Press Ctrl+C to exit"
echo ""

# Try to open the Windows browser from WSL if a helper is available (best-effort).
if command -v wslview > /dev/null 2>&1; then
    (sleep 3 && wslview "http://localhost:3456" >/dev/null 2>&1) &
fi

# Launch claude-sandbox (repo-local build preferred)
"${CLI_CMD[@]}" "${EXTRA_ARGS[@]}" "$@"
