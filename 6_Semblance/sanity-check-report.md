# Sanity Check Report — OBS Infrastructure-as-Code Project

**Date:** 2026-02-22  
**Scope:** Full project review — structure, scripts, plugins, configuration, documentation  
**Repo:** https://github.com/rifaterdemsahin/obs

---

## Summary

This project treats OBS Studio configuration as Infrastructure-as-Code (IaC) by version-controlling scene collections, profiles, plugin settings, and custom Lua scripts. The core backup pipeline is functional. Several important gaps remain around restore automation, cross-machine portability, and repository hygiene.

---

## ✅ Pros — What Is Working Well

### 1. Clear Knowledge System Structure
The numbered folder hierarchy (`1_Real_Unknown` → `7_Testing_Known`) provides a logical, self-documenting journey from problem definition to validation. Each folder has a `README.md` with purpose-specific content.

### 2. Functional Backup Script (`backup-obs-config.ps1`)
- Single-command backup: `.\backup-obs-config.ps1`
- Gracefully skips locked files (browser cookies/databases) with `try/catch`
- Properly excludes caches, logs, crash dumps, and temp files
- Accepts a `-BackupDir` parameter for custom destinations
- Gives clear console output with file counts

### 3. Projector Hotkeys Lua Plugin
- Configurable per-scene and per-monitor hotkey bindings
- Supports auto-open on OBS startup
- Includes a workaround for the grey-screen rendering race condition (`double_startup`)
- Well-structured and readable Lua code

### 4. Meaningful Scene Collections Committed
Ten scene JSON files are committed covering diverse use cases (interviews, course recording, presentations, screen capture, multi-device). Five streaming/recording profiles are also versioned.

### 5. Good `.gitignore` Coverage
Video file formats (`*.mp4`, `*.mkv`, `*.avi`, etc.), OS files (`Thumbs.db`, `.DS_Store`), and IDE folders are all excluded from version control.

### 6. Per-Folder Documentation
Every folder has a `README.md` with context-specific content: OKRs in `1_Real_Unknown`, landscape in `2_Environment`, workflow diagrams in `3_Simulation`, how-to steps in `4_Formula`, code symbols in `5_Symbols`, and a test matrix in `7_Testing_Known`.

### 7. Polished Project Web Page (`index.html`)
The GitHub Pages site (`index.html`) presents the project cleanly with a dark theme, structured sections, and clear usage instructions.

### 8. Established Roadmap
`2_Environment/README.md` has an explicit roadmap with completed and pending items, making progress trackable.

---

## ❌ Cons — What Is Missing or Broken

### 1. No Restore Script (Critical Gap)
The backup half of IaC is complete, but there is no `restore-obs-config.ps1`. A user cannot reproduce their OBS environment on a new machine using this repo alone. This is the most important missing piece.

**Roadmap status:** Listed as `[ ]` since project inception.

---

### 2. Absolute Paths in Scene JSON Break Cross-Machine Restore
Scene collections contain Windows absolute paths such as:
```json
"file": "C:\\Users\\Pexabo\\Images\\overlay.png"
```
Restoring on a different machine or under a different username will silently break image, video, and other file-backed sources. There is no path-remapping logic.

**Impact:** High — affects all scene collections with local file sources.

---

### 3. Large Binary Files Not Excluded from Backup
The `obs-localvocal` plugin stores Whisper AI model files (hundreds of MB, `.bin` extension) in `plugin_config/`. These are not excluded by the current backup script and not excluded by `.gitignore`, meaning they could accidentally be committed.

**Suggested fix (backup script):**
```powershell
$excludeCachePatterns += @("*\models\*.bin", "*\models\*.gguf")
```

**Suggested fix (`.gitignore`):**
```gitignore
# Large AI model files
*.bin
*.gguf
```

---

### 4. `.json.v1` Manual Versioning Files in Repo
Three scene files have a `.json.v1` suffix (`allsources.json.v1`, `just_rec.json.v1`, `firstprinciples.json.v1`), indicating manual backup copies were created instead of using Git history. These clutter the scene directory and undermine the purpose of Git versioning.

**Suggested fix:** Remove the `.v1` files and rely on `git log` / `git checkout <hash>` for historical versions.

---

