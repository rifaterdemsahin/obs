# 4_Formula — Re-Setup Implementation Steps

## Complete Guide: Restore OBS Studio from This Repository

This guide walks you through rebuilding your OBS Studio setup from scratch using the backed-up configuration in this repository.

---

## Pre-Flight Checklist

Before starting, confirm:
- [ ] You have this repository cloned on the target machine
- [ ] You have internet access to download OBS and plugins
- [ ] Chocolatey is installed (or use the manual install path)
- [ ] All physical hardware is connected (webcams, audio interfaces, capture cards)

---

## Phase 1 — Install OBS Studio

### Option A: Chocolatey (recommended — matches original install method)

```powershell
# Run PowerShell as Administrator
choco install obs-studio
```

> **Important:** Install the current **stable** release, not a Release Candidate.
> Check https://github.com/obsproject/obs-studio/releases for the latest stable version.

### Option B: Manual installer

Download the latest stable installer from https://obsproject.com and run it.
Default install path: `C:\Program Files\obs-studio\`

### Post-install: Run OBS once to initialize

1. Launch OBS Studio
2. Close the auto-configuration wizard (or run it — you'll overwrite settings anyway)
3. Close OBS

This creates the `%APPDATA%\obs-studio\` directory that the restore script needs.

---

## Phase 2 — Restore Configuration

### Step 2.1: Run the restore script

```powershell
cd <path-to-this-repo>

# Preview what will happen (no changes made)
.\restore-obs-config.ps1 -DryRun

# Run the restore (auto-detects old username from backup)
.\restore-obs-config.ps1

# If the backup was made on a machine with a different username, specify it
.\restore-obs-config.ps1 -OldUser "Pexabo"
```

This copies everything from `obs-config-backup/` into `%APPDATA%\obs-studio\` and remaps
any absolute paths containing the old username to your current Windows username.

### Step 2.2: Verify the restore

```powershell
# Check that scene collections are present
Get-ChildItem "$env:APPDATA\obs-studio\basic\scenes" -Filter "*.json"

# Check that profiles are present
Get-ChildItem "$env:APPDATA\obs-studio\basic\profiles" -Directory

# Validate scene JSON files
Get-ChildItem "$env:APPDATA\obs-studio\basic\scenes\*.json" | ForEach-Object {
    try {
        $null = Get-Content $_.FullName | ConvertFrom-Json
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($_.Name) — INVALID JSON" -ForegroundColor Red
    }
}
```

---

## Phase 3 — Install Required Plugins

All of these plugins are registered in `obs-config-backup/plugin_manager/modules.json` and
need to be installed separately — their binaries are not stored in this repo.

### Plugin Install Locations

| Plugin | Source | Install Method |
|--------|--------|----------------|
| obs-source-record | https://github.com/exeldro/obs-source-record | Release zip → extract to OBS |
| obs-color-monitor | https://github.com/nagadomi/obs-color-monitor | Release zip → extract to OBS |
| move-transition | https://github.com/exeldro/obs-move-transition | Release zip → extract to OBS |
| advanced-scene-switcher | https://github.com/WarmUpTill/SceneSwitcher | Release installer or zip |
| distroav | https://github.com/DistroAV/DistroAV | Release installer |
| Elgato StreamDeck for OBS | https://www.elgato.com/software-center | Elgato installer |

### Standard plugin install procedure (zip-based)

1. Download the latest release `.zip` for Windows
2. Extract to `C:\Program Files\obs-studio\`
   - DLLs go in: `obs-plugins\64bit\`
   - Data files go in: `data\obs-plugins\<plugin-name>\`
3. Restart OBS

### Advanced Scene Switcher — restore settings

The plugin settings backups are in `obs-config-backup/plugin_config/advanced-scene-switcher/`.
After installing, copy the appropriate settings file:

```powershell
# Example: restore NationalGrid scene switcher config
$src  = ".\obs-config-backup\plugin_config\advanced-scene-switcher\settings-backup-NationalGrid-1.30.1.json"
$dest = "$env:APPDATA\obs-studio\plugin_config\advanced-scene-switcher\settings.json"
Copy-Item $src $dest -Force
```

---

## Phase 4 — Load the Projector Hotkeys Script

```
1. Open OBS Studio
2. Tools → Scripts → click [+]
3. Navigate to: <repo>\5_Symbols\plugins\projector-hotkeys.lua
4. Click Open
5. In the Scripts panel, configure monitor assignments per output
6. In Settings → Hotkeys, assign keyboard shortcuts to each projector
```

> **Note:** If you add or rename scenes later, the script must be reloaded.

---

## Phase 5 — Hardware Configuration

### 5.1 Run OBS as Administrator (CRITICAL)

Without admin rights, the AMD GPU scheduler fails to set D3D11 thread priority, causing
encoding lag and QThread priority warnings every session.

```
C:\Program Files\obs-studio\bin\64bit\obs64.exe
  → Right-click → Properties → Compatibility tab
  → ☑ Run this program as an administrator
  → Apply
