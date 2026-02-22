# OBS Log Analysis Report

**Period Analyzed:** 2026-02-17 through 2026-02-22 (10 sessions)
**OBS Version:** 32.1.0-rc1
**System:** AMD Ryzen Threadripper PRO 3995WX | AMD Radeon RX 6900 XT (16GB VRAM) | 64GB RAM | Windows 11

---

## Executive Summary

Across 10 OBS sessions, a consistent set of configuration problems and hardware instability issues were identified. The most urgent issue is **7.6% encoding lag** (232 dropped frames) recorded on 2026-02-22 07:46, which directly degrades recording quality. This is compounded by OBS running as a **non-administrator process**, preventing GPU priority scheduling that AMD hardware requires for stable rendering.

Audio instability is the dominant recurring theme: a permanently missing WASAPI capture device (Audio Output Capture 2) fails every session, the Elgato Wave:3 microphone intermittently disappears from the system on startup, and the Focusrite Scarlett XLR interface drops out under load. One session (2026-02-19 10:04) experienced a catastrophic audio buffering spike of **618ms** following a mid-session GPU device reset.

One confirmed crash/unclean shutdown occurred (session 2026-02-19 12:33). Two missing OBS plugins generate errors in every single session. The Elgato Prompter display has been physically disconnected since 2026-02-19. The system is running an OBS release candidate rather than a stable build.

**Healthy aspects:** CPU and GPU utilization remain acceptable in most sessions. The AMD AMF H.264 encoder initializes correctly. Recording outputs complete successfully in the majority of sessions.

---

## Quick Fix Priority List

### Priority 1 — Run OBS as Administrator
**Impact:** Immediately resolves GPU thread priority failure (every session), eliminates QThread priority warnings, and gives the AMD AMF encoder higher scheduling priority to prevent future encoding lag events. Single checkbox change that affects every future session.

**Steps:** `C:\Program Files\obs-studio\bin\64bit\obs64.exe` > Right-click > Properties > Compatibility > Check "Run this program as an administrator" > Apply.

**Time:** 2 minutes.

---

### Priority 2 — Fix Dead Audio Device + Set Desktop Audio to a Fixed Device
**Impact:** Eliminates persistent WASAPI error on every session startup, and prevents the 30+ default-device-switch audio churn from destabilizing OBS.

**Steps:**
1. OBS > Right-click "Audio Output Capture 2" source > Remove (or re-map to a valid device)
2. OBS > Settings > Audio > Desktop Audio > change from `Default` to your specific primary output device
3. OBS > Settings > Audio > Advanced > Audio Monitoring Device > change from `Default` to a specific device

**Time:** 5 minutes.

---

### Priority 3 — Disable Windows Game DVR
**Impact:** Frees GPU encode capacity exclusively for AMF H.264, directly reducing the risk of encoding lag recurrence (the 7.6% frame drop event).

**Steps:**
1. Win + I > Gaming > Xbox Game Bar > toggle Off
2. Win + I > Gaming > Captures > toggle "Record in the background while I'm playing a game" to Off

**Time:** 2 minutes.

---

## Issues by Severity

---

### CRITICAL

#### C1 — Encoding Lag: 7.6% Skipped Frames
- **What:** `Video stopped, number of skipped frames due to encoding lag: 232/3068 (7.6%)` — AMD AMF encoder could not keep up with frame rate, producing a choppy recording.
- **When:** 1 of 10 sessions — `2026-02-22 07-46-03.txt`
- **Cause:** Coincided with 30+ audio device switches within 15 minutes. OBS not running as admin means the encoder competes at normal process priority.
- **Fix:** See Priority 1 (run as admin) and Priority 3 (disable Game DVR).

#### C2 — OBS Not Running as Administrator (GPU Priority Failure)
- **What:** Every session: `warning: Failed to set D3D11 GPU thread priority` — OBS cannot elevate its rendering thread on AMD hardware.
- **When:** Every session (10/10).
- **Fix:** See Priority 1.

#### C3 — Crash / Unclean Shutdown Detected
- **What:** Session 2026-02-19 12:33 opened with `Crash or unclean shutdown detected`. The prior session (10:04) experienced both a GPU device reset and 618ms audio spike — likely root causes.
- **When:** 1 confirmed crash — `2026-02-19 12-33-29.txt`
- **Fix:** Stabilize GPU driver (R5), run as admin (Priority 1), upgrade to stable OBS (R12).

#### C4 — Mid-Session GPU Device Reset
- **What:** `Device Remove/Reset! Rebuilding all assets...` — AMD RX 6900 XT driver crashed and recovered (TDR event), disrupting all capture sources mid-session.
- **When:** 1 instance — `2026-02-19 10-04-28.txt`
- **Fix:** Update AMD GPU drivers. Check GPU temps/power delivery. Disable hardware-accelerated GPU scheduling if enabled.

