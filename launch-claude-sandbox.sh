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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    echo "   Please navigate to your project directory first:"
    echo "   cd ~/Github/your-project"
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
else
    echo ""
    echo "⚠️  Failed to pull latest image, using cached version"
fi

# Check Claude Code version in the image
echo ""
echo "ℹ️  Claude Code version in Docker image:"
docker run --rm ghcr.io/tdoerks/claude-code-sandbox:latest claude-code --version 2>/dev/null || echo "   (version check skipped)"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Launching Claude Sandbox..."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "   Browser will open automatically at http://localhost:3456"
echo "   Press Ctrl+C to exit"
echo ""

# Launch claude-sandbox
claude-sandbox "$@"
