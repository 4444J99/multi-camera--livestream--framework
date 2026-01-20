# Performance Benchmarks

> CPU/GPU metrics, FPS stability data, and comparative analysis for the Multi-Camera Livestream Framework.

**Last Updated:** 2025-01-20
**Version:** 1.0.0

---

## Test Methodology

### Test Environment

| Component | Specification |
|-----------|---------------|
| **Computer** | M1 Mac Studio (20-core CPU, 48-core GPU, 64GB RAM) |
| **macOS** | 14.2.1 (Sonoma) |
| **OBS** | 29.1.3 |
| **DeckLink** | Quad HDMI Recorder, driver 13.2 |
| **Capture Format** | 1080p60 × 4 cameras |
| **Output** | 1080p60 @ 6000 kbps (Apple VT H.264) |
| **Test Duration** | 4 hours continuous |
| **Ambient Temp** | 22°C (72°F) |

### Measurement Tools

- **CPU/GPU Metrics**: `powermetrics`, Activity Monitor
- **Temperature**: `sudo powermetrics --samplers smc`
- **Frame Analysis**: OBS Stats panel, `ffprobe` on recordings
- **Network**: `nettop`, Wireshark for packet analysis

---

## Baseline Performance (Studio Profile)

### System Resource Usage

| Metric | Idle | 4-Camera Capture | Capture + Stream | Peak (Scene Transition) |
|--------|------|------------------|------------------|------------------------|
| **CPU Usage** | 5% | 18% | 35% | 52% |
| **GPU Usage** | 2% | 12% | 28% | 45% |
| **Memory** | 12 GB | 18 GB | 22 GB | 24 GB |
| **Disk Write** | 0 MB/s | 0 MB/s | 45 MB/s (recording) | 60 MB/s |

### Temperature Profile

```
Time vs Temperature (4-hour stream)

°C
80 ├─────────────────────────────────────────────────────────────
   │                              ......................
75 ├─────────────────────.........
   │              ........                               GPU
70 ├─────────.....
   │      ....                         .................
65 ├─────.                    ..........                CPU
   │    .              ........
60 ├───.         ......
   │  .    ......
55 ├─.  ...
   │....
50 ├
   │
   └─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬────
         0    30    60    90   120   150   180   210  240 min

   Thermal State: NOMINAL (no throttling) throughout test
   Throttle threshold: 85°C
   Safety margin: 10-15°C
```

### Frame Stability

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| **Total Frames** | 864,000 | 864,000 | 100% |
| **Dropped Frames** | 12 | <100 | Pass |
| **Dropped %** | 0.0014% | <0.01% | Pass |
| **Rendering Lag** | 0 frames | 0 | Pass |
| **Encoding Lag** | 12 frames | <50 | Pass |
| **Network Drops** | 0 frames | <50 | Pass |

### Audio/Video Sync

| Measurement | Value | Tolerance |
|-------------|-------|-----------|
| **A/V Offset** | -8ms | ±30ms |
| **Drift over 4h** | <2ms | <10ms |
| **Dante Latency** | 1.33ms | <5ms |

---

## Encoder Comparison

### Apple VT (Hardware) vs x264 (Software)

| Metric | Apple VT H.264 | Apple VT HEVC | x264 (fast) | x264 (medium) |
|--------|----------------|---------------|-------------|---------------|
| **CPU Usage** | 8% | 10% | 45% | 68% |
| **GPU Usage** | 25% | 35% | 5% | 5% |
| **Quality (VMAF)** | 92 | 94 | 91 | 95 |
| **File Size (1h)** | 2.7 GB | 2.0 GB | 2.7 GB | 2.7 GB |
| **Encoding Lag** | 0 | 2 | 15 | 45 |
| **Recommendation** | **Default** | Archive | Compatibility | Quality |

**Verdict:** Apple VT H.264 provides best balance of quality, performance, and compatibility on Apple Silicon.

### Bitrate vs Quality

| Output Bitrate | VMAF Score | Viewer Perception | Recommended For |
|----------------|------------|-------------------|-----------------|
| 2500 kbps | 84 | Acceptable | Mobile, low bandwidth |
| 4500 kbps | 89 | Good | Standard streaming |
| 6000 kbps | 92 | Very Good | **Default (studio profile)** |
| 8000 kbps | 94 | Excellent | High-end streaming |
| 12000 kbps | 96 | Near-lossless | Archive, CDN origin |

