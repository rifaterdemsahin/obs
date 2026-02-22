# 7_Testing_Known — Validation & Proof

## Reaching Back to 1_Real_Unknown

This section validates whether the project solves the original unknowns defined in [`1_Real_Unknown`](../1_Real_Unknown/README.md).

---

## Test Matrix

### Objective 1: Make OBS configuration fully version-controlled

| # | Acceptance Criteria | Status | Evidence |
|---|---------------------|--------|----------|
| 1.1 | All scene collections are committed to Git | ✅ Pass | `obs-config-backup/basic/scenes/` contains 10 scene JSON files |
| 1.2 | All profiles are committed to Git | ✅ Pass | `obs-config-backup/basic/profiles/` contains 5 profiles |
| 1.3 | Plugin settings are committed to Git | ✅ Pass | `obs-config-backup/plugin_config/` includes websocket, browser, rtmp-services configs |
| 1.4 | A single command backs up the current state | ✅ Pass | `.\backup-obs-config.ps1` copies 391 files |
| 1.5 | Changes are trackable via `git diff` | ✅ Pass | Run backup twice, modify a scene, re-backup — diff shows changes |

### Objective 2: Enable reproducible OBS environments

| # | Acceptance Criteria | Status | Evidence |
|---|---------------------|--------|----------|
| 2.1 | Scene JSON files can be copied to a new `%APPDATA%` | ⬜ Untested | Needs validation on second machine |
| 2.2 | Profile settings survive copy/paste restore | ⬜ Untested | Needs validation |
| 2.3 | Plugin configs (websocket, hotkeys) restore correctly | ⬜ Untested | Needs validation |
| 2.4 | Absolute paths are remapped during restore | ✅ Built | `restore-obs-config.ps1` remaps `C:\Users\<OldUser>` to current user |

### Objective 3: Automate OBS setup management

| # | Acceptance Criteria | Status | Evidence |
|---|---------------------|--------|----------|
| 3.1 | Backup runs with single command | ✅ Pass | `.\backup-obs-config.ps1` |
| 3.2 | Locked files are handled gracefully | ✅ Pass | `try/catch` skips locked files with warning |
| 3.3 | Caches/logs/temp files are excluded | ✅ Pass | 730 files skipped, 391 copied |
| 3.4 | Custom plugins are version-controlled | ✅ Pass | `5_Symbols/plugins/projector-hotkeys.lua` committed |
| 3.5 | Restore script pushes config back | ✅ Built | `.\restore-obs-config.ps1` |

---

## Re-Setup Validation Test Procedures

Use these tests after running `restore-obs-config.ps1` to confirm the restore was successful.

### Test 5: Restore Script Dry Run

```powershell
# Should list files without making changes
.\restore-obs-config.ps1 -DryRun
# Expected: lists all files that would be copied, exits with no errors
```

### Test 6: Restore with Path Remapping

```powershell
.\restore-obs-config.ps1 -OldUser "Pexabo"
# Expected: "Remapped: NationalGrid.json" (or similar) for scene files with absolute paths
# Expected: "Restore complete! Files copied: <N>"
```

### Test 7: Verify Restored Config

```powershell
# All scene collections present
Get-ChildItem "$env:APPDATA\obs-studio\basic\scenes" -Filter "*.json" | Select Name

# All profiles present
Get-ChildItem "$env:APPDATA\obs-studio\basic\profiles" -Directory | Select Name

# All scene JSON valid
Get-ChildItem "$env:APPDATA\obs-studio\basic\scenes\*.json" | ForEach-Object {
    try   { $null = Get-Content $_.FullName | ConvertFrom-Json; Write-Host "✓ $($_.Name)" -FG Green }
    catch { Write-Host "✗ $($_.Name) - Invalid JSON" -FG Red }
}
```

### Test 8: OBS Launch After Restore

```
1. Launch OBS as Administrator
2. Expected: No "crash detected" warning
3. Expected: NationalGrid scene collection is active
4. Expected: No "Failed to load module" errors for installed plugins
5. Expected: No D3D11 GPU thread priority warning (if running as admin)
```

---

## Manual Test Procedures

### Test 1: Fresh Backup
```powershell
# 1. Close OBS Studio
# 2. Run backup
.\backup-obs-config.ps1

# Expected: "Backup complete!" with file counts
# Expected: obs-config-backup/ contains basic/, plugin_config/, plugin_manager/
```

### Test 2: Verify Scene Integrity
```powershell
# Check that scene JSON files are valid
Get-ChildItem obs-config-backup\basic\scenes\*.json | ForEach-Object {
    try {
        $null = Get-Content $_.FullName | ConvertFrom-Json
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($_.Name) - Invalid JSON" -ForegroundColor Red
    }
}
```

### Test 3: Git Change Tracking
```powershell
# 1. Make a change in OBS (e.g., add a source to a scene)
# 2. Run backup again
.\backup-obs-config.ps1
# 3. Check what changed
git diff obs-config-backup/

# Expected: Only the modified scene file shows changes
```

### Test 4: Projector Hotkeys Plugin
```
1. Load plugins/projector-hotkeys.lua in OBS → Tools → Scripts
2. Set monitor for "Program Output" to monitor 2
3. Set a hotkey in Settings → Hotkeys → "Open Fullscreen Projector for 'Program Output'"
4. Press the hotkey
   Expected: Fullscreen projector opens on monitor 2
5. Enable "Open on Startup", restart OBS
   Expected: Projector opens automatically
```

---

## Summary

| Area | Tested | Passing | Blocked |
|------|--------|---------|---------|
| Backup automation | 5 | 5 | 0 |
| Reproducibility | 4 | 1 | 3 (needs second machine) |
| Plugin management | 1 | 1 | 0 |
| Re-setup procedures | 4 | — | — (run after restore) |
| **Total** | **14** | **7** | **3** |

**Conclusion:** Core IaC backup pipeline is working. Restore script is now implemented with path remapping. Cross-machine portability still needs second-machine validation — tracked in the roadmap in [`2_Environment`](../2_Environment/README.md).
