# 6_Semblance — Errors, Near-Misses & Workarounds

## Known Issues

### Issue 1: Locked Browser Cookies During Backup

**Error:**
```
Copy-Item : The process cannot access the file
'...\obs-browser\Network\Cookies' because it is being used by another process.
```

**Cause:** OBS keeps browser source databases locked while running.

**Fix:** Added `try/catch` around `Copy-Item` with `-ErrorAction Stop`. Locked files are skipped gracefully with a warning message.

**Workaround:** Close OBS before running the backup for a complete copy.

---

### Issue 2: Grey Screen Projectors on Startup

**Error:** Projectors opened via `obs_frontend_open_projector()` on startup show a blank grey screen.

**Cause:** OBS scripts load before the rendering pipeline is fully initialized.

**Fix:** The projector-hotkeys plugin supports a "Open Again on Startup" (`double_startup`) option that opens a duplicate projector, which renders correctly. The original blank projector remains behind it.

**Code:**
```lua
-- in open_startup_projectors()
for output, open_twice in pairs(double_startup) do
    if open_twice then open_fullscreen_projector(output) end
end
```

---

### Issue 3: Large Binary Files in Backup

**Problem:** The `obs-localvocal` plugin stores Whisper AI models (hundreds of MB) in `plugin_config/`. These shouldn't be in Git.

**Status:** Currently these are backed up. Should be excluded or handled via Git LFS.

**Suggested Fix:** Add to backup exclusion list:
```powershell
$excludeCachePatterns += @("*\models\*.bin")
```

---

### Issue 4: Absolute Paths in Scene JSON

**Problem:** Scene collection JSON files may contain absolute Windows paths like:
```json
"file": "C:\\Users\\Pexabo\\Images\\overlay.png"
```

**Impact:** Restoring on a different machine or username will break these sources.

**Status:** Not yet resolved. Future restore script needs path remapping logic.

**Suggested Approach:**
```powershell
# During restore, remap old username to current
$content = Get-Content $sceneFile -Raw
$content = $content -replace 'C:\\\\Users\\\\OldUser', "C:\\\\Users\\\\$env:USERNAME"
Set-Content $sceneFile $content
```

---

### Issue 5: Scene Names with Special Characters

**Problem:** The projector-hotkeys plugin converts scene names to function identifiers:
```lua
function output_to_function_name(name)
    return "ofsp_" .. name:gsub('[%p%c%s]', '_')
end
```

If two scenes have names that differ only by special characters (e.g., "Scene (1)" and "Scene [1]"), they'll collide to the same function name.

**Impact:** Low — unlikely in practice, but worth noting.

---

## Error Log Template

Use this format when logging new issues:

```markdown
### Issue N: <Short Title>

**Error:** <exact error message or symptom>
**Cause:** <root cause analysis>
**Fix:** <what was done to resolve it>
**Status:** Resolved / Workaround / Open
```
