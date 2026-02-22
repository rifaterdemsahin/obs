<#
.SYNOPSIS
    Restores OBS Studio configuration from the obs-config-backup folder.

.DESCRIPTION
    Copies OBS Studio configuration files (scenes, profiles, settings, plugin configs)
    from the obs-config-backup folder into %APPDATA%\obs-studio.
    Optionally remaps absolute Windows paths (e.g. old username) to the current machine.

.PARAMETER BackupDir
    Path to the backup folder. Defaults to obs-config-backup/ beside this script.

.PARAMETER OldUser
    The Windows username stored in the backup (e.g. "Pexabo"). If provided, all
    occurrences of C:\Users\<OldUser> in scene JSON files are replaced with the
    current user's home path. Auto-detected from global.ini if not provided.

.PARAMETER DryRun
    If set, shows what would be copied/changed without making any changes.

.PARAMETER Force
    If set, skips the confirmation prompt before overwriting the OBS config directory.

.EXAMPLE
    .\restore-obs-config.ps1
    .\restore-obs-config.ps1 -OldUser "Pexabo"
    .\restore-obs-config.ps1 -DryRun
    .\restore-obs-config.ps1 -BackupDir "C:\my-backups\obs" -OldUser "Pexabo" -Force
#>

param(
    [string]$BackupDir = (Join-Path (if ($PSScriptRoot) { $PSScriptRoot } else { $PWD }) "obs-config-backup"),
    [string]$OldUser   = "",
    [switch]$DryRun,
    [switch]$Force
)

$obsConfigDir = Join-Path $env:APPDATA "obs-studio"
$currentUser  = $env:USERNAME

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OBS Studio Configuration Restore" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Validate backup directory ---
if (-not (Test-Path $BackupDir)) {
    Write-Error "Backup directory not found: $BackupDir"
    exit 1
}

