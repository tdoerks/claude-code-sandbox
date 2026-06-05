#!/bin/bash
#
# Claude Sandbox Launcher with Auto-Update
# Automatically pulls the latest Docker image before launching
#

set -e

echo "════════════════════════════════════════════════════════════"
echo "🤖 Claude Sandbox Launcher"
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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    echo "   Please choose a directory that is a git repository."
    exit 1
fi

# Show current project
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
echo "📁 Project: $PROJECT_NAME"
echo "🌿 Branch: $BRANCH"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "⚠️  Docker is not running. Starting Docker..."
    sudo service docker start
    sleep 2
fi

# Pull latest Docker image
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

# Check Claude Code version in the image
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
echo "   Browser will open automatically at http://localhost:3456"
echo "   Press Ctrl+C to exit"
echo ""

# Launch claude-sandbox
claude-sandbox "${EXTRA_ARGS[@]}" "$@"
