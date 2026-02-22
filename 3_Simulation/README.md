# 3_Simulation — What It Could Look Like

## Simulated Workflow

### Backup Flow
```
User runs .\backup-obs-config.ps1
         │
         ▼
  Read %APPDATA%\obs-studio
         │
         ├── Skip: caches, logs, crashes, temp files
         ├── Skip: locked files (graceful error handling)
         │
         ▼
  Copy to obs-config-backup/
         │
         ▼
  git add → git commit → git push
         │
         ▼
  Configuration is now version-controlled ✓
```

### Restore Flow (Future)
```
User clones repo on new machine
         │
         ▼
  Run .\restore-obs-config.ps1
         │
         ├── Detect current machine paths
         ├── Remap absolute paths in scene JSON
         │
         ▼
  Copy obs-config-backup/ → %APPDATA%\obs-studio
         │
         ▼
  Launch OBS → Configuration restored ✓
```

## Example Scene Collection Structure

A typical scene JSON (`basic/scenes/Interview.json`) contains:
```json
{
    "name": "Interview",
    "sources": [
        {
            "name": "Webcam",
            "type": "dshow_input",
            "settings": { "video_device_id": "..." }
        },
        {
            "name": "Screen Share",
            "type": "monitor_capture",
            "settings": { "monitor": 0 }
        },
        {
            "name": "Overlay",
            "type": "image_source",
            "settings": { "file": "C:\\assets\\overlay.png" }
        }
    ],
    "transitions": [...],
    "hotkeys": [...]
}
```

## Example Profile Structure

A profile (`basic/profiles/Complex/basic.ini`) defines:
```ini
[Video]
BaseCX=1920
BaseCY=1080
OutputCX=1920
OutputCY=1080
FPSType=0
FPSCommon=30

[Output]
Mode=Advanced
RecType=Standard
RecFormat=mkv

[Stream1]
ServiceType=rtmp_common
```

## UI/UX Mockup — Backup Script Output

```
============================================
 OBS Studio Configuration Backup
============================================

Source : C:\Users\User\AppData\Roaming\obs-studio
Destination: C:\projects\obs\obs-config-backup

Backing up...
  ✓ basic/profiles (5 profiles)
  ✓ basic/scenes (10 scene collections)
  ✓ plugin_config (4 plugins)
  ✓ Root config files (2 files)
  ⚠ Skipped: plugin_config/obs-browser/Cookies (locked)

Backup complete!
  Files copied : 391
  Files skipped: 730 (caches, logs, etc.)
```