#### C5 — Catastrophic Audio Buffering Spike (618ms)
- **What:** `adding 576 milliseconds of audio buffering, total audio buffering is now 618 milliseconds (source: zv1-sony)` — audio and video drifted ~0.6 seconds apart. Recordings from after this event have desynced audio.
- **When:** 1 instance following the GPU reset — `2026-02-19 10-04-28.txt`
- **Action:** Review any recordings from that session. Audio after ~12:10 will need manual realignment or re-recording.

---

### WARNING

#### W1 — Audio Output Capture 2: WASAPI Device Permanently Missing
- **What:** `[WASAPISource::TryInitDevice] Failed to enumerate device... error code: 80070490 (Element not found)` — device `{d760c5dc...}` no longer exists but is still referenced by a scene source.
- **When:** Every session (10/10).
- **Fix:** See Priority 2, step 1.

#### W2 — Elgato Wave:3 Microphone Missing at Startup
- **What:** `elgatoMicRight` WASAPI source fails at startup with error 80070490. Windows reassigns device GUIDs across reboots (old: `{3b3b683a...}`, new: `{e85ac5b4...}`).
- **When:** 3 of 10 sessions — `2026-02-20 08-36-05.txt`, `2026-02-22 07-46-03.txt`, `2026-02-22 17-43-24.txt`
- **Fix:** Always connect the Wave:3 to the same USB port. Use Elgato Wave Link virtual audio device as the OBS source instead of the raw WASAPI device for a stable ID.

#### W3 — Focusrite Scarlett XLR Audio Dropout
- **What:** `[WASAPISource::OnDeviceInvalidated] Device invalidated! error code: 88890004` (`AUDCLNT_E_DEVICE_INVALIDATED`) — USB audio interface disconnects under load, interrupting recording for a few seconds.
- **When:** 2 sessions — `2026-02-17 07-34-29.txt`, `2026-02-18 07-34-02.txt`
- **Fix:** Connect Scarlett directly to a motherboard USB port (not a hub). Disable USB selective suspend: Control Panel > Power Options > Advanced > USB selective suspend > Disabled. Update Focusrite drivers.

#### W4 — Massive Audio Device Churn (30+ Device Switches in 15 Minutes)
- **What:** 30+ consecutive "default output device changed" events in one session. Audio buffering climbed to 234ms. Likely caused by Elgato Wave Link, VB-Audio Cable, or Steam Streaming negotiating audio routing.
- **When:** 1 session — `2026-02-22 07-46-03.txt`
- **Fix:** See Priority 2, steps 2–3 (pin Desktop Audio and Monitoring to fixed devices).

#### W5 — Elgato Facecam: Video Configuration Failed
- **What:** `fc: data.GetDevice failed` / `fc: Video configuration failed`. One escalation to `DShow: Run failed (0x800705AA): Insufficient system resources` — USB bandwidth exhaustion preventing the DirectShow capture pipeline from allocating kernel resources.
- **When:** Config failure in 4+ sessions. Resource exhaustion once in `2026-02-19 10-04-28.txt`.
- **Fix:** Use Device Manager (View > Devices by connection) to identify USB root hubs and distribute the Facecam, Insta360, and Brio across different physical USB controllers.

#### W6 — Insta360: DecodeDeviceId Failed / MJPEG dqt Warning Flood
- **What:** Two issues: (1) `insta360: DecodeDeviceId failed` at startup in one session. (2) Hundreds of `warning: dqt: 0 quant value` MJPEG decoder warnings flooding the log (making `2026-02-20 08-36-05.txt` abnormally large) — corrupted quantization tables in initial frames.
- **When:** DecodeDeviceId in `2026-02-17 07-34-29.txt`; MJPEG flood in `2026-02-20 08-36-05.txt`
- **Fix:** Update Insta360 Link firmware and drivers. In OBS Source Properties, change Video Format from MJPEG to YUY2 or NV12 to bypass the MJPEG decoder.

#### W7 — Rendering Lag (Graphics Thread Spikes)
- **What:** Profiler reports large maximum spike durations on the graphics thread:

  | Session | Max Spike | Rendering Lag % |
  |---|---|---|
  | 2026-02-17 07:34 | 734 ms | 0.1% |
  | 2026-02-17 23:02 | 157 ms | 0.2% |
  | 2026-02-19 12:33 | 319 ms | 0.0% (1 frame) |
  | 2026-02-22 07:46 | — | 0.3% (8 frames) |

  Below the 1% visible-impact threshold but the 734ms spike indicates a full-second rendering freeze correlating with device initialization events.
- **Fix:** Running as admin (Priority 1) and disabling Game DVR (Priority 3) will reduce spike frequency.

#### W8 — Window Capture Audio Fails Every Session (App Not Open)
- **What:** `[WASAPISource] Failed to find process for window capture` — a per-application audio capture source (Chrome/Instagram) cannot find the target process because it isn't running at OBS launch.
- **When:** Every session (10/10). Benign if intentional.
- **Fix:** Either ensure the application is open before OBS, or remove the source if no longer needed.

