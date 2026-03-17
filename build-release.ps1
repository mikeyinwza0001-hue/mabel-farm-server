# ═══════════════════════════════════════════════════════
# Mabel MC Server — Release Packaging Script
# ═══════════════════════════════════════════════════════
# Usage: .\build-release.ps1
# Creates a clean zip for distribution (no sensitive data)

param(
    [string]$OutputDir = ".\release"
)

$ErrorActionPreference = "Stop"

# Read version
$versionFile = Get-Content ".\server-version.json" | ConvertFrom-Json
$version = $versionFile.version
$zipName = "mabel-server-v$version.zip"

Write-Host "=== Building release v$version ===" -ForegroundColor Cyan

# Clean output dir
if (Test-Path $OutputDir) { Remove-Item $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$tempDir = "$OutputDir\mabel-server"
New-Item -ItemType Directory -Path $tempDir | Out-Null

# ─── Files/Folders to EXCLUDE from release ────────────
$excludeFiles = @(
    "ops.json",
    "whitelist.json",
    "banned-players.json",
    "banned-ips.json",
    "usercache.json",
    "server.properties",
    ".console_history",
    "bug_farm.txt",
    "build-release.ps1",
    ".gitignore",
    ".gitattributes"
)

$excludeDirs = @(
    ".git",
    ".vscode",
    "mabel-ricefarm",
    "backup",
    "logs",
    "cache",
    "versions",
    "libraries",
    "release",
    "plugins\.paper-remapped",
    "plugins\bStats",
    "plugins\spark"
)

# ─── Copy everything first ────────────────────────────
Write-Host "Copying server files..." -ForegroundColor Yellow

# Copy files (excluding dirs first)
$allItems = Get-ChildItem -Path "." -Force
foreach ($item in $allItems) {
    $name = $item.Name
    $skip = $false

    # Skip excluded files
    if ($excludeFiles -contains $name) { $skip = $true }

    # Skip excluded directories
    foreach ($dir in $excludeDirs) {
        if ($name -eq $dir -or $name -eq $dir.Split("\")[-1]) { $skip = $true; break }
    }

    if (-not $skip) {
        if ($item.PSIsContainer) {
            Copy-Item -Path $item.FullName -Destination "$tempDir\$name" -Recurse -Force
        } else {
            Copy-Item -Path $item.FullName -Destination "$tempDir\$name" -Force
        }
    }
}

# ─── Remove sensitive plugin files ────────────────────
$sensitivePluginFiles = @(
    "$tempDir\plugins\ServerTap\config.yml",
    "$tempDir\plugins\mabel-riceFarm\machine-id"
)
foreach ($f in $sensitivePluginFiles) {
    if (Test-Path $f) { Remove-Item $f -Force }
}

# ─── Copy template as server.properties ───────────────
if (Test-Path ".\server.properties.template") {
    Copy-Item ".\server.properties.template" "$tempDir\server.properties" -Force
}

# ─── Create empty required files ──────────────────────
"[]" | Set-Content "$tempDir\ops.json"
"[]" | Set-Content "$tempDir\whitelist.json"
"[]" | Set-Content "$tempDir\banned-players.json"
"[]" | Set-Content "$tempDir\banned-ips.json"

# ─── Create zip ───────────────────────────────────────
Write-Host "Creating $zipName..." -ForegroundColor Yellow
$zipPath = "$OutputDir\$zipName"
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

# Cleanup temp
Remove-Item $tempDir -Recurse -Force

$size = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
Write-Host ""
Write-Host "=== Release built! ===" -ForegroundColor Green
Write-Host "  File: $zipPath" -ForegroundColor White
Write-Host "  Size: ${size} MB" -ForegroundColor White
Write-Host "  Version: $version" -ForegroundColor White
Write-Host ""
Write-Host "Next: Upload $zipName to GitHub Releases" -ForegroundColor Cyan
