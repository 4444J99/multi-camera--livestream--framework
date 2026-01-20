# Quick Start Guide

> Get streaming in 15 minutes. Visual step-by-step for first-time setup.

---

## Choose Your Profile

```
+------------------+     +------------------+     +------------------+
|     BUDGET       |     |     STUDIO       |     |    BROADCAST     |
|     ~$3,000      |     |     ~$20,000     |     |     ~$50,000+    |
|                  |     |                  |     |                  |
|  3 cameras       |     |  4 cameras       |     |  8 cameras       |
|  USB capture     |     |  PCIe capture    |     |  SDI capture     |
|  USB audio       |     |  Dante audio     |     |  32ch Dante      |
|  1080p30         |     |  4K30 → 1080p60  |     |  4K60 multi-plat |
|                  |     |                  |     |                  |
|  Small venues    |     |  Pro streaming   |     |  Broadcast TV    |
+------------------+     +------------------+     +------------------+
         |                       |                       |
         v                       v                       v
   budget.yaml             studio.yaml            broadcast.yaml
```

---

## 5-Minute Setup

### Step 1: Clone & Configure

```bash
# Clone the repository
git clone https://github.com/yourusername/multi-camera-livestream-framework.git
cd multi-camera-livestream-framework

# Install dependencies (one time)
make install-deps

# Choose your profile and generate config
make config PROFILE=studio    # or: budget, mobile, broadcast

# Verify configuration generated
ls software/generated/
```

**Expected output:**
```
config.json
config.sh
docs/
```

### Step 2: Hardware Connection

```
                          YOUR SETUP
                              |
        +---------+-----------+-----------+---------+
        |         |           |           |         |
        v         v           v           v         v
    +-------+ +-------+ +-------+ +-------+   +--------+
    |Cam 1  | |Cam 2  | |Cam 3  | |Cam 4  |   | Mics   |
    | HDMI  | | HDMI  | | HDMI  | | HDMI  |   | XLR    |
    +---+---+ +---+---+ +---+---+ +---+---+   +---+----+
        |         |         |         |           |
        +----+----+----+----+         |           |
             |                        |           |
        +----v----+              +----v----+  +---v----+
        |DeckLink |              |DeckLink |  | MOTU   |
        | Quad    |              | Quad    |  | 8PRE   |
        |(inputs  |              |(inputs  |  |(audio) |
        | 1-2)    |              | 3-4)    |  +---+----+
        +----+----+              +----+----+      |
             |                        |      Ethernet
             +--------+    +----------+          |
                      |    |                     |
                 +----v----v----+         +------v------+
                 | Echo Express |         |   Dante     |
                 | (Thunderbolt)|         |   Switch    |
                 +------+-------+         +------+------+
                        |                        |
                   Thunderbolt              Ethernet
                        |                        |
                        +----------+  +----------+
                                   |  |
                              +----v--v----+
                              | Mac Studio |
                              +-----+------+
                                    |
                               Internet
                                    |
                              +-----v-----+
                              |  YouTube  |
                              |  Twitch   |
                              |  etc.     |
                              +-----------+
```

### Step 3: Power On Sequence

```
ORDER MATTERS! Follow this sequence:

  1. Audio Interface    [MOTU 8PRE-ES]
     Wait for: ------> LEDs stable (30 sec)

  2. Dante Switch       [Network switch]
     Wait for: ------> Link lights active

  3. Thunderbolt Chassis [Echo Express]
     Wait for: ------> Power LED solid

  4. Cameras            [All cameras]
     Wait for: ------> HDMI output confirmed

  5. Computer           [Mac Studio]
     Wait for: ------> Desktop ready
```

### Step 4: Run Health Check

```bash
./software/scripts/health-check.sh
```

**What you want to see:**

```
=== Multi-Camera Livestream Framework Health Check ===

[✓] macOS version: 14.2.1
[✓] Disk space: 234GB free (minimum: 50GB)
[✓] Memory: 89GB available
[✓] CPU load: 12% (maximum: 70%)

[✓] DeckLink detected: Quad HDMI Recorder
[✓] MOTU detected: 8PRE-ES
[✓] Dante Controller: Running

[✓] OBS Studio: Installed (29.1.3)
[✓] Ableton Live: Installed (12.0.10)

=== All checks passed! Ready to stream. ===
```

**If you see failures:**
```
[✗] = Critical issue, see TROUBLESHOOTING.md
[⚠] = Warning, can proceed but investigate
```

### Step 5: Launch Applications

```bash
./software/scripts/launch-studio.sh
```

**Launch order (automatic):**
```
1. Dante Controller  -----> Verify audio routing
2. MOTU Discovery    -----> Configure audio interface
3. Ableton Live      -----> Load audio project
4. OBS Studio        -----> Configure scenes
```