#### W9 — Missing Plugin: obs-source-record
- **What:** `Failed to load module file obs-source-record.dll` — plugin not installed. Sources using `source_record_filter` silently fail.
- **When:** Every session (10/10).
- **Fix:** Install from https://github.com/exeldro/obs-source-record — or remove scene references to `source_record_filter` to eliminate log errors.

#### W10 — Missing Plugin: obs-color-monitor (falsecolor_filter)
- **What:** Failure to load `net.nagater.obs-color-monitor.falsecolor_filter` — plugin not installed. Sources using falsecolor filter display incorrectly.
- **When:** Every session (10/10).
- **Fix:** Install from https://github.com/nagadomi/obs-color-monitor — or remove scene references to `falsecolor_filter`.

#### W11 — OBS Running Release Candidate Build (32.1.0-rc1)
- **What:** Pre-release candidate, not a stable release. RC builds may contain unfixed bugs. The confirmed crash (C3) and GPU device reset (C4) could have been exacerbated by RC-specific regressions.
- **When:** All sessions (10/10).
- **Fix:** Upgrade to the current stable release from obsproject.com.

#### W12 — win-capture.dll Load Time: 551ms (Abnormal)
- **What:** `win-capture.dll: 551.455 ms (module load)` — normal is under 50ms. Session immediately followed a crash, which may have left system state degraded.
- **When:** 1 session — `2026-02-19 12-33-29.txt`

---

### INFO

#### I1 — Expected Module Load Failures (No Matching Hardware)
- `aja-output-ui.dll` / `aja.dll` — AJA capture card not present
- `decklink.dll` / `decklink-output-ui.dll` — Blackmagic DeckLink not present
- `obs-nvenc.dll` — NVIDIA encoder (AMD GPU system)
- CUDA / NVIDIA effects — no NVIDIA hardware

All benign. Expected on an AMD-only system.

#### I2 — Sony BRIO Camera at 640x480 (Underutilized)
The BRIO supports up to 4K. Currently configured at 640x480. After resolving USB bandwidth issues (W5/R7), increase to 1920x1080 or higher in Source > Properties > Resolution.

#### I3 — Sony ZV-1 Camera at 50fps (OBS Project at 60fps)
OBS will duplicate/drop frames to match the 60fps project, causing subtle judder. Fix: Source > Properties > FPS > set to 60.00 (if camera supports it) or 30.00 as a stable fallback.

#### I4 — Elgato Prompter Disconnected Since 2026-02-19
The Prompter source shows `display: (0x0)` in every session since 2026-02-19. Either reconnect the Prompter, or remove/disable the source in affected scenes.

#### I5 — Windows Game DVR Enabled
Xbox Game Bar background recording is capturing GPU resources and can interfere with OBS's D3D11 capture pipeline. See Priority 3.

#### I6 — Windows Firewall Disabled
No direct OBS impact, but a security concern for a streaming/recording system connected to the internet.

#### I7 — Memory Leaks at Shutdown (2 Objects)
`warning: 2 leaked objects at shutdown` appears in every session with profiler output. Consistent 2-object count — no growth, no operational impact. Likely a known RC build issue.

#### I8 — Audio Monitoring Set to "Default" Device
When the system default audio device changes, OBS monitoring breaks or switches unexpectedly mid-session. Fix: Settings > Audio > Advanced > Audio Monitoring Device > select a specific fixed device.

#### I9 — QThread Priority Failures on File Splits
`QThread::start: Failed to set thread priority` on each new output file split. Non-admin privilege issue. Recordings complete, but without priority hints. Resolved by Priority 1.

#### I10 — StreamDeck Plugin: Failed to Load 'en-GB' Locale
Cosmetic localization packaging issue in the Elgato StreamDeck OBS plugin. No functional impact.

---

## Full Recommendations Reference

| # | Action | Addresses |
|---|---|---|
| R1 | Run OBS as Administrator | C1, C2, I9 |
| R2 | Disable Windows Game DVR | C1, W7 |
| R3 | Remove/remap "Audio Output Capture 2" dead source | W1 |
| R4 | Fix Elgato Wave:3 USB port + use Wave Link virtual device | W2 |
| R5 | Fix Focusrite Scarlett USB (direct port, disable suspend, update drivers) | W3 |
| R6 | Pin Desktop Audio and Monitoring to fixed devices (not Default) | W4, I8 |
| R7 | Redistribute cameras across USB controllers to fix resource exhaustion | W5 |
| R8 | Update Insta360 firmware; switch source format to YUY2/NV12 | W6 |
| R9 | Set ZV-1 source to 60fps (or 30fps) to match project | I3 |
| R10 | Upgrade Sony BRIO resolution after resolving USB bandwidth | I2 |
| R11 | Install obs-source-record and obs-color-monitor plugins | W9, W10 |
| R12 | Upgrade OBS to current stable release | W11 |
| R13 | Reconnect or remove Elgato Prompter source | I4 |
| R14 | Review/repair 2026-02-19 10:04 recordings for audio desync | C5 |

---

*Report generated from 10 log files: 2026-02-17 01:13:34 through 2026-02-22 17:43:24.*
