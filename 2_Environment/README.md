# 2_Environment — The Landscape

## Technology Stack

| Component       | Technology          | Role                                    |
|-----------------|---------------------|-----------------------------------------|
| OBS Studio      | 28+ (C/C++)         | The streaming/recording application     |
| Lua Scripting   | OBS Lua API         | Plugin automation (projector hotkeys)    |
| PowerShell      | 5.1+                | Backup/restore automation               |
| Git             | Version control     | Track config changes over time          |
| Windows         | 10/11               | Host OS (`%APPDATA%` paths)             |

## OBS Configuration Landscape

### Where OBS stores its data
```
%APPDATA%\obs-studio\
├── basic\
│   ├── profiles\        ← Encoding, streaming, recording settings
│   └── scenes\          ← Scene collections (sources, filters, transforms)
├── plugin_config\       ← Per-plugin settings
│   ├── obs-browser\     ← Browser source (CEF cache, cookies, DRM)
│   ├── obs-websocket\   ← WebSocket server config
│   ├── obs-localvocal\  ← Whisper AI models (large binaries)
│   ├── rtmp-services\   ← Streaming service definitions
│   └── win-capture\     ← Window/game capture metadata
├── plugin_manager\      ← Installed plugin registry
├── global.ini           ← Global OBS settings
├── user.ini             ← User preferences
├── logs\                ← Session logs (not backed up)
├── crashes\             ← Crash dumps (not backed up)
└── profiler_data\       ← Performance data (not backed up)
```

## Constraints

- **Machine-specific paths**: Scene JSON files may contain absolute paths to video/image sources
- **Large binaries**: Whisper models (obs-localvocal) can be hundreds of MB
- **Locked files**: Browser cookies/databases may be locked while OBS is running
- **No native export**: OBS has no built-in "export all settings" feature
- **Plugin compatibility**: Plugin configs may differ between OBS versions

## Use Cases

1. **Disaster recovery** — Reinstall Windows, restore OBS exactly as it was
2. **Multi-machine sync** — Same OBS setup on desktop and laptop
3. **Change tracking** — See what changed when a scene broke
4. **Onboarding** — New team member gets a proven OBS config instantly
5. **Experimentation** — Try new layouts knowing you can revert via Git

## Roadmap

- [x] Backup script for OBS config (`backup-obs-config.ps1`)
- [x] Projector hotkeys plugin (`5_Symbols/plugins/projector-hotkeys.lua`)
- [x] Git-based version control
- [x] Restore script with path remapping (`restore-obs-config.ps1`)
- [x] Detailed re-setup implementation steps (`4_Formula/RESETUP-STEPS.md`)
- [x] Re-setup roadmap (this document)
- [x] GitHub Actions to validate scene JSON on push
- [ ] Incremental backup (replace full-wipe with `robocopy /MIR`)
- [ ] Cross-platform backup script (`backup-obs-config.sh` for macOS/Linux)
- [ ] Second-machine restore validation (update `7_Testing_Known`)

---

## Re-Setup Roadmap

Use this roadmap when setting up OBS on a new machine or after a clean Windows install.
The full step-by-step guide is in [`4_Formula/RESETUP-STEPS.md`](../4_Formula/RESETUP-STEPS.md).

### Phase 1 — Install OBS Studio

| Step | Action | Status |
|------|--------|--------|
| 1.1 | Install stable OBS via Chocolatey: `choco install obs-studio` | ⬜ |
| 1.2 | Run OBS once to initialize `%APPDATA%\obs-studio\`, then close OBS | ⬜ |

### Phase 2 — Restore Configuration

| Step | Action | Status |
|------|--------|--------|
| 2.1 | Clone this repo on the new machine | ⬜ |
| 2.2 | Run: `.\restore-obs-config.ps1 -OldUser "Pexabo"` | ⬜ |
| 2.3 | Verify scenes, profiles, and plugin configs are in `%APPDATA%\obs-studio\` | ⬜ |

### Phase 3 — Install Required Plugins

| Plugin | URL | Status |
|--------|-----|--------|
| obs-source-record | https://github.com/exeldro/obs-source-record | ⬜ |
| obs-color-monitor | https://github.com/nagadomi/obs-color-monitor | ⬜ |
| move-transition | https://github.com/exeldro/obs-move-transition | ⬜ |
| advanced-scene-switcher | https://github.com/WarmUpTill/SceneSwitcher | ⬜ |
| distroav | https://github.com/DistroAV/DistroAV | ⬜ |
| Elgato StreamDeck for OBS | https://www.elgato.com/software-center | ⬜ |

### Phase 4 — Load Custom Scripts

| Step | Action | Status |
|------|--------|--------|
| 4.1 | OBS → Tools → Scripts → [+] → load `5_Symbols/plugins/projector-hotkeys.lua` | ⬜ |
| 4.2 | Configure monitor assignments in the script settings | ⬜ |
| 4.3 | Assign hotkeys: Settings → Hotkeys | ⬜ |

### Phase 5 — Hardware & OS Configuration

| Step | Action | Status |
|------|--------|--------|
| 5.1 | **Run OBS as Administrator** (fixes GPU priority / encoding lag) | ⬜ |
| 5.2 | Disable Windows Game DVR (Win+I → Gaming → Xbox Game Bar → Off) | ⬜ |
| 5.3 | Set Desktop Audio to a fixed device (not "Default") | ⬜ |
| 5.4 | Remove/remap dead "Audio Output Capture 2" source | ⬜ |
| 5.5 | Distribute USB cameras across separate USB controllers | ⬜ |
| 5.6 | Connect Elgato Wave:3 to the same USB port every time | ⬜ |
| 5.7 | Change Insta360 source format to YUY2/NV12 | ⬜ |
| 5.8 | Set ZV-1 source FPS to match project (60 or 30fps) | ⬜ |
| 5.9 | Update AMD GPU drivers (prevents GPU device reset / TDR events) | ⬜ |

### Phase 6 — First Launch Verification

| Check | Expected Result | Status |
|-------|----------------|--------|
| No crash warning on open | Clean startup | ⬜ |
| NationalGrid scene collection loads | All scenes visible | ⬜ |
| All profiles present | Complex, Main, Untitled, only_cam, onlyhd | ⬜ |
| No plugin load errors | All plugins listed load successfully | ⬜ |
| No GPU thread priority warning | Running as admin resolves this | ⬜ |
| Cameras and audio sources active | No "device not found" errors | ⬜ |
| Test recording completes | Output file plays back correctly | ⬜ |


Log location > C:\Users\Pexabo\AppData\Roaming\obs-studio\logs

Script load location > 
C:\Program Files\obs-studio\data\obs-plugins\frontend-tools\scripts

Obs Install Location
C:\Program Files\obs-studio\bin\64bit

OBS Installed via
Choco
