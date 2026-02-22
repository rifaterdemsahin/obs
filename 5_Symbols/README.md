# 5_Symbols — Source Code

## Core Implementation Files

This folder documents the actual source code that makes the IaC system work.

### File Index

| File | Language | Purpose |
|------|----------|---------|
| [`backup-obs-config.ps1`](../backup-obs-config.ps1) | PowerShell | Backs up OBS config to repo |
| [`plugins/projector-hotkeys.lua`](../plugins/projector-hotkeys.lua) | Lua | Fullscreen projector hotkey plugin |
| [`.gitignore`](../.gitignore) | Config | Excludes videos, caches, IDE files |
| [`index.html`](../index.html) | HTML/CSS | Project overview page |

---

### backup-obs-config.ps1 — Key Symbols

```powershell
# Entry point parameters
param(
    [string]$BackupDir = (Join-Path $PSScriptRoot "obs-config-backup")
)

# Exclusion lists — what NOT to back up
$excludeDirs = @("crashes", "logs", "profiler_data", "updates", ".sentinel")
$excludeFilePatterns = @("*.log", "*.bak", "*.tmp")
$excludeCachePatterns = @("*\Cache\*", "*\GPUCache\*", "*\blob_storage\*",
                          "*\Session Storage\*", "*\Local Storage\*", "*\Code Cache\*")

# Locked file handling
try {
    Copy-Item $file.FullName -Destination $destPath -Force -ErrorAction Stop
} catch {
    Write-Host "  Skipped (locked): $relativePath"
}
```

---

### projector-hotkeys.lua — Key Symbols

```lua
-- Projector type constants
PROJECTOR_TYPE_SCENE     = "Scene"
PROJECTOR_TYPE_SOURCE    = "Source"
PROJECTOR_TYPE_PROGRAM   = "StudioProgram"
PROJECTOR_TYPE_MULTIVIEW = "Multiview"

-- Core function: open a fullscreen projector via OBS API
function open_fullscreen_projector(output)
    obslua.obs_frontend_open_projector(projector_type, monitors[output], "", output)
end

-- Hotkey registration: creates a hotkey per scene + Program + Multiview
function register_hotkeys(settings)
    for _, output in ipairs(outputs) do
        hotkey_ids[output] = obslua.obs_hotkey_register_frontend(...)
    end
end

-- Startup: auto-open projectors when OBS launches
function open_startup_projectors()
    for output, open_on_startup in pairs(startup_projectors) do
        if open_on_startup then open_fullscreen_projector(output) end
    end
end
```

---

### OBS Scene JSON — Data Structure

Scene collections are stored as JSON in `obs-config-backup/basic/scenes/`. Key structure:

```
Scene Collection
├── name: string
├── sources[]: array
│   ├── name: string
│   ├── id: string (type identifier)
│   ├── settings: object (source-specific config)
│   ├── mixers: number (audio routing)
│   └── filters[]: array (visual/audio filters)
├── transitions[]: array
├── transition_duration: number
└── groups[]: array (source grouping)
```
