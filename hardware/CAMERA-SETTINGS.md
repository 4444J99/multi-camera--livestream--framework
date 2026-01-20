# Camera Settings Guide

> Per-camera configuration for the Multi-Camera Livestream Framework.

**Last Updated:** 2025-01-20
**Version:** 1.0.0

---

## Overview

This document contains the specific settings for each camera in your multi-camera setup. Consistent settings across all cameras ensure seamless switching and a professional look.

---

## Universal Settings

Apply these settings to **all cameras** for consistency:

### Video Output

| Setting | Value | Notes |
|---------|-------|-------|
| Resolution | 1920x1080 | Or match DeckLink input |
| Frame Rate | 60p | Or 30p if all cameras match |
| HDMI Output | Clean/No Info Display | Critical! |
| HDMI Resolution | Match capture format | Don't let camera scale |

### Exposure

| Setting | Value | Notes |
|---------|-------|-------|
| Mode | Manual or Aperture Priority | Consistency > auto |
| ISO | 400-1600 (start at 800) | Match across cameras; adjust for lighting |
| Shutter Speed | 1/120 for 60fps | Double frame rate rule |
| Aperture | f/4.0-f/5.6 | Balance DOF with light; wider for low-light |

### White Balance

| Setting | Value | Notes |
|---------|-------|-------|
| Mode | Manual (Kelvin) | Never auto |
| Temperature | 5600K (daylight) or 3200K (tungsten) | Match your lighting |
| Tint | 0 (or match to grey card) | Fine-tune if needed |

### Color Profile

| Setting | Value | Notes |
|---------|-------|-------|
| Picture Profile | Standard/Neutral | Easier to match |
| Contrast | 0 or -1 | Slightly flat is easier to grade |
| Saturation | 0 | Neutral |
| Sharpness | -1 or 0 | Avoid over-sharpening |

---

## Per-Camera Configuration

### Camera 1: Panasonic Lumix G7 (Reference Example)

**Role:** Wide shot / Establishing shot
**Position:** Center, 12ft back, elevated 8ft on truss mount
**Lens:** Panasonic 12-35mm f/2.8 II (24-70mm equivalent)

#### Settings

```
Resolution: 1080p60
HDMI Output: Clean (no info display)
White Balance: 5600K (daylight LED panels)
ISO: 800
Aperture: f/4.0
Shutter: 1/120

Photo Style: Natural
Contrast: -1
Saturation: 0
Sharpness: -1
Noise Reduction: -2

Focus: Manual (locked at hyperfocal distance)
Image Stabilization: Off (tripod mounted)
HDCP: Disabled (critical for DeckLink capture)

Power: DMW-AC10 AC adapter + DMW-DCC8 DC coupler
Memory Card: Removed (prevents record prompt)
```

#### Menu Navigation (Lumix G7 Specific)

```
Menu → Setup → TV Connection
├── HDMI Mode: AUTO (defaults to 1080p when HDMI connected)
├── VIERA Link: OFF
└── Info Display: OFF (critical for clean HDMI)

Menu → Rec → Photo Style → Natural
├── Contrast: -1
├── Sharpness: -1
├── Noise Reduction: -2
├── Saturation: 0
└── Hue: 0

Menu → Motion Picture → Rec Quality
├── AVCHD: FHD/60p
└── (HDMI output follows this setting)

Menu → Setup → Economy
└── Power Save: OFF
```

#### Notes

- **HDCP must be disabled** for DeckLink capture to work; this camera has no HDCP on live HDMI output (confirmed compatible)
- Firmware v2.5 tested and verified
- AC adapter eliminates battery heat and runtime concerns
- 12-35mm f/2.8 at f/4.0 provides sharp edge-to-edge performance
- Use DMW-RSL1 remote shutter release to start recording without touching camera
- Sensor crop factor 2x means 12mm = 24mm equivalent field of view

---

### Camera 2: Sony A6400 (Example Mirrorless)

**Role:** Medium shot / Speaker close-up
**Position:** Stage right, 8ft back, tripod at eye level
**Lens:** Sony E 18-105mm f/4 G OSS (27-157mm equivalent)

#### Settings

```
Resolution: 1080p60
HDMI Output: Clean (HDMI Info Display: Off)
White Balance: 5600K (manual Kelvin)
ISO: 640
Aperture: f/4.0
Shutter: 1/125

Picture Profile: PP Off (neutral for matching)
Creative Style: Standard
Contrast: 0
Saturation: 0
Sharpness: 0

Focus: Continuous AF (Face/Eye AF enabled for presenter tracking)
Image Stabilization: Off (tripod mounted; OSS disabled saves battery)

Power: AC-PW20 AC adapter
Memory Card: Removed
```

#### Menu Navigation (Sony A6400 Specific)

```
Menu → Setup → HDMI Settings
├── HDMI Resolution: 1080p
├── HDMI Output: 4:2:2 8-bit
├── HDMI Info Display: Off
├── TC Output: Off
└── REC Control: Off

Menu → Camera → Picture Profile
└── Off (or use PP1 set to neutral values)

Menu → Camera → AF → Face/Eye AF
├── Face/Eye AF Set: On
├── Face Dtct Frm Disp: Off (no overlay on HDMI)
└── Subject: Human

Menu → Setup → Power Setting
├── Auto Pwr OFF Temp: High
└── Auto Power Off: Off
```

