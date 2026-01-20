# System Architecture

**Generated from profile:** studio
**Last Updated:** 2026-01-20

## High-Level Overview

This pipeline ingests 4K video from DSLR/mirrorless cameras, synchronizes audio via Dante network, enables low-latency NDI caller integration, and outputs to streaming platforms (YouTube, Twitch) via OBS.

**Design principle**: Separation of concerns — capture, sync, mixing, output are independent subsystems connected via standardized protocols (HDMI, Dante, NDI, RTMP).

## Signal Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ INPUT LAYER                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Cameras (HDMI)              Cameras (Audio)                │
│  ├─ [Camera 1]               ├─ USB or XLR                 │
│  ├─ [Camera 2]               └─ Dante converters           │
│  ├─ [Camera 3]                                              │
│  └─ [Camera 4]               Callers (Remote)              │
│       ↓                        └─ NDI OBS stream           │
│                      │
│  ()        │
│       ↓                                                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ CAPTURE LAYER ()          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                │
│  ├─ Scene 1: Camera quad (4K mosaic)                       │
│  ├─ Scene 2: Single camera + caller                        │
│  ├─ Scene 3: Screen share (graphics)                       │
│  └─ Audio Input:  │
│                    │
│                                                             │
│  Dante Network (audio sync)                                │
│  ├─  (Dante I/O)  │
│  ├─ Dante AVIO nodes (camera audio converters)             │
│  └─ Sample clock: 48 kHz (broadcast standard)              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ PROCESSING LAYER                                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   (audio mixing)   │
│  ├─ Input: Camera feeds (via Dante)                        │
│  ├─ Master clock: Drives all Dante devices                 │
│  └─ Output: Master mix → Audio Interface → OBS             │
│                                                             │
│   (optional)      │
│  ├─ Input: Generative parameters (MIDI from DAW)          │
│  └─ Output: Screen share → OBS                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ OUTPUT / ENCODING LAYER                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  OBS Encoder (H.264 or H.265)                              │
│  ├─ Video bitrate: 8–25 Mbps (codec-dependent)             │
│  ├─ Resolution: 4K or 1080p mosaic                         │
│  └─ Framerate: 30fps or 60fps                              │
│       ↓                                                      │
│  RTMP Output (streaming protocol)                          │
│       ↓                                                      │
├─────────────────────────────────────────────────────────────┤
│ DISTRIBUTION LAYER                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Streaming Platforms:                                       │
│  ├─ YouTube                   │
│  └─ Twitch                    │
│                                                             │
│  Archive & Analytics:                                       │
│  ├─ Local recording (OBS → H.264 file)                     │
│  └─ Optional: Cloud backup of raw recordings               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Capture Subsystem (HDMI + Video Capture)

- ****: 4× HDMI input, outputs to PCIe
- ****: thunderbolt3 enclosure, PCIe slot for capture card
- **Protocol**: Uncompressed HDMI or HDCP-encrypted video
- **Latency**: <1ms (hardware-based capture)
- **Bandwidth**: ~1.5 Gbps per 4K30 stream

### 2. Audio Synchronization (Dante)

**Why Dante?**
- All audio sources share a **global sample clock**
- Avoids drift between video and audio
- Supports flexible routing without hardware reconfiguration
- Industry standard for broadcast

**Components**:
- **Dante Network**: Dedicated managed Ethernet switch
- ****: 24 in / 28 out channels
- ****: Acts as Dante clock master

### 3. Computer System

| Specification | Value |
|--------------|-------|
| Model |  |
| Chip |  |
| RAM |  GB |
| OS |   |

### 4. Network Configuration

| Interface | Purpose |
|-----------|---------|
| en0 | Primary network (streaming) |
| Dante Network | Dedicated audio network |

## Operational Thresholds

| Parameter | Value |
|-----------|-------|
| Minimum Disk Space | 50 GB |
| Recommended Disk Space | 100 GB |
| Max CPU Usage | 70% |
| Min Memory Free | 20% |

---

*This document was generated from profile: **studio***
