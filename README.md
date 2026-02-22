# OBS Studio Configuration & Plugins

A repository for managing OBS Studio configuration backups and custom plugins.

## Project Structure

```
obs/
├── plugins/
│   └── projector-hotkeys.lua   # Lua plugin for fullscreen projector hotkeys
├── obs-config-backup/          # Backed-up OBS Studio configuration
│   ├── basic/
│   │   ├── profiles/           # Streaming/recording profiles
│   │   │   ├── Complex/
│   │   │   ├── Main/
│   │   │   ├── onlyhd/
│   │   │   ├── only_cam/
│   │   │   └── Untitled/
│   │   └── scenes/             # Scene collections
│   │       ├── AllDevices.json
│   │       ├── CourseEra.json
│   │       ├── Interview.json
│   │       ├── Marp.json
│   │       ├── NationalGrid.json
│   │       ├── simpleScreen.json
│   │       └── ...
│   └── plugin_config/          # Plugin settings (browser, websocket, etc.)
├── backup-obs-config.ps1       # PowerShell script to back up OBS config
├── index.html                  # Project overview page
├── .gitignore
└── README.md
```

## Plugins

### Projector Hotkeys (`plugins/projector-hotkeys.lua`)

An OBS Lua script that adds hotkeys to open fullscreen projectors. Features include:

- **Hotkey-based projectors** — Assign hotkeys to open fullscreen projectors for the Program output, Multiview, and every scene
- **Monitor selection** — Choose which monitor each projector opens on (supports up to 10 monitors)
- **Startup projectors** — Optionally auto-open projectors to specific monitors when OBS starts
- **Double-open workaround** — Option to open a duplicate projector on startup to fix the grey-screen issue some users experience

#### Installation

1. Open OBS Studio → **Tools** → **Scripts**
2. Click **+** and select `projector-hotkeys.lua`
3. Configure monitor assignments in the script settings
4. Set hotkeys in **Settings** → **Hotkeys**

> **Note:** If scenes are added or renamed, the script must be reloaded.

## Configuration Backup

The `backup-obs-config.ps1` script copies your OBS configuration from `%APPDATA%\obs-studio` into the `obs-config-backup/` folder, skipping caches, logs, and crash dumps.

### Usage

```powershell
# Back up to the default location (obs-config-backup/)
.\backup-obs-config.ps1

# Back up to a custom directory
.\backup-obs-config.ps1 -BackupDir "C:\my-backups\obs"
```

### What Gets Backed Up

| Directory        | Contents                                     |
|------------------|----------------------------------------------|
| `basic/profiles` | Streaming & recording profiles (bitrate, encoder, service settings) |
| `basic/scenes`   | Scene collections (sources, filters, layouts) |
| `plugin_config`  | Plugin settings (browser source, websocket, local vocal, etc.) |
| `plugin_manager` | Installed plugin registry                    |
| Root files       | `global.ini`, `user.ini`                     |

### What Gets Skipped

Caches, logs, crash dumps, profiler data, temp files, and browser storage.

## Scene Collections

| Scene             | Description                        |
|-------------------|------------------------------------|
| AllDevices        | Multi-device capture setup         |
| CourseEra         | Course recording layout            |
| Interview         | Interview/talking-head layout      |
| Marp              | Marp presentation recording        |
| NationalGrid      | National Grid project layout       |
| simpleScreen      | Simple screen capture              |

## Requirements

- **OBS Studio** 28+ (for Lua scripting and frontend API support)
- **PowerShell** 5.1+ (for the backup script)
- **Windows** (backup script uses `%APPDATA%` paths)

## Credits

- Projector Hotkeys plugin by [David Magnus](https://github.com/DavidKMagnus)
- Built on OBS frontend projector API from [obsproject/obs-studio#1910](https://github.com/obsproject/obs-studio/pull/1910/)