#### Notes

- Sony's "High" temperature threshold allows longer runtime before overheating
- Face/Eye AF works well for presenters who move; keep detection frame overlay off
- PP Off provides most neutral image for multi-camera matching
- USB power delivery does not work during HDMI output; must use AC adapter
- Clean HDMI verified with DeckLink at 1080p60

---

### Camera 3: <!-- TODO: Model Name -->

**Role:** <!-- TODO -->
**Position:** <!-- TODO -->
**Lens:** <!-- TODO -->

#### Settings

```
Resolution: 1080p60
HDMI Output: Clean
White Balance: 5600K
ISO: 800
Aperture: f/4.0
Shutter: 1/120

Picture Profile: Standard
Contrast: 0
Saturation: 0
Sharpness: 0

Focus: Manual / Continuous
Image Stabilization: Off

Power: AC adapter
```

#### Notes

-
-

---

### Camera 4: <!-- TODO: Model Name -->

**Role:** <!-- TODO -->
**Position:** <!-- TODO -->
**Lens:** <!-- TODO -->

#### Settings

```
Resolution: 1080p60
HDMI Output: Clean
White Balance: 5600K
ISO: 800
Aperture: f/4.0
Shutter: 1/120

Picture Profile: Standard
Contrast: 0
Saturation: 0
Sharpness: 0

Focus: Manual / Continuous
Image Stabilization: Off

Power: AC adapter
```

#### Notes

-
-

---

## Brand-Specific Settings

### Sony Cameras

**HDMI Output Settings:**
```
Menu → Setup → HDMI Settings
├── HDMI Resolution: 1080p
├── HDMI Output: No Info Display
├── TC Output: Off
└── REC Control: Off
```

**Picture Profile (Neutral):**
```
Menu → Camera → Picture Profile
├── PP Off (or)
└── PP1 with:
    ├── Black Level: 0
    ├── Gamma: Still
    ├── Color Mode: Standard
    └── Saturation: 0
```

### Canon Cameras

**HDMI Output Settings:**
```
Menu → Wrench/Setup → Video System
├── HDMI output: 1080p
Menu → Wrench/Setup → HDMI Output
├── Info Display: Off
└── Clean HDMI: On
```

**Picture Style:**
```
Menu → Camera → Picture Style
└── Standard or Neutral
```

### Panasonic Cameras

**HDMI Output Settings:**
```
Menu → Setup → TV Connection
├── HDMI Mode: 1080p
├── Info Display: Off
└── Down Convert: Off
```

**Photo Style:**
```
Menu → Rec → Photo Style
└── Standard or Natural
```

### Blackmagic Cameras

**HDMI Output:**
```
Menu → Setup → Monitor
├── Clean Feed: On
├── Status Text: Off
└── Frame Guides: Off
```

---

## Pre-Show Camera Checklist

Run through this checklist for each camera before streaming:

- [ ] Power: AC adapter connected (not battery)
- [ ] Memory card: Removed or formatted (prevents recording prompt)
- [ ] HDMI: Clean output confirmed (no overlays)
- [ ] Resolution: Matches OBS/DeckLink setting
- [ ] White balance: Manual, matches all cameras
- [ ] Exposure: Manual or locked, levels matched
- [ ] Focus: Set and locked (or AF configured)
- [ ] Audio: Disabled or confirmed muted on camera
- [ ] Auto power-off: Disabled
- [ ] Recording: Not actively recording

---

## Color Matching Procedure

### Initial Setup (One Time)

1. Set up all cameras pointing at same grey card
2. Match white balance exactly (use Kelvin value)
3. Set identical exposure (ISO, aperture, shutter)
4. Set identical picture profile settings
5. Take screenshot of each camera's output in OBS
6. Adjust picture profile if needed to match

### Quick Match (Per Session)

1. Verify white balance matches (same lighting)
2. Check exposure levels (waveform/histogram)
3. Quick A/B switch between cameras to verify

### Post-Production (If Needed)

For recordings that need color correction:
1. Apply same base correction to all cameras
2. Fine-tune individual clips as needed
3. Use scopes (waveform, vectorscope)

---

## Troubleshooting

### Cameras Look Different When Switching

1. Check white balance (most common cause)
2. Check exposure/brightness levels
3. Compare picture profiles
4. Verify same resolution/frame rate

### HDMI Showing Overlays

1. Find "HDMI Info Display" or "Clean HDMI" setting
2. Disable all overlays, guides, histograms
3. May need to disable record indicator

### Camera Overheating

1. Use AC power (reduces heat from charging)
2. Remove memory card (reduces internal recording heat)
3. Ensure ventilation around camera
4. Consider camera cooling fan for long sessions

### Auto Power-Off During Stream

1. Find "Auto Power Off" setting, set to OFF
2. Use AC adapter (some cameras won't sleep on AC)
3. Set LCD timeout but not camera power-off

---

## See Also

- [VIDEO-CAPTURE.md](../docs/VIDEO-CAPTURE.md) - DeckLink configuration
- [COMPATIBILITY.md](COMPATIBILITY.md) - Tested camera models
- [RUNBOOK.md](../docs/RUNBOOK.md) - Pre-stream checklist

---

*Document maintained by Multi-Camera Livestream Framework team*
