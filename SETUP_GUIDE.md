# Claude Sandbox - Complete Setup Guide

Complete reference for setting up and launching Claude Sandbox on your computer.

## Step 1: Open Ubuntu

In PowerShell:

```powershell
wsl -d Ubuntu-24.04
```

Or from Start Menu: Search "Ubuntu" and click it.

## Step 2: Pull the Pre-Built Docker Image

**NEW: No need to build or install anything!** We maintain auto-updated Docker images:

```bash
docker pull ghcr.io/tdoerks/claude-code-sandbox:latest
```

This image:
- ✅ Auto-updates nightly with latest Claude Code
- ✅ Includes all dependencies pre-installed
- ✅ No npm install/build required
- ✅ Always stays current

**That's it!** You don't need to install the npm package or run `npm link`. The Docker image has everything.

### Advanced: Install from Source (Optional)

**Only for developers** who want to modify the claude-sandbox tool itself:

```bash
cd ~/Github/claude-code-sandbox
git pull origin main
npm install
npm run build
sudo npm link  # Makes 'claude-sandbox' command available globally
```

**For normal use, skip this section** - the Docker image is all you need!

## Step 3: Set Up GitHub Credentials (One-Time Setup)

This allows Claude to push commits and create PRs automatically.

### Install and Authenticate GitHub CLI

Install GitHub CLI:

```bash
sudo apt update
sudo apt install gh
```

Authenticate with GitHub:

```bash
gh auth login
```

Follow the prompts:

1. **What account?** → GitHub.com (press Enter)
2. **Protocol?** → HTTPS (press Enter)
3. **Authenticate Git?** → Yes (press Enter)
4. **How to authenticate?** → Login with a web browser (press Enter)
5. **Copy the one-time code** (e.g., `4D37-508D`)
6. **Press Enter**

⚠️ **Browser Won't Auto-Open in WSL (This is Normal!)**

You'll see an error:

```
! Failed opening a web browser at https://github.com/login/device
exec: "xdg-open,x-www-browser,www-browser,wslview": executable file not found in $PATH
Please try entering the URL in your browser manually
```

This is expected in WSL! Do this manually:

1. Open your **Windows browser** (Chrome, Edge, etc.)
2. Go to: https://github.com/login/device
3. **Paste the code** you copied (e.g., `9454-514C`)
4. Click **"Continue"**
5. Click **"Authorize GitHub CLI"**
6. Go back to Ubuntu terminal and press Enter

You'll see:

```
✓ Authentication complete.
✓ Logged in as your-github-username
```

Verify it works:

```bash
gh auth status
```

Should show:

```
✓ Logged in to github.com account your-github-username
```

### Configure Git Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

Verify:

```bash
git config --global --list
```

Should show your name and email.

✅ GitHub setup complete! You can now push and create PRs from claude-sandbox.

## Step 4: Configure Claude Sandbox to Use Pre-Built Image

In your project directory, create or update `claude-sandbox.config.json`:

```json
{
  "dockerImage": "ghcr.io/tdoerks/claude-code-sandbox:latest",
  "autoPush": true,
  "autoCreatePR": true
}
```

This tells claude-sandbox to use the pre-built image instead of building locally.

## Step 5: Navigate to Your Project

Navigate to your project directory:

```bash
cd ~/Github/your-project-name
```

Examples:

```bash
# For a web app project
cd ~/Github/my-web-app

# For a data science project
cd ~/Github/ml-pipeline

# For testing with claude-code-sandbox itself
cd ~/Github/claude-code-sandbox
```

To clone a new project:

```bash
cd ~/Github
git clone https://github.com/username/repo-name.git
cd repo-name
```

## Step 6: Get the Auto-Update Launch Script

Download the launch script that automatically pulls the latest Docker image:

```bash
cd ~/Github
git clone https://github.com/tdoerks/claude-code-sandbox.git
```

## Step 7: Launch Claude Sandbox!

**Option 1: Use the Auto-Update Launch Script (Recommended)**

```bash
cd ~/Github/your-project
~/Github/claude-code-sandbox/launch-claude-sandbox.sh
```

This script automatically:
- Pulls the latest Docker image
- Shows the Claude Code version
- Launches the sandbox

**Option 2: Direct Launch**

If you installed from source (Step 2 Advanced):

```bash
cd ~/Github/your-project
claude-sandbox
```

Browser should auto-open with the Claude interface connected to your project!

## What Claude Sandbox Does

Once running, Claude can:

✅ Read/write code in your repo
✅ Execute commands safely in Docker container
✅ Run tests
✅ Make git commits
✅ **Push to GitHub** (with your credentials)
✅ **Create Pull Requests** (automated)
✅ Debug issues
✅ Refactor code
✅ Create new features