```

### 5.2 Disable Windows Game DVR

Game DVR competes with OBS for GPU encoding capacity.

```
Win + I → Gaming → Xbox Game Bar → toggle Off
Win + I → Gaming → Captures → "Record in background" → Off
```

### 5.3 Fix Audio Devices (Set Fixed Devices, Not "Default")

Using "Default" for audio causes 30+ device-switch events when other apps start.

```
OBS → Settings → Audio
  Desktop Audio   : [select your specific primary output — e.g. "Speakers (Realtek)"]
  Desktop Audio 2 : Disabled (unless needed)
  Mic/Aux         : [leave empty — configured per-scene]

OBS → Settings → Audio → Advanced
  Audio Monitoring Device: [select a specific device — e.g. "Headphones (USB)"]
```

### 5.4 Remove Dead Audio Source

Remove (or remap) the permanently missing "Audio Output Capture 2" source that causes
a WASAPI error on every session startup:

```
Right-click "Audio Output Capture 2" in any scene that has it → Remove
  — OR —
Right-click → Properties → Device: select a valid device
```

### 5.5 Distribute USB Cameras Across Controllers

The Facecam, Insta360, and BRIO compete for USB bandwidth when on the same controller.

```
Device Manager → View → Devices by connection
Identify which USB Root Hubs host each camera.
Move cameras to different physical USB ports on different controllers.
```

### 5.6 Fix Elgato Wave:3 Microphone USB Stability

Windows re-assigns device GUIDs when the Wave:3 is plugged into a different port.
Always use the **same physical USB port**.

Alternatively, use the **Elgato Wave Link** virtual audio device as the OBS source
(it has a stable ID that survives reboots):

```
Source → Properties → Device: "WAVE:3 (Wave Link Stream)" or similar
```

### 5.7 Update Insta360 Video Format

Change the Insta360 source from MJPEG to YUY2 to eliminate MJPEG decoder warnings:

```
Source → Insta360 → Properties → Video Format: YUY2 (or NV12)
```

### 5.8 Set ZV-1 Source FPS to Match Project (60fps)

```
Source → ZV-1 → Properties → FPS: 60.00 (if camera supports it) or 30.00
```

### 5.9 Upgrade Logitech BRIO Resolution

After resolving USB bandwidth (Step 5.5), raise the BRIO to 1080p:

```
Source → BRIO → Properties → Resolution: 1920x1080
```

---

## Phase 6 — First Launch Verification

Launch OBS and check each item:

```
[ ] OBS opens without "crash detected" warning
[ ] Scene collection "NationalGrid" loads (or whichever was last active)
[ ] All profiles are listed: Complex, Main, Untitled, only_cam, onlyhd
[ ] No "Failed to load module" errors for installed plugins
[ ] All cameras appear in sources (no "video configuration failed")
[ ] Audio meters show input from microphones and desktop audio
[ ] No WASAPI "element not found" errors for active sources
[ ] GPU thread priority warning is GONE (OBS running as admin)
[ ] WebSocket server is running (obs-websocket config restored)
[ ] Projector hotkeys script loaded and monitors configured
[ ] Test recording: start/stop a 10-second recording, check output file
[ ] Test stream: start/stop a 30-second stream to verify RTMP config
```

---

## Phase 7 — Post-Setup Maintenance

### Run the backup script after any configuration change

```powershell
.\backup-obs-config.ps1
git add -A
git commit -m "Update OBS config backup — <describe change>"
git push
```

### Keep OBS on the stable channel

```powershell
# Update via Chocolatey
choco upgrade obs-studio

# Or: OBS → Help → Check for Updates
# Ensure UpdateBranch=stable in obs-config-backup/global.ini
```

### Schedule regular backups (optional)

Use Windows Task Scheduler to run `backup-obs-config.ps1` automatically:

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
           -Argument "-NonInteractive -File `"$PSScriptRoot\backup-obs-config.ps1`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
Register-ScheduledTask -TaskName "OBS Config Backup" -Action $action -Trigger $trigger
```

---

## Quick Reference — Useful Git Commands

| Command | Purpose |
|---------|---------|
| `.\backup-obs-config.ps1` | Back up current OBS config |
| `.\restore-obs-config.ps1 -DryRun` | Preview restore without changes |
| `.\restore-obs-config.ps1 -OldUser "Pexabo"` | Restore with path remapping |
| `git diff obs-config-backup/` | See what changed since last backup |
| `git log --oneline obs-config-backup/` | View backup history |
| `git checkout <hash> -- obs-config-backup/` | Restore a specific historical version |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `D3D11 GPU thread priority` warning | Not running as admin | Phase 5.1 |
| Audio source "element not found" | Stale device GUID | Remove/remap dead source (5.4) |
| 7% skipped frames / encoding lag | Game DVR + no admin | Phase 5.1 + 5.2 |
| Grey projector on startup | OBS rendering race | projector-hotkeys "Open Again on Startup" option |
| Plugin sources missing / broken | Plugin not installed | Phase 3 |
| Image/video sources show wrong path | Absolute path mismatch | Re-run restore with `-OldUser` flag |
| 618ms audio buffering spike | GPU device reset | Update AMD GPU drivers |
| Wave:3 missing at startup | USB port changed | Fix to same port (5.6) |

See `6_Semblance/logs/REPORT.md` for a full analysis of known issues from recent sessions.