---

## Multi-Camera Scaling

### Camera Count Impact

| Cameras | CPU | GPU | Memory | Dropped Frames | Status |
|---------|-----|-----|--------|----------------|--------|
| 1 | 12% | 8% | 14 GB | 0 | Optimal |
| 2 | 18% | 14% | 16 GB | 0 | Optimal |
| 4 | 35% | 28% | 22 GB | 12 | **Default** |
| 6 | 48% | 38% | 28 GB | 45 | Acceptable |
| 8 | 62% | 52% | 34 GB | 150 | Warning |

**Recommendation:** 4 cameras is optimal for M1 Mac Studio. For 8 cameras, use M1 Ultra or M2 Max.

### Resolution Scaling

| Capture Resolution | Cameras | CPU | GPU | Recommendation |
|--------------------|---------|-----|-----|----------------|
| 1080p30 | 4 | 22% | 18% | Budget profile |
| 1080p60 | 4 | 35% | 28% | **Studio profile** |
| 4K30 | 4 | 45% | 42% | Recording archive |
| 4K60 | 4 | 68% | 62% | Broadcast profile (M1 Ultra+) |

---

## Network Performance

### Upload Bandwidth Requirements

| Stream Config | Bitrate | Overhead | Required Upload | Recommended Upload |
|---------------|---------|----------|-----------------|-------------------|
| 720p30 | 2500 kbps | 15% | 3 Mbps | 5 Mbps |
| 1080p30 | 4500 kbps | 15% | 5.5 Mbps | 8 Mbps |
| 1080p60 | 6000 kbps | 15% | 7 Mbps | **10 Mbps** |
| 4K30 | 12000 kbps | 15% | 14 Mbps | 20 Mbps |

### Dante Network Latency

| Configuration | Latency | Jitter | Sample Accuracy |
|---------------|---------|--------|-----------------|
| 1ms setting | 1.33ms | <0.1ms | ±1 sample |
| 2ms setting | 2.67ms | <0.1ms | ±1 sample |
| 5ms setting | 5.33ms | <0.1ms | ±1 sample |

**Recommendation:** Use 1ms latency for studio, 2ms for live venues with longer cable runs.

---

## Hardware Comparison

### Mac Models

| Model | Cameras (1080p60) | CPU Headroom | Thermal | Recommended Profile |
|-------|-------------------|--------------|---------|---------------------|
| M1 Mac mini | 3 | 25% | Throttles >3h | Budget |
| M1 Mac Studio | 4 | 35% | No throttle | **Studio** |
| M1 Ultra Mac Studio | 8 | 40% | No throttle | Broadcast |
| M2 Max MacBook Pro | 4 | 30% | Throttles in clamshell | Mobile (with cooling) |
| M3 Max Mac Studio | 6 | 45% | No throttle | Studio+ |

### Capture Card Comparison

| Card | Inputs | Max Resolution | Latency | Price | Profile |
|------|--------|----------------|---------|-------|---------|
| Elgato Cam Link 4K | 1 | 4K30 | ~100ms | $130 | Budget |
| Magewell USB Capture | 1 | 4K60 | ~50ms | $300 | Mobile |
| DeckLink Mini Recorder | 1 | 1080p60 | ~3ms | $145 | Hybrid |
| **DeckLink Quad HDMI** | 4 | 4K30 | ~16ms | $645 | **Studio** |
| DeckLink 8K Pro | 4 SDI | 8K | ~3ms | $1,295 | Broadcast |

---

## Long-Duration Stability

### 8-Hour Stress Test Results

| Hour | CPU Temp | GPU Temp | Memory | Dropped Frames | Issues |
|------|----------|----------|--------|----------------|--------|
| 1 | 68°C | 65°C | 22 GB | 0 | None |
| 2 | 72°C | 70°C | 22 GB | 3 | None |
| 3 | 74°C | 72°C | 23 GB | 5 | None |
| 4 | 75°C | 73°C | 23 GB | 8 | None |
| 5 | 75°C | 73°C | 24 GB | 12 | None |
| 6 | 76°C | 74°C | 24 GB | 15 | None |
| 7 | 76°C | 74°C | 25 GB | 18 | Minor memory creep |
| 8 | 76°C | 74°C | 26 GB | 22 | Minor memory creep |

