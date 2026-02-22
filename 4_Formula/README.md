# 4_Formula — How to Build It

## Recipe: OBS Infrastructure-as-Code

### Step 1: Initialize the Repository

```powershell
mkdir obs
cd obs
git init
```

### Step 2: Create .gitignore

Exclude large/binary/temp files that shouldn't be version-controlled:

```gitignore
# Video files
*.mp4
*.mkv
*.avi
*.mov

# IDE folders
.zencoder/
.zenflow/

# OS files
Thumbs.db
Desktop.ini
.DS_Store
```

### Step 3: Build the Backup Script

Key design decisions:
1. **Source**: `%APPDATA%\obs-studio`
2. **Destination**: `obs-config-backup/` in the repo
3. **Exclude by directory**: `crashes`, `logs`, `profiler_data`, `updates`, `.sentinel`
4. **Exclude by pattern**: `*.log`, `*.bak`, `*.tmp`
5. **Exclude cache subfolders**: `Cache`, `GPUCache`, `blob_storage`, `Session Storage`, `Local Storage`, `Code Cache`
6. **Handle locked files**: `try/catch` with graceful skip

```powershell
param(
    [string]$BackupDir = (Join-Path $PSScriptRoot "obs-config-backup")
)

$obsConfigDir = Join-Path $env:APPDATA "obs-studio"

# ... copy files, skip excluded patterns, handle locked files
```

See full implementation: [`backup-obs-config.ps1`](../backup-obs-config.ps1)

### Step 4: Add Custom Plugins

Place OBS Lua/Python scripts in `plugins/`:

```
plugins/
└── projector-hotkeys.lua   # Hotkeys for fullscreen projectors
```

Install in OBS: **Tools → Scripts → + → select file**

### Step 5: Run Backup and Commit

```powershell
.\backup-obs-config.ps1
git add -A
git commit -m "Backup OBS configuration"
git push
```

### Step 6: Restore on New Machine (Future)

```powershell
git clone <repo-url>
cd obs
.\restore-obs-config.ps1   # TODO: implement
```

## Best Practices

1. **Close OBS before backing up** to avoid locked file warnings
2. **Don't backup Whisper models** — they're large and downloadable
3. **Review scene JSON for absolute paths** before restoring on a different machine
4. **Use Git branches** to experiment with different OBS configurations
5. **Tag stable configs** with `git tag` before major changes
6. **Run backup regularly** — automate with Task Scheduler if needed

## PowerShell Cheat Sheet

| Command | Purpose |
|---------|---------|
| `.\backup-obs-config.ps1` | Run backup |
| `git diff obs-config-backup/` | See what changed since last backup |
| `git log --oneline obs-config-backup/` | View backup history |
| `git checkout <hash> -- obs-config-backup/` | Restore a specific version |
| `git stash` | Temporarily shelve changes |
