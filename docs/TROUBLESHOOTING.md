# Troubleshooting Guide

> Decision-tree format troubleshooting for common issues in the Multi-Camera Livestream Framework.

**Last Updated:** 2025-01-20
**Version:** 1.0.0

---

## Quick Navigation

- [No Video Signal](#no-video-signal)
- [No Audio](#no-audio)
- [Audio Sync Issues](#audio-sync-issues)
- [Dropped Frames](#dropped-frames)
- [Stream Disconnection](#stream-disconnection)
- [Software Crashes](#software-crashes)
- [Hardware Issues](#hardware-issues)
- [Network Problems](#network-problems)
- [Emergency Recovery](#emergency-recovery)
- [What If X Fails?](#what-if-x-fails-mid-stream-failure-scenarios)
- [Backup & Failover Procedures](#backup--failover-procedures)

---

## No Video Signal

```
Camera not showing in OBS?
│
├─ Is the camera powered on?
│  ├─ No → Power on camera
│  └─ Yes → Continue
│
├─ Is HDMI cable connected at both ends?
│  ├─ No → Connect cable securely
│  └─ Yes → Continue
│
├─ Does camera show signal on its LCD?
│  ├─ No → Check camera settings, ensure HDMI output enabled
│  └─ Yes → Continue
│
├─ Is Echo Express chassis powered?
│  ├─ No → Power on chassis, wait 30 seconds
│  └─ Yes → Continue
│
├─ Does Desktop Video Setup show signal?
│  ├─ No → DeckLink not detecting signal
│  │  ├─ Try different HDMI input on DeckLink
│  │  ├─ Try different HDMI cable
│  │  └─ Restart Echo Express chassis
│  └─ Yes → Continue
│
├─ Is OBS source configured correctly?
│  ├─ Check source properties match camera format
│  ├─ Try removing and re-adding source
│  └─ Verify correct DeckLink input selected
│
└─ Still not working?
   ├─ Restart OBS
   ├─ Restart Mac Studio
   └─ Check COMPATIBILITY.md for known issues
```

---

## No Audio

```
No audio in OBS/stream?
│
├─ Check: Where is audio expected from?
│  ├─ Dante/MOTU → Go to Dante Audio Path
│  └─ HDMI embedded → Go to HDMI Audio Path
│
├─ DANTE AUDIO PATH
│  ├─ Is MOTU 8PRE-ES powered on?
│  │  ├─ No → Power on, wait for boot (LEDs stabilize)
│  │  └─ Yes → Continue
│  │
│  ├─ Does Dante Controller show MOTU?
│  │  ├─ No → Check Ethernet connection to Dante switch
│  │  └─ Yes → Continue
│  │
│  ├─ Is audio routing configured in Dante Controller?
│  │  ├─ No → Configure routing matrix
│  │  └─ Yes → Continue
│  │
│  ├─ Does Ableton receive audio?
│  │  ├─ No → Check Ableton audio preferences
│  │  │  ├─ Correct audio device selected?
│  │  │  └─ Correct input channels enabled?
│  │  └─ Yes → Continue
│  │
│  └─ Does OBS receive audio from Ableton?
│     ├─ Check virtual audio cable routing
│     └─ Check OBS audio mixer levels
│
├─ HDMI AUDIO PATH (if using)
│  ├─ Is camera set to output audio via HDMI?
│  ├─ Is OBS source configured to capture audio?
│  └─ Check OBS audio mixer for HDMI source
│
└─ Still no audio?
   ├─ Restart Dante Controller
   ├─ Restart Ableton Live
   ├─ Check macOS Sound preferences
   └─ Verify no mutes active anywhere in chain
```

---

## Audio Sync Issues

```
Audio out of sync with video?
│
├─ Is audio ahead or behind video?
│  ├─ AHEAD → Add positive sync offset in OBS
│  └─ BEHIND → Add negative sync offset in OBS
│
├─ How to adjust in OBS:
│  ├─ Right-click audio source in Mixer
│  ├─ Advanced Audio Properties
│  └─ Adjust Sync Offset (ms)
│     ├─ Start with ±50ms increments
│     └─ Test with clap test
│
├─ Is sync consistent or drifting?
│  ├─ DRIFTING → Clock sync issue
│  │  ├─ Check Dante clock master (MOTU should be master)
│  │  ├─ Verify all devices same sample rate (48kHz)
│  │  └─ Check for multiple clock masters
│  └─ CONSISTENT → Static offset, adjust and done
│
├─ Sync only affects certain sources?
│  ├─ Check individual source sync offsets
│  ├─ Check processing delays in Ableton
│  └─ Verify source formats match (frame rate)
│
└─ Sync keeps changing?
   ├─ Check CPU load (processing delays vary with load)
   ├─ Simplify Ableton project
   └─ Use hardware monitoring where possible
```

---

## Dropped Frames

```
OBS showing dropped frames?
│
├─ Check OBS Stats (View → Stats)
│
├─ Which type of drops?
│  │
│  ├─ "Frames missed due to rendering lag"
│  │  ├─ GPU is overloaded
│  │  ├─ Simplify scenes (fewer sources, effects)
│  │  ├─ Lower preview resolution
│  │  └─ Close other GPU-intensive apps
│  │
│  ├─ "Skipped frames due to encoding lag"
│  │  ├─ Encoder can't keep up
│  │  ├─ Switch to hardware encoder (Apple VT)
│  │  ├─ Use faster x264 preset
│  │  ├─ Lower output resolution
│  │  └─ Lower frame rate
│  │
│  └─ "Dropped frames due to network issues"
│     ├─ Upload can't sustain bitrate
│     ├─ Lower bitrate
│     ├─ Check network connection (use wired)
│     ├─ Test upload speed
│     └─ Check for network congestion
│
├─ Drops only during specific actions?
│  ├─ Scene transitions → Simplify transitions
│  ├─ Certain scenes → Check those scene sources
│  └─ After time passes → Memory leak, restart OBS
│
└─ Consistent drops throughout?
   ├─ System resources insufficient
   ├─ Check Activity Monitor
   ├─ Close unnecessary applications
   └─ Consider hardware upgrade
```

---

## Stream Disconnection

```
Stream keeps disconnecting?
│
├─ How frequently?
│  ├─ Every few seconds → Severe network issue
│  ├─ Every few minutes → Moderate network issue
│  └─ Random/rare → Intermittent issue
│
├─ Check OBS connection status
│  ├─ View → Stats → check connection indicator
│  └─ Check log for disconnect reasons
│
├─ Network checks:
│  ├─ Using wired Ethernet?
│  │  └─ No → Switch to wired immediately
│  ├─ Run speed test during issue
│  ├─ Check for packet loss: ping -c 100 8.8.8.8
│  └─ Check router/modem status lights
│
├─ Platform-specific:
│  ├─ Try different RTMP server
│  ├─ Check platform status page
│  └─ Re-copy stream key (may have expired)
│
├─ OBS settings:
│  ├─ Enable "Automatically Reconnect"
│  ├─ Lower bitrate (reduce network stress)
│  └─ Increase retry delay
│
└─ Still disconnecting?
   ├─ Contact ISP
   ├─ Try streaming from different network
   └─ Use cellular hotspot as emergency backup
```

---

## Software Crashes

### OBS Crashes

```
OBS crashes or freezes?
│
├─ When does it crash?
│  ├─ On startup → Config corruption
│  │  ├─ Delete scene collection, rebuild
│  │  └─ Reset OBS profile
│  │
│  ├─ When adding source → Plugin issue
│  │  ├─ Disable recently added plugins
│  │  └─ Check plugin compatibility
│  │
│  ├─ During stream → Resource issue
│  │  ├─ Check memory usage
│  │  ├─ Simplify scenes
│  │  └─ Update OBS
│  │
│  └─ Random → Various causes
│     ├─ Check Console.app for crash logs
│     └─ Update macOS and OBS
│
└─ OBS frozen but not crashed?
   ├─ Wait 60 seconds (might be processing)
   ├─ Force quit: Cmd+Option+Esc
   └─ Kill via terminal: pkill -9 obs
```

### Ableton Crashes

```
Ableton crashes or freezes?
│
├─ When does it crash?
│  ├─ Opening project → Corrupt project
│  │  ├─ Try opening Auto-Backup version
│  │  └─ Create new project, import tracks
│  │
│  ├─ During audio playback → Plugin issue
│  │  ├─ Open project with plugins disabled (hold Option on load)
│  │  ├─ Enable plugins one by one to find culprit
│  │  └─ Update/replace problematic plugin
│  │
│  └─ Randomly → Resource issue
│     ├─ Increase audio buffer size
│     └─ Freeze/flatten heavy tracks
│
└─ Audio dropouts in Ableton?
   ├─ Increase buffer size (Preferences → Audio)
   ├─ Reduce sample rate (48kHz → 44.1kHz)
   └─ Close other audio apps
```

---

## Hardware Issues

### DeckLink Not Detected

```
DeckLink card not recognized?
│
├─ Check System Report → Thunderbolt
│  ├─ Is Echo Express listed?
│  │  ├─ No → Thunderbolt connection issue
│  │  │  ├─ Check cable connection
│  │  │  ├─ Try different TB port
│  │  │  └─ Power cycle chassis
│  │  └─ Yes → Continue
│  │
│  └─ Is DeckLink listed under PCI?
│     ├─ No → Card not seated properly or driver issue
│     │  ├─ Reseat card in chassis (power off first!)
│     │  └─ Reinstall Desktop Video drivers
│     └─ Yes → Card detected, check OBS sources
│
└─ After macOS update?
   ├─ Check for updated Desktop Video drivers
   ├─ Grant permissions in System Preferences → Privacy
   └─ May need to allow system extension
```

### MOTU Not Responding

```
MOTU 8PRE-ES issues?
│
├─ Front panel LEDs status?
│  ├─ No LEDs → No power
│  │  └─ Check power connection
│  ├─ Flashing LEDs → Booting or error
│  │  └─ Wait for stable state or power cycle
│  └─ Stable LEDs → Powered, continue
│
├─ Not visible in Dante Controller?
│  ├─ Check Ethernet cable
│  ├─ Verify switch connection
│  ├─ Try direct connection to Mac
│  └─ Power cycle MOTU
│
├─ Audio issues?
│  ├─ Check input gain (preamp knobs)
│  ├─ Verify phantom power if needed (+48V)
│  └─ Check web interface for detailed status
│
└─ Clock sync errors?
   ├─ Verify MOTU is set as clock master
   └─ Check sample rate consistency
```

---

## Network Problems

### Dante Network Issues

```
Dante network not working?
│
├─ Dante Controller shows no devices?
│  ├─ Firewall blocking? → Allow Dante Controller
│  ├─ Correct network interface? → Check settings
│  └─ Devices on same subnet? → Verify IP addresses
│
├─ Audio dropouts on Dante?
│  ├─ Check clock sync status (should be green)
│  ├─ Check switch for errors
│  ├─ Try different Dante latency setting
│  └─ Verify dedicated Dante network (no other traffic)
│
└─ Device shows red status?
   ├─ Clock sync error → Check clock master config
   ├─ Network error → Check physical connection
   └─ Device error → Power cycle device
```

### Internet Connectivity

```
Internet connection issues?
│
├─ Complete outage?
│  ├─ Check other devices
│  ├─ Check modem/router
│  └─ Contact ISP
│
├─ Slow/intermittent?
│  ├─ Run speed test
│  ├─ Check for local congestion
│  └─ Try different DNS (8.8.8.8, 1.1.1.1)
│
└─ Stream-specific issues?
   ├─ Platform status page shows issues?
   ├─ Try different RTMP server
   └─ Lower bitrate
```

---

## Emergency Recovery

### Mid-Stream Emergency

If something fails during a live stream:

1. **Stay calm** - Viewers will wait briefly
2. **Keep audio rolling** if possible (apologize, explain technical difficulties)
3. **Don't end stream** unless absolutely necessary

#### Quick Recovery Actions

| Issue | Quick Fix | Time |
|-------|-----------|------|
| OBS frozen | Force quit, relaunch | 30-60 sec |
| Video source gone | Remove/re-add source | 15-30 sec |
| Audio gone | Check mutes, restart source | 15-30 sec |
| Stream dropped | OBS auto-reconnects | 5-15 sec |
| Complete system hang | Restart Mac | 2-3 min |

#### Emergency Hotkeys

Configure in OBS Settings → Hotkeys:

| Hotkey | Action |
|--------|--------|
| F1 | Switch to safe scene (static image) |
| F2 | Mute all audio |
| F3 | Start/stop streaming |
| F4 | Start/stop recording |

### Post-Incident

After any significant issue:

1. Document what happened (software/templates/incident-report.md)
2. Review logs
3. Identify root cause
4. Update troubleshooting docs
5. Add preventive checks to RUNBOOK

---

## What If X Fails? (Mid-Stream Failure Scenarios)

This section documents what happens when critical components fail during a live stream and the recovery procedures.

### What if the Mac Studio crashes?

**Symptom:** Complete black screen or system freeze, stream goes offline immediately.

**Impact:** CRITICAL - Complete stream loss, all software terminates.

**Immediate Actions:**
1. Stream automatically ends (viewers see platform's "offline" screen)
2. Power button: Hold for 5 seconds to force shutdown
3. Wait 10 seconds, then power on
4. Recovery time: 2-3 minutes to full streaming capability

**Recovery Procedure:**
```
1. Mac boots → Login (auto-login recommended for production)
2. Run: ./software/scripts/launch-studio.sh
3. OBS: Click "Start Streaming" (scene should restore from profile)
4. Ableton: May need to reopen project and arm tracks
5. Dante: Usually auto-reconnects (verify routing in Dante Controller)
```

**Prevention:**
- Run health check before every stream
- Monitor CPU/GPU temps (>80°C = warning)
- Ensure adequate cooling and airflow
- Keep macOS and apps updated

---

### What if OBS crashes?

**Symptom:** OBS window disappears, stream drops after buffer timeout (5-30 seconds).

**Impact:** MAJOR - Stream interruption, but other systems remain running.

**Immediate Actions:**
1. Relaunch OBS immediately: `open -a "OBS"`
2. OBS restores last scene collection automatically
3. Click "Start Streaming"
4. Recovery time: 30-60 seconds

**What happens to viewers:**
- Platform shows "offline" or frozen frame during gap
- VOD recording may have gap (check OBS recording separately)

**Prevention:**
- Simplify scenes (fewer sources = fewer crash vectors)
- Update OBS to latest stable version
- Disable unused plugins
- Monitor memory usage during stream

---

### What if Ableton crashes?

**Symptom:** Audio stops, Ableton window closes, OBS audio meters drop to zero.

**Impact:** MAJOR - No audio to stream, but video continues.

**Immediate Actions:**
1. Stream continues with video but no audio
2. Consider muting OBS audio to avoid dead air
3. Relaunch Ableton: `open -a "Ableton Live 12 Standard"`
4. Recovery time: 45-90 seconds

**Recovery Procedure:**
```
1. Relaunch Ableton
2. Open streaming project (Recent → your project)
3. Arm input tracks for live monitoring
4. Verify Dante routing restored (Dante Controller)
5. Verify virtual audio cable to OBS (check OBS mixer)
```

**Workaround:** If Ableton won't recover:
- Route MOTU directly to OBS (bypass Ableton processing)
- Use OBS's direct audio input until resolved

---

### What if the DeckLink card fails?

**Symptom:** One or more video sources show black in OBS, Desktop Video Setup shows no signal.

**Impact:** MAJOR to CRITICAL - Partial or total video loss.

**Immediate Actions:**
1. Switch to remaining working cameras in OBS
2. If all inputs fail, switch to backup scene (graphics, pre-recorded content)

**Recovery Attempts (in order):**
```
1. Try different HDMI input on DeckLink (may be single port failure)
2. Reseat HDMI cables at both ends
3. Check Echo Express power/connection
4. Restart OBS (releases and re-acquires device)
5. Last resort: Restart Mac (re-initializes Thunderbolt devices)
```

**What this means:**
- Single input failure: Switch to working cameras, stream continues
- Complete card failure: Need backup video source or pre-recorded content

---

### What if MOTU/Dante fails?

**Symptom:** Audio disappears, Dante Controller shows device offline or clock errors.

**Impact:** MAJOR - No audio from Dante sources.

**Immediate Actions:**
1. Video continues, but audio is silent
2. Check MOTU front panel (LEDs indicate status)
3. If complete failure, consider alternative audio source

**Recovery Procedure:**
```
1. Power cycle MOTU (off for 10 seconds, then on)
2. Wait 30-60 seconds for Dante to reconnect
3. Verify clock sync in Dante Controller (green status)
4. Verify routing matrix is restored
5. Check Ableton is receiving audio
```

**Alternative Audio Sources:**
- Camera HDMI audio (embedded in video signal)
- USB microphone directly to Mac
- iPhone as wireless mic via built-in mic app

---

### What if the network/internet fails?

**Symptom:** OBS shows "Disconnected" or high dropped frames, stream goes offline on platform.

**Impact:** CRITICAL for live delivery, but local recording continues.

**Immediate Actions:**
1. OBS auto-reconnects by default (check settings)
2. Verify local recording is active (audience can watch VOD)
3. Check network equipment (router, modem lights)

**Recovery Options:**
```
1. Wait for auto-reconnect (OBS retries every 10 seconds)
2. If ISP is down, switch to cellular hotspot:
   - iPhone Personal Hotspot (USB tethering preferred over WiFi)
   - Lower bitrate to 2500kbps for cellular
3. If switch/router failed, try direct connection to modem
```

**Audience Communication:**
- If you have a second device, post on social media: "Technical difficulties, back soon"
- Use platform's chat to communicate (if accessible from another device)

---

### What if a camera fails?

**Symptom:** Single source in OBS shows black or frozen, other cameras continue.

**Impact:** MINOR to MODERATE - One angle lost.

**Immediate Actions:**
1. Switch to working cameras using scene transitions
2. Do not draw attention to the failure (viewers may not notice)

**Recovery Attempts:**
```
1. Check camera power (battery died? AC adapter disconnected?)
2. Check camera LCD (is it on? showing error?)
3. Check HDMI cable connection at camera end
4. Power cycle camera (may need 30 seconds to re-establish HDMI)
```

**If camera won't recover:**
- Continue with remaining cameras
- Adjust framing on other cameras to compensate
- In OBS, remove the broken source to avoid accidental cut to black

---

### What if the Dante clock drifts/fails?

**Symptom:** Audio gradually drifts out of sync with video, clicking/popping sounds, audio dropouts.

**Impact:** MODERATE - Degraded audio quality.

**Diagnosis:**
```
Open Dante Controller:
- Check clock master status (should be green)
- Look for multiple devices claiming master (conflict)
- Verify sample rate consistency (all devices 48kHz)
```

**Immediate Actions:**
1. In OBS, adjust audio sync offset as temporary fix
2. If clicking/popping, mute affected audio until resolved

**Recovery:**
```
1. Identify clock master (should be MOTU)
2. Remove competing clock masters from config
3. If MOTU is not master:
   - In Dante Controller, set MOTU as Preferred Master
   - Power cycle any devices fighting for master
```

**Prevention:**
- Configure clock hierarchy before stream
- Only one device should be clock master
- Document clock configuration in your setup notes

---

### Failure Priority Matrix

| Component | Stream Impact | Recovery Time | Backup Strategy |
|-----------|---------------|---------------|-----------------|
| Mac Studio | CRITICAL | 2-3 min | Second computer ready |
| OBS | MAJOR | 30-60 sec | OBS auto-restores scenes |
| Ableton | MAJOR | 45-90 sec | Direct MOTU→OBS routing |
| DeckLink | MAJOR-CRITICAL | 1-2 min | USB capture device |
| MOTU/Dante | MAJOR | 60 sec | Camera HDMI audio |
| Network | CRITICAL | Variable | Cellular hotspot |
| Single Camera | MINOR | 30 sec | Use other angles |
| Dante Clock | MODERATE | 30-60 sec | Restart Dante devices |

---

## Backup & Failover Procedures

This section documents proactive backup strategies to minimize impact when failures occur.

### Pre-Stream Backup Preparation

#### 1. Recording Backup (Always Active)

Always record locally in addition to streaming:

```
OBS Settings → Output → Recording:
├── Recording Path: External SSD (not boot drive)
├── Recording Format: MKV (survives crashes better than MP4)
├── Encoder: Apple VT H.265 (efficient, low CPU)
└── Recording Quality: High Quality, Large File Size
```

**Why MKV?** If OBS crashes, MKV files are recoverable. MP4 requires proper finalization and may be corrupt if OBS crashes.

**Post-stream:** Remux MKV to MP4 via `File → Remux Recordings`.

#### 2. Backup Stream Destination

Configure a backup stream destination that activates if primary fails:

```
OBS Settings → Stream:
├── Primary: YouTube Live
└── (Advanced) Enable backup via Restream.io or similar

Alternative: Run two OBS instances to different platforms
├── OBS 1 → YouTube (primary)
└── OBS 2 → Twitch (backup) [lower bitrate]
```

**Warning:** Dual-streaming doubles upload bandwidth requirements.

#### 3. Emergency Scene Setup

Create a "Technical Difficulties" scene in OBS:

```
Scene: [Emergency - Tech Difficulties]
├── Source: Static image with "We'll be right back" message
├── Source: Looping background music (royalty-free)
└── Hotkey: F1 (instant access)

Use when:
├── All cameras fail
├── Need time to diagnose issue
└── Presenter needs to step away
```

#### 4. Backup Audio Path

Configure fallback audio routing:

```
Primary Path:   Mics → MOTU 8PRE-ES → Dante → Ableton → OBS
Backup Path 1:  Mics → MOTU 8PRE-ES → USB → Mac → OBS (bypass Dante)
Backup Path 2:  Camera HDMI audio → DeckLink → OBS (embedded audio)
Backup Path 3:  USB Microphone → Mac → OBS (last resort)
```

**Quick Switch:**
1. In OBS, add backup audio sources (muted by default)
2. If primary fails, mute primary → unmute backup
3. Hotkey recommended: F5 = Toggle backup audio

#### 5. Backup Video Source

Configure fallback video:

```
Backup Options:
├── Second capture device (USB capture card) as backup input
├── Pre-recorded video loop (always have B-roll loaded)
├── Static slides/graphics (keeps visual interest)
└── Screen share (if presenting from computer)
```

### Failover Procedures by Scenario

#### Scenario A: Primary Computer Fails

**Setup (before stream):**
1. Backup laptop with OBS installed and configured
2. Stream key copied to backup laptop
3. USB capture card connected to backup laptop
4. Backup laptop on same network

**Failover Steps:**
1. Primary crashes → start backup laptop OBS
2. Connect one camera to USB capture card
3. Start streaming from backup (reduced quality, single camera)
4. Notify viewers if significant delay

**Practice:** Run failover drill quarterly.

#### Scenario B: Internet Fails

**Preparation:**
1. Cellular hotspot ready (phone charged, Personal Hotspot enabled)
2. USB-C cable for tethering (more reliable than WiFi)
3. Know your cellular upload speed (test beforehand)
4. Pre-configure lower bitrate profile: 2000-3000 kbps

**Failover Steps:**
```
1. OBS will auto-reconnect (wait 30 seconds)
2. If not recovered:
   └─ System Preferences → Network → Enable iPhone tether
3. OBS → Settings → Stream → Use cellular-friendly bitrate
4. Click "Start Streaming"
```

**Note:** Inform viewers of potentially reduced quality.

#### Scenario C: Audio System Fails Completely

**Immediate Response:**
1. Switch to emergency scene (hide that you're troubleshooting)
2. Enable camera HDMI audio in OBS
3. Or plug USB microphone directly into Mac
4. Return to live scene with backup audio

**Emergency USB Mic Setup (pre-configure):**
```
OBS Audio Sources:
├── [Dante Master] - Primary (enabled)
├── [USB Backup Mic] - Disabled by default
└── [HDMI Embedded Audio] - Disabled by default
```

#### Scenario D: All Cameras Fail

**Immediate Response:**
1. Switch to emergency scene
2. Enable screen share or slides
3. Continue with audio-only + visuals
4. Troubleshoot cameras in background

**Screen Share Backup:**
```
OBS Sources (pre-configured):
├── Scenes with cameras (primary)
└── Scene: [Backup - Screen Share]
    ├── Display Capture or Window Capture
    └── Works even with no cameras
```

### Backup Hardware Checklist

Keep this backup equipment ready:

| Item | Purpose | Location |
|------|---------|----------|
| USB Capture Card (Elgato Cam Link or similar) | Backup video input | Equipment bag |
| USB Microphone | Backup audio | Equipment bag |
| Phone Hotspot + USB-C cable | Backup internet | Always charged |
| HDMI cables (2 extra) | Cable failure | Equipment bag |
| Power strips + extension cords | Power backup | Under desk |
| Laptop with OBS | Full system backup | Charged, nearby |

### Automated Health Monitoring

Run health check during stream (every 30 minutes):

```bash
# Quick mid-stream check (non-intrusive)
./software/scripts/health-check.sh --quiet

# Output warning if issues detected:
# - Disk space < 20GB
# - CPU temp > 80°C
# - Memory > 90%
```

**Recommended:** Set a recurring timer to check health during long streams.

### Recovery Time Objectives (RTO)

Target recovery times for different failure modes:

| Failure | Target RTO | Achieved By |
|---------|------------|-------------|
| OBS crash | < 60 sec | Auto-restore scenes, quick relaunch |
| Audio loss | < 30 sec | Backup audio sources pre-configured |
| Single camera loss | < 15 sec | Scene without that camera |
| Internet loss | < 2 min | Hotspot failover |
| Complete system failure | < 5 min | Backup laptop procedure |

### Monthly Failover Drill

Practice failover procedures monthly:

```
Drill Checklist:
□ Simulate OBS crash → relaunch and verify recovery
□ Test backup audio path → mute primary, enable backup
□ Test hotspot failover → disconnect Ethernet, enable cellular
□ Test backup laptop → start stream from secondary machine
□ Time each recovery → record in incident log
□ Update procedures if issues found
```

---

## Collecting Diagnostic Information

### For Bug Reports

Gather this information:

```bash
# macOS version
sw_vers

# OBS version
/Applications/OBS.app/Contents/MacOS/OBS --version

# Check running processes
ps aux | grep -E "(obs|ableton|dante)"

# System load
top -l 1 -n 0 | head -10

# Disk space
df -h /

# Network interfaces
ifconfig | grep -E "^[a-z]|inet "
```

### OBS Logs

Location: `~/Library/Application Support/obs-studio/logs/`

### Crash Reports

Location: `~/Library/Logs/DiagnosticReports/`

---

## See Also

- [RUNBOOK.md](RUNBOOK.md) - Pre-stream checklist (prevents many issues)
- [AUDIO-DANTE.md](AUDIO-DANTE.md) - Dante-specific troubleshooting
- [VIDEO-CAPTURE.md](VIDEO-CAPTURE.md) - Video-specific troubleshooting
- [STREAMING.md](STREAMING.md) - Streaming-specific troubleshooting

---

*Document maintained by Multi-Camera Livestream Framework team*