Write-Host "Source      : $BackupDir"
Write-Host "Destination : $obsConfigDir"
if ($DryRun) {
    Write-Host "Mode        : DRY RUN (no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

# --- Auto-detect old username from global.ini if not provided ---
if ($OldUser -eq "") {
    $globalIni = Join-Path $BackupDir "global.ini"
    if (Test-Path $globalIni) {
        $iniContent = Get-Content $globalIni -Raw
        if ($iniContent -match 'Configuration=C:\\\\Users\\\\([^\\]+)\\\\') {
            $OldUser = $Matches[1]
            Write-Host "Auto-detected backup username: $OldUser" -ForegroundColor DarkGray
        }
    }
}

if ($OldUser -ne "" -and $OldUser -ne $currentUser) {
    Write-Host "Path remapping: C:\Users\$OldUser -> C:\Users\$currentUser" -ForegroundColor Cyan
} elseif ($OldUser -eq $currentUser) {
    Write-Host "Backup username matches current user — no path remapping needed." -ForegroundColor DarkGray
    $OldUser = ""
}
Write-Host ""

# --- Warn if OBS is running ---
$obsProcess = Get-Process -Name "obs64" -ErrorAction SilentlyContinue
if ($obsProcess) {
    Write-Host "WARNING: OBS Studio is currently running." -ForegroundColor Yellow
    Write-Host "         Close OBS before restoring to avoid conflicts." -ForegroundColor Yellow
    if (-not $Force -and -not $DryRun) {
        $answer = Read-Host "Continue anyway? [y/N]"
        if ($answer -notmatch '^[yY]$') {
            Write-Host "Restore cancelled." -ForegroundColor Red
            exit 0
        }
    }
    Write-Host ""
}

# --- Confirm before overwriting ---
if (-not $DryRun -and -not $Force) {
    if (Test-Path $obsConfigDir) {
        Write-Host "WARNING: This will overwrite files in:" -ForegroundColor Yellow
        Write-Host "         $obsConfigDir" -ForegroundColor Yellow
        $answer = Read-Host "Continue? [y/N]"
        if ($answer -notmatch '^[yY]$') {
            Write-Host "Restore cancelled." -ForegroundColor Red
            exit 0
        }
        Write-Host ""
    }
}

# --- Remap absolute paths in scene JSON files ---
if ($OldUser -ne "") {
    Write-Host "Remapping paths in scene JSON files..." -ForegroundColor Cyan
    $sceneDir = Join-Path $BackupDir "basic\scenes"
    if (Test-Path $sceneDir) {
        $sceneFiles = Get-ChildItem $sceneDir -Filter "*.json"
        foreach ($sceneFile in $sceneFiles) {
            $content    = Get-Content $sceneFile.FullName -Raw -Encoding UTF8
            # Four backslashes in the regex match the double-escaped backslashes
            # that OBS writes in JSON: "C:\\Users\\Pexabo" is stored as C:\\\\Users\\\\Pexabo
            $oldPath    = "C:\\\\Users\\\\$([regex]::Escape($OldUser))"
            $newPath    = "C:\\\\Users\\\\$currentUser"
            $newContent = $content -replace $oldPath, $newPath

            # Also handle single-backslash variants
            $oldPathSingle = "C:\\Users\\$([regex]::Escape($OldUser))"
            $newPathSingle = "C:\\Users\\$currentUser"
            $newContent    = $newContent -replace [regex]::Escape($oldPathSingle), $newPathSingle

            if ($content -ne $newContent) {
                Write-Host "  Remapped: $($sceneFile.Name)" -ForegroundColor Green
                if (-not $DryRun) {
                    Set-Content $sceneFile.FullName $newContent -Encoding UTF8
                }
            }
        }
    }
    Write-Host ""
}

# --- Copy backup files to OBS config directory ---
Write-Host "Copying configuration files..." -ForegroundColor Cyan

$allFiles    = Get-ChildItem $BackupDir -Recurse -File
$copiedCount = 0
$skippedCount = 0

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Substring($BackupDir.Length + 1)
    $destPath     = Join-Path $obsConfigDir $relativePath
    $destDir      = Split-Path $destPath -Parent

    if ($DryRun) {
        Write-Host "  [DryRun] Would copy: $relativePath" -ForegroundColor DarkGray
        $copiedCount++
        continue
    }

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    try {
        Copy-Item $file.FullName -Destination $destPath -Force -ErrorAction Stop
        $copiedCount++
    } catch {
        Write-Host "  Skipped (locked or error): $relativePath" -ForegroundColor DarkYellow
        $skippedCount++
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete — no files were changed." -ForegroundColor Yellow
    Write-Host "  Files that would be copied: $copiedCount"
} else {
    Write-Host "Restore complete!" -ForegroundColor Green
    Write-Host "  Files copied  : $copiedCount" -ForegroundColor Green
    if ($skippedCount -gt 0) {
        Write-Host "  Files skipped : $skippedCount (locked or error)" -ForegroundColor DarkYellow
    }
}
Write-Host ""

# --- Post-restore checklist ---
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Post-Restore Checklist" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Install required plugins (see 4_Formula/RESETUP-STEPS.md):"
Write-Host "       - distroav"
Write-Host "       - obs-source-record  (https://github.com/exeldro/obs-source-record)"
Write-Host "       - obs-color-monitor  (https://github.com/nagadomi/obs-color-monitor)"
Write-Host "       - move-transition    (https://github.com/exeldro/obs-move-transition)"
Write-Host "       - advanced-scene-switcher (https://github.com/WarmUpTill/SceneSwitcher)"
Write-Host "       - Elgato StreamDeck for OBS (via Elgato website)"
Write-Host ""
Write-Host "  2. Load the projector hotkeys script:"
Write-Host "       OBS > Tools > Scripts > + > 5_Symbols\plugins\projector-hotkeys.lua"
Write-Host ""
Write-Host "  3. Run OBS as Administrator:"
Write-Host "       obs64.exe > Right-click > Properties > Compatibility"
Write-Host "       > Check 'Run this program as an administrator'"
Write-Host ""
Write-Host "  4. Fix audio devices:"
Write-Host "       Settings > Audio > Desktop Audio: set to a fixed device (not Default)"
Write-Host "       Settings > Audio > Advanced > Monitoring Device: set to a fixed device"
Write-Host ""
Write-Host "  5. Start OBS — your scenes, profiles and plugin settings should be restored."
Write-Host ""
Write-Host "See 4_Formula/RESETUP-STEPS.md for the complete step-by-step guide." -ForegroundColor Cyan
