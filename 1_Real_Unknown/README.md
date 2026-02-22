# 1_Real_Unknown — Define the Problem

## The Unknown

**How do we treat OBS Studio configuration as Infrastructure-as-Code (IaC)?**

OBS Studio stores all its configuration — scenes, profiles, sources, filters, hotkeys, plugin settings — as local files in `%APPDATA%\obs-studio`. These are not version-controlled, not portable, and not recoverable after a system wipe. There is no built-in way to:

- Reproduce an identical OBS setup on a new machine
- Track changes to scene layouts over time
- Roll back a broken configuration
- Share a proven setup across team members or devices

## OKRs

### Objective 1: Make OBS configuration fully version-controlled
- **KR1:** All critical OBS config files (scenes, profiles, plugin settings) are committed to Git
- **KR2:** A single script can back up the current OBS state at any time
- **KR3:** Configuration changes are trackable via Git history

### Objective 2: Enable reproducible OBS environments
- **KR1:** A new machine can be set up with the same OBS configuration using this repo
- **KR2:** Scene collections and profiles can be restored from backup
- **KR3:** Plugin settings (hotkeys, websocket, browser sources) survive a reinstall

### Objective 3: Automate OBS setup management
- **KR1:** Backup runs with a single command (`.\backup-obs-config.ps1`)
- **KR2:** Restore script can push config back to `%APPDATA%\obs-studio`
- **KR3:** Custom plugins are stored and documented alongside config

## Key Questions

1. Can OBS scene JSON files be reliably restored across machines?
2. Do plugin configs (e.g., obs-websocket, obs-browser) survive copy/paste restoration?
3. What files are machine-specific vs. portable?
4. How do we handle large binary files (Whisper models, Widevine DLLs) in the backup?
