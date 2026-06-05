# Claude Code Sandbox - WSL Setup Guide (Windows)

**Quick Start for Windows users with WSL (Windows Subsystem for Linux)**

This guide shows you how to run Claude Code Sandbox on Windows using WSL, which is easier and more reliable than native Windows PowerShell setup.

## Prerequisites

- Windows 10/11 with WSL 2 installed
- Docker Desktop for Windows (with WSL 2 integration enabled)

## Why WSL?

Running Claude Code Sandbox in WSL offers several advantages:
- ✅ Uses the bash launcher script (simpler than PowerShell)
- ✅ Better compatibility with Docker
- ✅ Faster performance
- ✅ Consistent with Linux/Mac experience
- ✅ No need to install Node.js/Git separately on Windows

---

## Step 1: Install WSL (if not already installed)

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This installs Ubuntu by default. Restart your computer when prompted.

### Install a specific distro (optional)

```powershell
# List available distributions
wsl --list --online

# Install Ubuntu 24.04
wsl --install -d Ubuntu-24.04
```

---

## Step 2: Install Docker Desktop

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Install and restart your computer
3. Open Docker Desktop
4. Go to **Settings → Resources → WSL Integration**
5. Enable integration with your WSL distro (e.g., Ubuntu-24.04)
6. Click "Apply & Restart"

---

## Step 3: Set Up Your WSL Environment

Open your WSL terminal:

```powershell
# From PowerShell or Command Prompt
wsl
```

Or open "Ubuntu" from the Start menu.

### Install Node.js (if needed)

Check if Node.js is installed:

```bash
node --version
```

If not installed or version is < 18:

```bash
# Install Node.js 20 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install Git (if needed)

```bash
git --version

# If not installed:
sudo apt-get update
sudo apt-get install git
```

### Verify Docker

```bash
docker --version
```

If Docker is not available, ensure Docker Desktop's WSL integration is enabled (see Step 2).

---

## Step 4: Clone and Build Claude Code Sandbox

```bash
# Clone the repository to your WSL home directory
cd ~
git clone https://github.com/tdoerks/claude-code-sandbox.git

# Navigate into the directory
cd claude-code-sandbox

# Install dependencies
npm install

# Build the project
npm run build
```

**Expected output:**
- `npm install` takes 1-2 minutes and installs ~600+ packages
- `npm run build` compiles TypeScript and takes ~30 seconds

---

## Step 5: Launch Claude Code Sandbox

### Option A: Quick Test (Recommended for first time)

```bash
# Create a test project
mkdir ~/test-project
cd ~/test-project
git init
echo "# Test Project" > README.md
git add .
git commit -m "Initial commit"

# Launch Claude Code Sandbox
cd ~/claude-code-sandbox
./launch-claude-sandbox.sh ~/test-project
```

### Option B: Use an Existing Project

```bash
# Clone your project to WSL (example: COMPASS-pipeline)
cd ~
git clone https://github.com/tdoerks/COMPASS-pipeline.git

# Launch Claude Code Sandbox with your project
cd ~/claude-code-sandbox
./launch-claude-sandbox.sh ~/COMPASS-pipeline
```

### Option C: Interactive Mode

```bash
cd ~/claude-code-sandbox
./launch-claude-sandbox.sh
```

The launcher will prompt you for:
1. **Project directory**: Path to your git repository
2. **Skills folder**: Press Enter to skip (optional Claude skills)
3. **Network access**: Type `1` for full internet or `2` for restricted

---

## Step 6: Access Claude Code

After launching:
- The script automatically opens your browser to **http://localhost:3456**
- If it doesn't open automatically, navigate there manually
- Claude Code will be running inside a Docker container with access to your project

To stop Claude Code:
- Press `Ctrl+C` in the WSL terminal

---

## Tips & Best Practice

### Working with Files

**WSL paths vs Windows paths:**
- WSL home: `~/project` → Linux file system (faster)
- Windows paths: `/mnt/c/Users/YourName/project` → Windows file system (slower)

**Recommendation:** Clone repositories to WSL home directory (`~`) for better performance.

### Accessing Files from Windows

Your WSL files are accessible from Windows Explorer:
```
\\wsl$\Ubuntu-24.04\home\tdoerks\
```

Or in File Explorer address bar, type: `\\wsl$`

### Git Configuration

Set up your Git identity in WSL (if not already done):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### SSH Keys

If you need GitHub SSH access, generate keys in WSL:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key to add to GitHub
cat ~/.ssh/id_ed25519.pub
```

---

## Troubleshooting

### "Docker is not running"

**Solution:** Start Docker Desktop from Windows Start menu, wait for it to fully start (whale icon in system tray), then try again.

### "Cannot connect to Docker daemon"

**Solution:** Ensure WSL integration is enabled in Docker Desktop settings:
1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable for your distro
4. Apply & Restart

### "node: command not found"

**Solution:** Install Node.js (see Step 3).

### "Permission denied" when running scripts

**Solution:** Make script executable:
```bash
chmod +x launch-claude-sandbox.sh
```

### Container fails to start

**Solution:** Check Docker Desktop logs:
1. Open Docker Desktop
2. Click the bug icon (bottom left)
3. Check for error messages

Or check container status:
```bash
docker ps -a
docker logs <container-id>
```

### First launch is slow

**Normal!** The first launch downloads the Docker image (~500MB), which takes several minutes. Subsequent launches are much faster.

### Browser doesn't open automatically

**Manual fix:** Open your Windows browser and go to:
```
http://localhost:3456
```

---

## Updating Claude Code Sandbox

To update to the latest version:

```bash
cd ~/claude-code-sandbox
git pull
npm install
npm run build
```

The launcher script automatically pulls the latest Docker image on each launch.

---

## Comparison: WSL vs Native Windows

| Feature | WSL (Recommended) | Native Windows (PowerShell) |
|---------|-------------------|------------------------------|
| Setup complexity | ✅ Simple | ⚠️ More complex |
| Performance | ✅ Fast | ⚠️ Slower |
| Script | Bash | PowerShell |
| Docker | Docker Desktop | Docker Desktop |
| File access | Linux + Windows | Windows only |
| Compatibility | ✅ Excellent | ⚠️ Good |

---

## Next Steps

Once Claude Code is running:
1. Explore the interface
2. Try asking Claude to analyze your code
3. Make changes and commit with Git
4. Experiment with different projects

For more information:
- [Main README](../README.md)
- [Environment Variables](./environment-variables.md)
- [GitHub Authentication](./github-authentication.md)
- [Setup Commands](./setup-commands.md)

---

## Quick Reference

### Essential Commands

```bash
# Launch Claude Code Sandbox
cd ~/claude-code-sandbox
./launch-claude-sandbox.sh /path/to/your/project

# Stop Claude Code
Ctrl+C

# Update Claude Code Sandbox
cd ~/claude-code-sandbox
git pull && npm install && npm run build

# Check Docker status
docker ps

# View container logs
docker logs <container-name>

# Access WSL from PowerShell
wsl

# Exit WSL
exit
```

### Useful Aliases (Optional)

Add to your `~/.bashrc`:

```bash
# Quick launch alias
alias claude-sandbox='cd ~/claude-code-sandbox && ./launch-claude-sandbox.sh'

# Reload bash config
source ~/.bashrc
```

Then you can simply run:
```bash
claude-sandbox ~/my-project
```

---

**Happy coding with Claude! 🤖**