### 5. Windows-Only Tooling (No Cross-Platform Support)
The backup script uses `%APPDATA%`, PowerShell, and Windows-specific path separators (`\`). Mac and Linux OBS users (~30–40% of OBS users) cannot use this repo as-is.

**Suggested fix:** Add a `backup-obs-config.sh` (Bash) for macOS/Linux that targets `~/Library/Application Support/obs-studio` (Mac) or `~/.config/obs-studio` (Linux).

---

### 6. No GitHub Actions CI
There is no automated validation of scene JSON files or the PowerShell script on push. Invalid JSON in a scene collection would only be discovered at restore time.

**Roadmap status:** Listed as `[ ]` since project inception.

**Suggested workflow:**
```yaml
# .github/workflows/validate.yml
- name: Validate Scene JSON
  run: |
    for f in obs-config-backup/basic/scenes/*.json; do
      python3 -m json.tool "$f" > /dev/null && echo "✓ $f" || echo "✗ $f INVALID"
    done
```

---

### 7. `locked.txt` Content Is Unrelated to This Project
`6_Semblance/locked.txt` contains documentation about a VS Code file-rename hang — unrelated to OBS IaC. This is likely leftover from an AI assistant session.

**Suggested fix:** Replace or remove the file; if the VS Code behaviour is worth noting, it should be in a clearly labelled context note.

---

### 8. Backup Script Does a Full Wipe on Every Run
Every backup deletes the entire `obs-config-backup/` folder before re-copying:
```powershell
Remove-Item $BackupDir -Recurse -Force
```
This means `git diff` after a backup shows all files as deleted and re-added, making it hard to see actual meaningful changes. It also means Git history is less useful.

**Suggested fix:** Use `robocopy` with `/MIR` or `Copy-Item` without the initial `Remove-Item`, and add `git diff --stat` at the end of the script.

---

### 9. Grey-Screen Double-Open Is a Workaround, Not a Fix
The `double_startup` feature opens a duplicate projector to work around a rendering race condition in OBS's Lua script load order. The original blank projector remains visible behind the duplicate.

**Impact:** Low on functionality, but adds visual noise and the original grey window persists.

**Suggested investigation:** Use `obs_frontend_add_event_callback` for `OBS_FRONTEND_EVENT_FINISHED_LOADING` to delay projector open until OBS is fully initialised.

---

### 10. Scene Name Collision Risk in Projector Hotkeys Plugin
The plugin converts scene names to Lua function identifiers:
```lua
function output_to_function_name(name)
    return "ofsp_" .. name:gsub('[%p%c%s]', '_')
end
```
Two scenes differing only by punctuation or whitespace (e.g., `"Scene (1)"` and `"Scene [1]"`) will map to the same identifier, causing a silent collision.

**Impact:** Low in practice, but a potential confusing bug for users with systematically named scenes.

---

### 11. No Automated Restore Test or Second-Machine Validation
`7_Testing_Known` shows 4 out of 10 acceptance criteria as `⬜ Untested` or `⬜ Not Built` (all in Objective 2: reproducibility). The core value proposition — _reproduce OBS on a new machine_ — has not been validated end-to-end.

---

## 🔧 What Can Be Done — Prioritised Action Items

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| 🔴 High | Implement `restore-obs-config.ps1` with path remapping | Medium | High |
| 🔴 High | Exclude Whisper model `.bin`/`.gguf` files from backup and `.gitignore` | Low | High |
| 🟠 Medium | Remove `.json.v1` manual backup files; rely on Git history | Low | Medium |
| 🟠 Medium | Add GitHub Actions workflow to validate scene JSON on push | Low | Medium |
| 🟠 Medium | Fix `locked.txt` — replace with relevant OBS content or remove | Low | Low |
| 🟡 Low | Add incremental backup (remove the full-wipe `Remove-Item`) | Medium | Medium |
| 🟡 Low | Add `backup-obs-config.sh` for macOS/Linux support | Medium | Medium |
| 🟡 Low | Investigate proper startup event for projector hotkeys (avoid double-open) | High | Low |
| 🟡 Low | Add scene name collision guard in projector hotkeys plugin | Low | Low |
| 🟡 Low | Conduct second-machine restore test and update `7_Testing_Known` | Medium | High |

---

## Detailed Action: Restore Script Outline

```powershell
# restore-obs-config.ps1 (proposed)
param(
    [string]$BackupDir  = (Join-Path $PSScriptRoot "obs-config-backup"),
    [string]$OldUser    = "",         # Username from backup machine (auto-detected if blank)
    [switch]$DryRun
)

$obsConfigDir = Join-Path $env:APPDATA "obs-studio"

# Path remapping: replace old username with current
if ($OldUser -ne "") {
    Get-ChildItem "$BackupDir\basic\scenes\*.json" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $content = $content -replace [regex]::Escape("C:\\Users\\$OldUser"), "C:\\Users\\$env:USERNAME"
        if (-not $DryRun) { Set-Content $_.FullName $content }
    }
}

# Copy backup → %APPDATA%\obs-studio
if (-not $DryRun) {
    Copy-Item "$BackupDir\*" -Destination $obsConfigDir -Recurse -Force
}
```

---

## Detailed Action: GitHub Actions Validation Workflow

```yaml
# .github/workflows/validate-scenes.yml
name: Validate OBS Scene JSON

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate all scene JSON files
        run: |
          failed=0
          for f in obs-config-backup/basic/scenes/*.json; do
            python3 -m json.tool "$f" > /dev/null 2>&1 \
              && echo "✓ $f" \
              || { echo "✗ $f — INVALID JSON"; failed=1; }
          done
          exit $failed
```

---

## Overall Health Score

| Category | Score | Notes |
|----------|-------|-------|
| Documentation | 9/10 | Excellent per-folder READMEs and project page |
| Backup automation | 8/10 | Works well; full-wipe approach is the main weakness |
| Restore automation | 1/10 | Not implemented |
| Plugin quality | 7/10 | Functional; grey-screen workaround is a known issue |
| Repository hygiene | 6/10 | `.json.v1` files and unrelated `locked.txt` lower the score |
| CI/CD | 0/10 | No automated validation workflows |
| Cross-platform | 2/10 | Windows-only tooling |
| **Overall** | **5/10** | Solid foundation; restore path and CI are the critical gaps |
