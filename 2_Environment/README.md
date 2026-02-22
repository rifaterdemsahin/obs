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

- [x] Backup script for OBS config
- [x] Projector hotkeys plugin
- [x] Git-based version control
- [ ] Restore script to push config back to `%APPDATA%`
- [ ] Machine-specific path remapping on restore
- [ ] GitHub Actions to validate scene JSON on push
- [ ] Documentation for cross-machine portability
