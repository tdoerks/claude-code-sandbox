# Claude Sandbox Launcher with Auto-Update (Windows / PowerShell)
#
# Native Windows launcher for Docker Desktop. Mirrors the bash launchers:
#   - prompts for the project directory
#   - optionally injects Claude skills (.zip) into the container
#   - optionally restricts the container's network to an allowlist
#   - pulls + re-tags the latest image, then launches claude-sandbox
#
# Requirements:
#   - Docker Desktop installed
#   - `claude-sandbox` installed on the Windows host (npm i -g, or use the repo)
#
# Usage:
#   pwsh ./launch-claude-sandbox.ps1 [project-directory] [-- extra claude-sandbox args]

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "Claude Sandbox Launcher (Windows)"
Write-Host "============================================================"
Write-Host ""

# --- Directory selection ----------------------------------------------------
$TargetDir = ""
if ($args.Count -ge 1 -and (Test-Path -PathType Container $args[0])) {
    $TargetDir = $args[0]
    $args = $args[1..($args.Count - 1)]
} else {
    $current = (Get-Location).Path
    $input = Read-Host "Project directory to launch from [$current]"
    if ([string]::IsNullOrWhiteSpace($input)) { $TargetDir = $current } else { $TargetDir = $input }
}
if (-not (Test-Path -PathType Container $TargetDir)) {
    Write-Host "ERROR: Directory does not exist: $TargetDir" -ForegroundColor Red
    exit 1
}
Set-Location $TargetDir
Write-Host "   Using: $((Get-Location).Path)"
Write-Host ""

# --- Git check --------------------------------------------------------------
git rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not a git repository. Choose a directory that is a git repo." -ForegroundColor Red
    exit 1
}
$ProjectName = Split-Path -Leaf (git rev-parse --show-toplevel)
$Branch = (git branch --show-current)
Write-Host "Project: $ProjectName"
Write-Host "Branch:  $Branch"
Write-Host ""

# --- Ensure Docker is running -----------------------------------------------
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Attempting to start Docker Desktop..."
    $dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerExe) { Start-Process $dockerExe }
    Write-Host "   Waiting for Docker to start..."
    $elapsed = 0
    while ($true) {
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds 2
        $elapsed += 2
        if ($elapsed -ge 60) {
            Write-Host "ERROR: Docker did not start within 60s. Aborting." -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Docker is running."
}

# --- Pull + re-tag image ----------------------------------------------------
$Image = "ghcr.io/tdoerks/claude-code-sandbox:latest"
Write-Host ""
Write-Host "Checking for Docker image updates..."
Write-Host "   Image: $Image"
docker pull $Image
if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker image up to date!"
    # Re-tag so claude-sandbox finds it under its expected local name
    docker tag $Image claude-code-sandbox:latest
} else {
    Write-Host "Failed to pull latest image, using cached version" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Claude Code version in Docker image:"
docker run --rm $Image claude --version 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "   (version check skipped)" }
Write-Host ""

# --- Skills (optional) ------------------------------------------------------
$ExtraArgs = @()
$SkillsDir = Read-Host "Path to a folder of skill .zip files (blank to skip)"
if (-not [string]::IsNullOrWhiteSpace($SkillsDir)) {
    if (Test-Path -PathType Container $SkillsDir) {
        $ExtraArgs += @("--skills", $SkillsDir)
        Write-Host "   Skills will be injected from: $SkillsDir"
    } else {
        Write-Host "   Skills path not found, skipping: $SkillsDir" -ForegroundColor Yellow
    }
}
Write-Host ""

# --- Network restriction (optional) -----------------------------------------
Write-Host "Network access:"
Write-Host "   1) Full internet (default)"
Write-Host "   2) Allowlist only (Anthropic API + GitHub) - sandboxed"
$NetChoice = Read-Host "   Choose [1/2]"
if ($NetChoice -eq "2") {
    $ExtraArgs += @("--network", "allowlist")
    Write-Host "   Network: allowlist (Anthropic + GitHub only)"
} else {
    Write-Host "   Network: full internet"
}
Write-Host ""

Write-Host "============================================================"
Write-Host "Launching Claude Sandbox..."
Write-Host "============================================================"
Write-Host ""
Write-Host "   Browser will open automatically at http://localhost:3456"
Write-Host "   Press Ctrl+C to exit"
Write-Host ""

# Launch claude-sandbox with chosen options plus any passthrough args
claude-sandbox @ExtraArgs @args