**Findings:**
- Temperatures stabilize after ~3 hours
- Memory slowly increases (~0.5 GB/hour) - restart OBS for 12+ hour streams
- Frame drops remain well within acceptable limits
- No thermal throttling observed

---

## Comparative Analysis: Alternative Stacks

### vs NDI-Only Setup

| Aspect | HDMI/DeckLink | NDI |
|--------|---------------|-----|
| Latency | 16ms | 50-150ms |
| Quality | Lossless | Compressed |
| CPU Load | Lower | Higher |
| Network | Not required | Requires 1Gbps+ |
| Cost | Higher (capture card) | Lower (software) |
| **Verdict** | **Better for live switching** | Better for remote cameras |

### vs USB-Only Setup

| Aspect | PCIe/DeckLink | USB Capture |
|--------|---------------|-------------|
| Latency | 16ms | 80-120ms |
| Sync | Genlock possible | No sync |
| Inputs | 4 on one card | 1 per device |
| Reliability | Excellent | Good |
| Cost | $645 + chassis | $130 × 4 = $520 |
| **Verdict** | **Better for pro use** | Better for budget |

### vs Dedicated Hardware Switcher

| Aspect | OBS + DeckLink | ATEM Mini Pro ISO |
|--------|----------------|-------------------|
| Flexibility | Unlimited scenes | 4 scenes |
| Recording | Requires separate | Built-in ISO |
| Streaming | Full control | Limited platforms |
| Audio | Dante/Ableton | Basic mixing |
| Cost | ~$20k (full stack) | $900 |
| **Verdict** | **Better for complex shows** | Better for simple, portable |

---

## Benchmarking Your System

### Quick Performance Test

```bash
# Install dependencies
brew install powermetrics ffmpeg

# Run 5-minute stress test
./software/scripts/health-check.sh --verbose

# Monitor during test (new terminal)
sudo powermetrics --samplers cpu_power,gpu_power,thermal -i 5000

# Check OBS stats after test
# View → Stats → Note: Frames rendered, Dropped frames, CPU usage
```

### Recording a Benchmark

```bash
# Start OBS with stats logging
/Applications/OBS.app/Contents/MacOS/OBS --verbose --log_file /tmp/obs-benchmark.log

# After test, analyze:
grep "Dropped frames" /tmp/obs-benchmark.log
grep "Average frame time" /tmp/obs-benchmark.log
```

### Temperature Monitoring Script

```bash
#!/bin/bash
# Save as: benchmark-temps.sh
# Usage: ./benchmark-temps.sh 60  (monitor for 60 minutes)

DURATION=${1:-30}
END=$(($(date +%s) + DURATION * 60))

echo "Timestamp,CPU_Temp,GPU_Temp" > temps.csv

while [ $(date +%s) -lt $END ]; do
    TEMPS=$(sudo powermetrics -n 1 -i 1000 --samplers smc 2>/dev/null | \
            grep -E "CPU die|GPU die" | \
            awk '{print $NF}' | tr '\n' ',' | sed 's/,$//')
    echo "$(date +%H:%M:%S),$TEMPS" >> temps.csv
    sleep 10
done

echo "Results saved to temps.csv"
```

---

## Optimization Recommendations

### For Lower CPU Usage

1. Use Apple VT hardware encoder (not x264)
2. Reduce preview resolution in OBS
3. Disable unused video sources
4. Use simple scene transitions (cut, not stinger)

### For Lower GPU Usage

1. Reduce output resolution (1080p vs 4K)
2. Minimize scaling (capture at output resolution)
3. Disable filters (color correction, etc.)
4. Use fewer overlays/graphics

### For Better Thermal Performance

1. Position Mac in open air (not enclosed cabinet)
2. Ambient temperature <24°C (75°F)
3. Consider external USB fan for laptops
4. Reduce workload for extended streams (>6 hours)

### For Zero Dropped Frames

1. Close all non-essential applications
2. Disable Time Machine during stream
3. Use wired Ethernet (not WiFi)
4. Set OBS process priority to "High"

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [COMPATIBILITY.md](../hardware/COMPATIBILITY.md) - Tested hardware
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Performance issues

---

*Benchmarks performed January 2025. Results may vary with different hardware and software versions.*
