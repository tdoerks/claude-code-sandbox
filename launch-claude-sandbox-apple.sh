#!/bin/bash
#
# Claude Sandbox Launcher with Auto-Update
# Mac-compatible version
#

set -e

echo "════════════════════════════════════════════════════════════"
echo "🤖 Claude Sandbox Launcher"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Git check ──────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    echo "   Please navigate to your project directory first:"
    echo "   cd ~/Github/your-project"
    exit 1
fi

PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
echo "📁 Project: $PROJECT_NAME"
echo "🌿 Branch: $BRANCH"
echo ""

# ── FIX 1: macOS Docker startup ────────────────────────────────
# On Linux, Docker is a daemon started with `service docker start`.
# On macOS, Docker Desktop is a GUI application. We open it and
# wait a few seconds for the daemon socket to become available.
if ! docker info > /dev/null 2>&1; then
    echo "⚠️  Docker is not running. Starting Docker Desktop..."
    open -a Docker
    echo "   Waiting for Docker to start..."
    # Poll until Docker is ready, timeout after 60 seconds
    timeout=60
    elapsed=0
    while ! docker info > /dev/null 2>&1; do
        sleep 2
        elapsed=$((elapsed + 2))
        if [ "$elapsed" -ge "$timeout" ]; then
            echo "❌ Docker did not start within ${timeout}s. Aborting."
            exit 1
        fi
    done
    echo "✅ Docker is running."
fi

# ── FIX 2: Force amd64 platform ────────────────────────────────
# The sandbox image is only published for linux/amd64 (x86_64).
# Apple Silicon Macs are arm64. Setting this env var tells Docker
# to use Rosetta emulation when pulling and running amd64 images.
# Without this, Docker returns "no matching manifest for arm64".
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "🔍 Checking for Docker image updates..."
echo "   Image: ghcr.io/tdoerks/claude-code-sandbox:latest"
echo "   Platform: linux/amd64 (forced for Apple Silicon compatibility)"
echo ""

if docker pull --platform linux/amd64 ghcr.io/tdoerks/claude-code-sandbox:latest; then
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
# Also pass --platform here so the version-check container matches
docker run --rm --platform linux/amd64 \
    ghcr.io/tdoerks/claude-code-sandbox:latest \
    claude --version 2>/dev/null || echo "   (version check skipped)"

# ── FIX 3: Strip macOS extended attributes ─────────────────────
# com.apple.provenance xattrs cause `docker cp` to fail (lsetxattr 500 error).
# Why the naive `xattr -rc .` fails:
#   Git stores object files (.git/objects/**) as read-only (mode 444).
#   macOS requires WRITE permission on a file to modify its xattrs,
#   even to remove them. So xattr exits non-zero silently on each object.
#
# Fix: grant user-write on .git first, strip xattrs, then we're done.
# (We don't need to restore 444 — git still works fine with 644 objects.)
echo ""
echo "🧹 Stripping macOS extended attributes (xattrs)..."

# Step 1: make git objects user-writable so xattr can touch them
chmod -R u+w .git 2>/dev/null || true

# Step 2: recursively clear all xattrs from the whole project tree
xattr -rc . 2>/dev/null || true

echo "   ✅ xattrs cleared (git objects made writable first)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Launching Claude Sandbox..."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "   Browser will open automatically at http://localhost:3456"
echo "   Press Ctrl+C to exit"
echo ""

# DOCKER_DEFAULT_PLATFORM is already exported above, so claude-sandbox
# will inherit it and use amd64 when it makes its own Docker calls
claude-sandbox "$@"
