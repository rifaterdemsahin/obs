<#
.SYNOPSIS
    Backs up OBS Studio configuration to the obs-config-backup folder.

.DESCRIPTION
    Copies important OBS Studio configuration files (scenes, profiles, settings,
    plugin configs) from %APPDATA%\obs-studio into a local backup folder.
    Skips caches, logs, crash dumps, and other non-essential data.

.EXAMPLE
    .\backup-obs-config.ps1
    .\backup-obs-config.ps1 -BackupDir "C:\my-backups\obs"
#>

param(
    [string]$BackupDir = (Join-Path $PSScriptRoot "obs-config-backup")
)

$obsConfigDir = Join-Path $env:APPDATA "obs-studio"

if (-not (Test-Path $obsConfigDir)) {
    Write-Error "OBS Studio config directory not found at: $obsConfigDir"
    exit 1
}

# Folders/files to skip (caches, logs, crash data, temp files)
$excludeDirs = @(
    "crashes",
    "logs",
    "profiler_data",
    "updates",
    ".sentinel"
)

$excludeFilePatterns = @(
    "*.log",
    "*.bak",
    "*.tmp"
)

# Cache subfolders to skip inside plugin_config
$excludeCachePatterns = @(
    "*\Cache\*",
    "*\GPUCache\*",
    "*\blob_storage\*",
    "*\Session Storage\*",
    "*\Local Storage\*",
    "*\Code Cache\*"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OBS Studio Configuration Backup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source : $obsConfigDir"
Write-Host "Destination: $BackupDir"
Write-Host ""

# Create backup directory
if (Test-Path $BackupDir) {
    Write-Host "Removing previous backup..." -ForegroundColor Yellow
    Remove-Item $BackupDir -Recurse -Force
}
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Get all files from OBS config
$allFiles = Get-ChildItem $obsConfigDir -Recurse -File

$copiedCount = 0
$skippedCount = 0

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Substring($obsConfigDir.Length + 1)
    $topFolder = $relativePath.Split('\')[0]

    # Skip excluded top-level directories
    if ($topFolder -in $excludeDirs) {
        $skippedCount++
        continue
    }

    # Skip excluded file patterns
    $skipFile = $false
    foreach ($pattern in $excludeFilePatterns) {
        if ($file.Name -like $pattern) {
            $skipFile = $true
            break
        }
    }
    if ($skipFile) {
        $skippedCount++
        continue
    }

    # Skip cache folders inside plugin_config
    $skipCache = $false
    foreach ($pattern in $excludeCachePatterns) {
        if ($relativePath -like $pattern) {
            $skipCache = $true
            break
        }
    }
    if ($skipCache) {
        $skippedCount++
        continue
    }

    # Copy the file
    $destPath = Join-Path $BackupDir $relativePath
    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    try {
        Copy-Item $file.FullName -Destination $destPath -Force -ErrorAction Stop
        $copiedCount++
    } catch {
        Write-Host "  Skipped (locked): $relativePath" -ForegroundColor DarkYellow
        $skippedCount++
    }
}

Write-Host ""
Write-Host "Backup complete!" -ForegroundColor Green
Write-Host "  Files copied : $copiedCount" -ForegroundColor Green
Write-Host "  Files skipped: $skippedCount (caches, logs, etc.)" -ForegroundColor DarkGray
Write-Host ""

# Show what was backed up
Write-Host "Backed up directories:" -ForegroundColor Cyan
Get-ChildItem $BackupDir -Directory | ForEach-Object {
    $count = (Get-ChildItem $_.FullName -Recurse -File).Count
    Write-Host "  $($_.Name)/ ($count files)"
}

# Also list root-level files
$rootFiles = Get-ChildItem $BackupDir -File
if ($rootFiles) {
    Write-Host "  (root) ($($rootFiles.Count) files)"
}