All isolated in Docker for safety!

## When Claude Makes a Commit

You'll see:

1. **Real-time notification**
2. **Full diff with syntax highlighting**
3. **Interactive menu with options:**
   - Continue working
   - Push branch to remote ← Uses your GitHub credentials!
   - Push and create PR ← Automated PR creation!
   - Exit

## Working on Different Projects

Each project gets its own isolated Docker container!

```bash
# Stop current sandbox (Ctrl+C in terminal)

# Start new project
cd ~/Github/different-project
claude-sandbox
```

## Docker Image Updates

The pre-built image auto-updates nightly:

- Checks for new Claude Code releases
- Rebuilds automatically when updates available
- Pull latest version anytime:

```bash
docker pull ghcr.io/tdoerks/claude-code-sandbox:latest
```

View build status: https://github.com/tdoerks/claude-code-sandbox/actions

## Common Issues & Fixes

### Issue: "claude-sandbox: command not found"

**Fix:** Use the launch script instead:

```bash
# Use the launch script (no installation needed)
cd ~/Github/your-project
~/Github/claude-code-sandbox/launch-claude-sandbox.sh
```

**Advanced:** If you want the `claude-sandbox` command globally available:

```bash
cd ~/Github/claude-code-sandbox
git pull origin main
npm install
npm run build
sudo npm link
```

### Issue: Docker not running

**Fix:**

```bash
sudo service docker start
```

### Issue: "Not a git repository"

**Fix:**

Make sure you're inside a git repo:

```bash
git status  # Check if you're in a git repo
cd ~/Github/claude-code-sandbox  # Navigate to a git repo
```

### Issue: Can't push to GitHub

**Fix:**

Re-authenticate GitHub CLI:

```bash
gh auth login

# Or check status:
gh auth status
```

### Issue: Want to update to latest Docker image

**Fix:**

```bash
docker pull ghcr.io/tdoerks/claude-code-sandbox:latest
```

The image updates nightly, but you can pull manually anytime!

## Quick Reference Commands

```bash
# Open Ubuntu
wsl -d Ubuntu-24.04

# Pull latest Docker image
docker pull ghcr.io/tdoerks/claude-code-sandbox:latest

# Navigate to project
cd ~/Github/your-project

# Launch sandbox
claude-sandbox

# Check GitHub auth
gh auth status

# Check Docker status
sudo service docker status

# Start Docker if stopped
sudo service docker start

# Exit sandbox
Ctrl+C in terminal

# Exit Ubuntu
exit
```

## Project Locations

Your projects are in:

```bash
~/Github/
```

Which maps to:

```
/home/username/Github/
```

Example projects:

- `claude-code-sandbox` - The sandbox tool itself
- `my-project` - Your project
- `another-project` - Another project

## Multiple Sandboxes at Once

Open multiple PowerShell/Terminal windows:

**Window 1:**

```bash
wsl -d Ubuntu-24.04
cd ~/Github/my-project
claude-sandbox
```

**Window 2:**

```bash
wsl -d Ubuntu-24.04
cd ~/Github/another-project
claude-sandbox
```

Each runs independently with separate browser tabs!

## Alternative: Personal Access Token (If GitHub CLI Fails)

If `gh auth login` doesn't work, use a token instead:

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Name: "Claude Sandbox"
4. Select scopes: ✅ `repo`, ✅ `workflow`
5. Generate and **copy the token** (starts with `ghp_...`)

Set the token:

```bash
export GITHUB_TOKEN='ghp_your_token_here'
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc
source ~/.bashrc
```

## Remember

✅ Must be inside a git repository
✅ Docker must be running
✅ Browser opens automatically
✅ GitHub credentials set up (Step 3)
✅ Run as your normal user (not root)
✅ Each project = separate sandbox
✅ **Pre-built images auto-update nightly** 🆕

## Setup Complete! 🎉

Quick launch (recommended):

```bash
cd ~/Github/your-project
~/Github/claude-code-sandbox/launch-claude-sandbox.sh
```

Browser opens → Start chatting with Claude → It codes for you → Push to GitHub! 🚀

The launch script auto-updates the Docker image every time you run it!

---

## What's New in This Fork

🆕 **Auto-Updated Docker Images**
- No more manual builds!
- Pull pre-built images: `ghcr.io/tdoerks/claude-code-sandbox:latest`
- Automatically rebuilds nightly with latest Claude Code
- Always stay current without maintenance

🆕 **Simplified Setup**
- Skip npm install/build if using pre-built images
- Faster initial setup
- Less disk space used

🆕 **Version Tracking**
- Images tagged with both `latest` and specific versions
- Pin to specific Claude Code versions if needed
- View all versions at: https://github.com/tdoerks/claude-code-sandbox/packages
