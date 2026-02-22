# OBS Studio — Infrastructure as Code

> 


A repository for treating OBS Studio configuration as Infrastructure-as-Code (IaC): version-controlled, reproducible, and automated.

## Knowledge System

The project follows a journey from _unknown problem_ → _understood solution_ → _proven result_:

| Folder | Purpose |
|--------|---------|
| [`1_Real_Unknown`](1_Real_Unknown/) | Define the problem — OKRs, goals, questions to answer |
| [`2_Environment`](2_Environment/) | Read the landscape — roadmap, constraints, use cases |
| [`3_Simulation`](3_Simulation/) | Examples and mockups — what the solution could look like |
| [`4_Formula`](4_Formula/) | Steps and guides — the recipe for building it |
| [`5_Symbols`](5_Symbols/) | Core source code — where the formula becomes real |
| [`6_Semblance`](6_Semblance/) | Errors and near-misses — problems, causes, fixes |
| [`7_Testing_Known`](7_Testing_Known/) | Validation — prove it solves the original unknowns |

## Project Structure

```
obs/
├── 1_Real_Unknown/             # Problem definition & OKRs
├── 2_Environment/              # Landscape, roadmap, constraints
├── 3_Simulation/               # Workflow diagrams & mockups
├── 4_Formula/                  # Step-by-step build guide
├── 5_Symbols/                  # Source code documentation
├── 6_Semblance/                # Error log & workarounds
├── 7_Testing_Known/            # Test matrix & validation
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