### Step 6: Go Live!

```
IN OBS STUDIO:

1. Verify all camera sources visible
   +--------+--------+
   | Cam 1  | Cam 2  |
   +--------+--------+
   | Cam 3  | Cam 4  |
   +--------+--------+

2. Check audio meters (should show signal)
   Audio Mixer: [||||||||    ]  -12 dB (good!)

3. Click "Start Streaming"

4. Verify on platform (YouTube Studio, Twitch Dashboard)
```

---

## Quick Reference Card

### Keyboard Shortcuts (configure in OBS)

| Key | Action |
|-----|--------|
| `F1` | Emergency scene (tech difficulties) |
| `F2` | Mute all audio |
| `F3` | Start/stop stream |
| `F4` | Start/stop recording |
| `1-4` | Switch to camera 1-4 |

### Status Indicators

| Indicator | Meaning |
|-----------|---------|
| OBS: Green circle | Stream active, healthy |
| OBS: Yellow/Red | Dropped frames, check Stats |
| Dante: Green | Clock synced |
| Dante: Red | Clock error, audio will fail |
| MOTU LEDs stable | Audio interface ready |

### Emergency Contacts

| Issue | First Action |
|-------|-------------|
| No video | Check HDMI cables, camera power |
| No audio | Check Dante Controller routing |
| Dropped frames | Lower bitrate, check network |
| Stream disconnect | OBS auto-reconnects; if persistent, check internet |

---

## Profiles Comparison

| Feature | Budget | Mobile | Studio | Broadcast |
|---------|--------|--------|--------|-----------|
| **Cameras** | 3 | 2 | 4 | 8 |
| **Capture** | USB | USB | PCIe | SDI |
| **Audio** | USB | USB | Dante | 32ch Dante |
| **Resolution** | 1080p30 | 1080p30 | 4K30→1080p60 | 4K60 |
| **Platforms** | 1 | 1 | 1 | 3+ |
| **Cost** | ~$3k | ~$2k | ~$20k | ~$50k+ |
| **Use Case** | Church, school | Field, travel | Studio, events | Broadcast TV |

---

## Common First-Time Issues

### "DeckLink not detected"

```
1. Check Thunderbolt cable (both ends)
2. Power cycle Echo Express chassis
3. System Report → Thunderbolt → should list device
4. Reinstall Desktop Video drivers
```

### "No audio in OBS"

```
1. Open Dante Controller
2. Check routing matrix (green checkmarks)
3. Open Ableton, verify tracks armed
4. Check OBS audio source settings
```

### "Stream keeps dropping"

```
1. Use wired Ethernet (not WiFi!)
2. Run speed test: need 10+ Mbps upload
3. Lower bitrate: Settings → Output → 4500 kbps
4. Check for network congestion
```

---

## Next Steps

| When you're ready for... | Read... |
|--------------------------|---------|
| Pre-stream checklist | [RUNBOOK.md](RUNBOOK.md) |
| Camera configuration | [CAMERA-SETTINGS.md](../hardware/CAMERA-SETTINGS.md) |
| Audio setup details | [AUDIO-DANTE.md](AUDIO-DANTE.md) |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Full architecture | [ARCHITECTURE.md](ARCHITECTURE.md) |

---

## One-Page Cheat Sheet

```
┌─────────────────────────────────────────────────────────────┐
│                    STREAMING CHEAT SHEET                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  STARTUP:                                                    │
│    1. Power: Audio → Network → Chassis → Cameras → Mac      │
│    2. Run: ./software/scripts/health-check.sh               │
│    3. Run: ./software/scripts/launch-studio.sh              │
│    4. Verify: Dante routing, camera sources, audio levels   │
│    5. Stream: OBS → Start Streaming                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DURING STREAM:                                              │
│    Monitor: OBS Stats (View → Stats)                         │
│    Watch: Dropped frames (should be 0)                       │
│    Watch: CPU usage (should be <70%)                         │
│    Check: Platform dashboard for viewer issues               │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SHUTDOWN:                                                   │
│    1. OBS: Stop Streaming                                    │
│    2. OBS: Stop Recording (if active)                        │
│    3. Save: Ableton project                                  │
│    4. Run: ./software/scripts/shutdown-studio.sh             │
│    5. Power off: Cameras → Chassis → Audio → Mac (optional)  │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  EMERGENCY:                                                  │
│    F1 = Safe scene (tech difficulties)                       │
│    F2 = Mute all                                             │
│    OBS crash? → Relaunch, scenes auto-restore (~30 sec)      │
│    Internet down? → Phone hotspot via USB                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

*Need help? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or [FAQ.md](FAQ.md)*
