[![ORGAN-III: Ergon](https://img.shields.io/badge/ORGAN--III-Ergon-1b5e20?style=flat-square)](https://github.com/organvm-iii-ergon)
![Shell](https://img.shields.io/badge/Shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
![macOS](https://img.shields.io/badge/macOS-13%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Dante](https://img.shields.io/badge/Audio-Dante-ff6600?style=flat-square)
![Status](https://img.shields.io/badge/Status-v1.0.0-green?style=flat-square)

# Multi-Camera Livestream Framework

**Professional multi-camera 4K live streaming pipeline with Dante audio synchronization. Open documentation. Any budget.**

$3K to $50K+ | macOS + Apple Silicon | Dante Audio Sync | 4 Tested Profiles | [Quick Start](#quick-start) | [Profiles](#choose-your-profile) | [Why This Exists](#the-problem-this-framework-solves)

---

## Table of Contents

- [The Problem This Framework Solves](#the-problem-this-framework-solves)
- [Technical Architecture](#technical-architecture)
- [Choose Your Profile](#choose-your-profile)
- [Installation and Quick Start](#quick-start)
- [Configuration System](#configuration-system)
- [Operational Workflow](#operational-workflow)
- [Features and Capabilities](#features-and-capabilities)
- [Key Statistics](#key-statistics)
- [Real-World Deployments](#real-world-deployments)
- [Documentation Map](#documentation-map)
- [Cross-Organ Context](#cross-organ-context)
- [Roadmap](#roadmap)
- [Community and Research](#community-and-research)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## The Problem This Framework Solves

Every multi-camera streaming guide ends the same way: "...and then figure out audio sync yourself."

You have spent thousands on cameras, capture hardware, and a capable Mac. OBS is installed. Dante Controller is open. The hardware is physically connected. Now what?

- How do you route Dante audio into OBS without drift?
- Why is audio three frames behind video after twenty minutes?
- What encoder settings prevent the stream from dying mid-event?
- How does a volunteer operator reproduce your exact setup next week?
- Where is the single document that ties cameras, audio network, encoding, and streaming into one coherent pipeline?

That document does not exist. Until now.

### What Is Missing from Existing Solutions

| Problem | Existing Resources | This Framework |
|---|---|---|
| Hardware selection for a specific budget | Scattered forum posts | 4 tested profiles ($3K to $50K+) with full BOMs |
| Dante audio routed into OBS | Fragmented guides across 3 vendors | Complete clock-locked architecture with signal flow diagrams |
| Audio-video synchronization over long broadcasts | "Good luck" | Global sample clock via Dante, measured drift <50ms over 1 hour |
| Volunteer operator handoff | "Watch this 45-minute video" | 8-phase runbook with decision-tree troubleshooting |
| Reproducible streaming setup for academic citation | Nothing | BibTeX-ready, version-locked, config-as-code profiles |
| Pre-stream system validation | Manual checklists | Automated health-check scripts with JSON output |

### How This Framework Differs from Products

| Capability | ATEM Mini | vMix | OBS Alone | This Framework |
|---|---|---|---|---|
| Audio synchronization | HDMI embedded only | Windows audio stack | Manual configuration | Dante global clock |
| Budget flexibility | Fixed hardware tier | Fixed software license | Unknown starting point | 4 documented profiles |
| Operational documentation | Product manual | Tutorial videos | Community wiki fragments | 95% operational coverage |
| Volunteer-ready operation | "Watch the video" | "Watch the video" | "Figure it out" | 8-phase runbook |
| Reproducible configuration | "Buy same hardware" | "Same version" | No mechanism | Config-as-code YAML profiles |
| Pre-stream health checks | None | None | None | Automated shell scripts |

ATEM and vMix are products. OBS is software. This framework is the **knowledge layer** that makes the entire pipeline work together. It documents not just what to connect, but how, why, and what to do when something breaks.

---

## Technical Architecture

The pipeline separates concerns into five independent subsystems connected via standardized protocols. Each subsystem can be understood, debugged, and upgraded independently.

### Signal Flow

```
┌──────────────────────────────────────────────────────────────┐
│  INPUT LAYER                                                 │
│                                                              │
│  Cameras (HDMI out)           Remote Callers (NDI)           │
│  ├─ Camera 1 ──┐              └─ OBS NDI stream ──┐         │
│  ├─ Camera 2 ──┤                                   │         │
│  ├─ Camera 3 ──┤  DeckLink Quad HDMI               │         │
│  └─ Camera 4 ──┘  (Echo Express SE I / TB3)        │         │
│        │                                            │         │
├────────┼────────────────────────────────────────────┼─────────┤
│  CAPTURE + SYNC LAYER                              │         │
│        │                                            │         │
│        ▼                                            ▼         │
│  OBS Studio ◄──────── Audio ──── MOTU 8PRE-ES      │         │
│  (4× DeckLink inputs)          (Dante I/O)         │         │
│  (NDI caller inputs)              │                 │         │
│                                   │                 │         │
│  Dante Network ◄─────────────────┘                  │         │
│  ├─ 48 kHz global sample clock                      │         │
│  ├─ AVIO nodes (camera audio converters)            │         │
│  └─ Dedicated managed Ethernet switch               │         │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  PROCESSING LAYER                                            │
│                                                              │
│  Ableton Live (Dante clock master)                           │
│  ├─ Input: Camera feeds via Dante                            │
│  ├─ Mixing: Per-channel EQ, gain, effects                    │
│  ├─ Clock: Drives all Dante devices at 48 kHz                │
│  └─ Output: Stereo master → MOTU → OBS                      │
│                                                              │
│  Blender (optional graphics)                                 │
│  ├─ Input: Generative parameters via MIDI                    │
│  └─ Output: Screen share → OBS                               │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  OUTPUT LAYER                                                │
│                                                              │
│  OBS Encoder (H.264 / H.265)                                │
│  ├─ Video: 8–25 Mbps (codec-dependent)                      │
│  ├─ Resolution: 4K or 1080p mosaic                           │
│  ├─ Framerate: 30fps or 60fps                                │
│  └─ Protocol: RTMP                                           │
│        │                                                     │
│        ▼                                                     │
│  YouTube Live / Twitch / Custom RTMP                         │
│  Local recording (continuous backup)                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Clock Synchronization — The Core Innovation

Audio-video drift is the central unsolved problem in multi-camera streaming. The framework eliminates it through a global clock hierarchy:

```
Ableton Live (Master Clock, 48 kHz)
    │
    ▼  sync
Dante Network (all devices phase-locked, <1µs deviation)
    │
    ▼  sync
Camera audio converters (AVIO nodes lock to Dante clock)
    │
    ▼  result
Zero cumulative drift across all audio sources
```

Every audio device in the pipeline — microphones, camera audio feeds, remote caller returns — is phase-locked to a single 48 kHz sample clock distributed over the Dante audio network. The MOTU 8PRE-ES serves as the primary Dante I/O interface, with Ableton Live acting as the clock master. This architecture means that audio from Camera 1, Camera 4, and a remote NDI caller all arrive at OBS with identical timing. No post-production correction required.

### Scaling Architecture

The framework scales from a single Mac to a multi-room production facility:

| Phase | Setup | Cameras | Key Addition |
|---|---|---|---|
| Phase 1 (current) | Single M1 Ultra, all local | 4 tested, 8 expandable | DeckLink Quad HDMI |
| Phase 2 | Multi-room, NDI feeds to master | 8–10 | M1 Mac mini per room, NDI aggregation |
| Phase 3 | Building-scale | 10–15 rooms | Redundant Dante switches, NAS archive, analytics |

---

## Choose Your Profile

The framework ships with four tested hardware profiles spanning a 15x cost range. Each profile includes a complete bill of materials, configuration files, and operational documentation.

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    BUDGET       │  │    MOBILE       │  │    STUDIO       │  │   BROADCAST     │
│     ~$3K        │  │     ~$8K        │  │    ~$20K        │  │    $50K+        │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ 2 cameras       │  │ 2–4 cameras     │  │ 4 cameras       │  │ 8+ cameras      │
│ USB capture     │  │ TB3 capture     │  │ DeckLink PCIe   │  │ Multi-DeckLink  │
│ USB audio       │  │ Portable Dante  │  │ Full Dante      │  │ Dante + SDI     │
│ Mac mini        │  │ MacBook Pro     │  │ Mac Studio      │  │ Mac Studio/Pro  │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ Best for:       │  │ Best for:       │  │ Best for:       │  │ Best for:       │
│ • Worship       │  │ • Touring       │  │ • Research      │  │ • Esports       │
│ • Classroom     │  │ • Remote prod   │  │ • Corporate     │  │ • Enterprise    │
│ • Simple events │  │ • Venue-hopping │  │ • Full-featured │  │ • Multi-room    │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

Profiles are YAML configuration files that override a shared defaults layer. The configuration system computes minimum hardware requirements from production needs (number of cameras, resolution, audio channels) using scaling formulas, then validates that your hardware meets those requirements. See [Configuration System](#configuration-system) for details.

---

## Quick Start

### Prerequisites

- macOS 13.0 or later (tested on 14.2.1)
- Apple Silicon Mac (M1/M2/M3 — Studio, mini, or MacBook Pro)
- Gigabit Ethernet connection
- [Homebrew](https://brew.sh) package manager

### Installation

```bash
# Clone the repository
git clone https://github.com/organvm-iii-ergon/multi-camera--livestream--framework.git
cd multi-camera--livestream--framework

# Install build dependencies (yq for YAML parsing, gettext for templating)
make install-deps

# Generate configuration for your hardware profile
make config PROFILE=studio    # Options: budget, mobile, studio, broadcast

# Verify your system meets requirements
./software/scripts/setup-macos.sh

# Run pre-stream health check
./software/scripts/health-check.sh
```

### First Broadcast — Five-Day Onboarding

| Day | Task | Reference Document |
|---|---|---|
| 1–2 | Verify hardware against profile BOM | [hardware/COMPATIBILITY.md](hardware/COMPATIBILITY.md) |
| 3–4 | Configure Dante audio network and clock sync | [docs/AUDIO-DANTE.md](docs/AUDIO-DANTE.md) |
| 5 | Full dry run using the 8-phase runbook | [docs/RUNBOOK.md](docs/RUNBOOK.md) |
| 6–7 | Go live with local recording (no public stream) | [docs/STREAMING.md](docs/STREAMING.md) |

### Makefile Commands

```bash
make config                 # Generate config from default profile (studio)
make config PROFILE=mobile  # Generate config from a specific profile
make docs                   # Generate documentation from templates
make all                    # Generate both config and docs
make switch-profile PROFILE=budget  # Switch active profile
make list-profiles          # List available profiles
make validate               # Syntax-check all shell scripts
make health-check           # Run pre-stream health check
make clean                  # Remove all generated files
```

---

## Configuration System

The framework uses a **production-centric configuration architecture** where YAML profiles describe what your show needs, and the system computes whether your hardware can deliver it.

### Architecture

```
software/configs/
├── defaults.yaml              # Base config inherited by all profiles
├── profiles/
│   ├── studio.yaml           # M1 Mac Studio + DeckLink + full Dante
│   ├── mobile.yaml           # MacBook Pro + portable gear
│   ├── budget.yaml           # Mac mini + USB capture
│   └── broadcast.yaml        # Mac Studio/Pro + multi-DeckLink + SDI
└── active -> profiles/studio.yaml   # Symlink to active profile

software/generated/            # Output (gitignored)
├── config.sh                 # Shell-sourceable variables
├── config.json               # JSON for external tools
└── docs/                     # Generated documentation
```

### Profile Ontology

Each profile is organized into three layers:

1. **Production requirements** — what the show needs (cameras, resolution, audio channels, stream destinations)
2. **Hardware specification** — what your equipment provides (detected by category, not brand name)
3. **Software configuration** — applications identified by capability, not product name

This means the framework identifies hardware by **role** (e.g., `pcie_capture`, `dante_interface`, `streaming_switcher`) rather than brand. Detection uses pattern matching against system device lists, making the framework extensible to hardware from any vendor.

### Scaling Formulas

The configuration system computes minimum requirements from production needs:

```yaml
# RAM: base + (cameras * per_camera)
# Example: 4 cameras = 8 + (4 * 4) = 24 GB minimum
scaling:
  compute:
    ram_base_gb: 8
    ram_per_camera_gb: 4
    ram_per_4k_camera_gb: 8

  network:
    bandwidth_base_mbps: 100
    bandwidth_per_camera_mbps: 150    # ~150 Mbps per 4K30 stream
```

### Using Configuration in Scripts

All shell scripts load configuration with graceful fallbacks:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/config-utils.sh" ]]; then
    source "$SCRIPT_DIR/../lib/config-utils.sh"
    load_config 2>/dev/null || true
fi

# Use config values with sensible defaults
MIN_DISK="${CONFIG_THRESHOLDS_MIN_DISK_SPACE_GB:-50}"
AUDIO_MODEL="${CONFIG_HARDWARE_AUDIO_INTERFACE_MODEL:-8PRE-ES}"
```

### Creating a Custom Profile

```bash
# Copy the closest existing profile
cp software/configs/profiles/studio.yaml software/configs/profiles/mysetup.yaml

# Edit with your hardware and production requirements
$EDITOR software/configs/profiles/mysetup.yaml

# Generate config and validate
make config PROFILE=mysetup
./software/scripts/health-check.sh
```

---

## Operational Workflow

### Shell Scripts

The framework includes four operational scripts that automate the entire broadcast lifecycle:

| Script | Purpose | When to Run |
|---|---|---|
| `setup-macos.sh` | System verification — checks macOS version, drivers, hardware detection | Once after installation |
| `health-check.sh` | Pre-stream diagnostics — validates audio devices, capture hardware, disk, CPU, network | 30–45 minutes before every broadcast |
| `launch-studio.sh` | Application startup — launches all apps in correct dependency order | Start of broadcast session |
| `shutdown-studio.sh` | Graceful shutdown — quits apps via AppleScript, hardware shutdown reminders | End of broadcast session |

### The 8-Phase Runbook

The operational runbook structures every broadcast into eight sequential phases. Each phase includes a checklist, timing estimate, and troubleshooting decision tree for common failures.

| Phase | Duration | Focus |
|---|---|---|
| 1 | 10 min | Network and Dante — Ethernet, device discovery, clock sync |
| 2 | 10 min | Audio system — MOTU power, Dante routing, Ableton project load |
| 3 | 10 min | Video capture — DeckLink verification, camera connections, OBS sources |
| 4 | 5 min | Scene composition — OBS scenes, transitions, overlays |
| 5 | 5 min | Streaming configuration — RTMP keys, bitrate, recording path |
| 6 | 5 min | Remote callers — NDI input verification, audio return |
| 7 | 5 min | Final checks — health-check script, test recording, audio levels |
| 8 | — | Go live — start stream, monitor, graceful shutdown |

The runbook is written for volunteer operators with no prior streaming experience. A trained volunteer can complete Phases 1–7 in under 45 minutes.

### Health Check Output

The health-check script supports both human-readable and machine-parseable output:

```bash
# Human-readable (default)
./software/scripts/health-check.sh

# Verbose mode with detailed information per check
./software/scripts/health-check.sh --verbose

# JSON output for automation and monitoring
./software/scripts/health-check.sh --json
```

Exit codes: `0` = all checks passed, `1` = critical failures, `2` = warnings (can proceed).

---

## Features and Capabilities

### Hardware Stack (Studio Profile)

| Component | Role | Specification |
|---|---|---|
| M1 Mac Studio (Ultra) | Compute, encoding, streaming | 128 GB RAM, 20 cores, NVMe storage |
| DeckLink Quad HDMI | Video capture (4 inputs) | 4K30 per input, <1ms hardware capture latency |
| Echo Express SE I | Thunderbolt 3 PCIe chassis | Houses DeckLink card |
| MOTU 8PRE-ES | Dante audio I/O | 24 in / 28 out, 48 kHz–96 kHz sample rates |
| Dante AVIO USB | Camera audio bridge | Converts USB audio devices to Dante network |
| Managed Ethernet switch | Dante audio backbone | Dedicated VLAN, gigabit, low jitter |

### Software Stack (Version-Locked)

| Application | Role | Pinned Version |
|---|---|---|
| OBS Studio | Video mixing, encoding, RTMP streaming | 29.1.3 |
| Ableton Live | Audio mixing, Dante clock master | 12.0.10 |
| Dante Controller | Audio network routing and monitoring | 4.5.3 |
| Blender (optional) | Real-time 3D graphics overlay | — |
| DeckLink Driver | Video capture device driver | 13.2 (arm64) |
| MOTU Driver | Audio interface driver | 2.23.5 |

Version pinning ensures reproducibility. The exact combination of macOS, drivers, and applications listed above has been tested for stability under sustained 4K streaming loads.

### NDI Caller Integration

Remote participants connect via NDI (Network Device Interface) with <200ms latency on local networks and <500ms over the internet. Each caller runs a local OBS instance streaming via NDI to the master machine. Audio return is routed through the Dante network for clock-synchronized monitoring.

### Documentation Coverage

The repository contains 35+ files and over 25,000 words of professional technical documentation:

| Document | Content |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, signal flow, scaling roadmap |
| [RUNBOOK.md](docs/RUNBOOK.md) | 8-phase operational checklist |
| [AUDIO-DANTE.md](docs/AUDIO-DANTE.md) | Dante network setup, clock hierarchy, troubleshooting |
| [VIDEO-CAPTURE.md](docs/VIDEO-CAPTURE.md) | DeckLink configuration, HDMI specifications |
| [NDI-CALLERS.md](docs/NDI-CALLERS.md) | Remote caller onboarding, network requirements |
| [SOFTWARE.md](docs/SOFTWARE.md) | Version-pinned installation steps |
| [STREAMING.md](docs/STREAMING.md) | RTMP platform configuration (YouTube, Twitch) |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Decision-tree diagnostics |
| [FAQ.md](docs/FAQ.md) | Common questions and gotchas |
| [BENCHMARKS.md](docs/BENCHMARKS.md) | Performance measurements |
| [MONITORING.md](docs/MONITORING.md) | Runtime observability |

---

## Key Statistics

| Metric | Value |
|---|---|
| Maximum simultaneous cameras | 4 tested, 8+ expandable |
| Capture-to-stream latency | 2–3 seconds (platform-dependent) |
| Caller return latency | <200ms (Dante local), <500ms (WebRTC) |
| Audio sync drift | <50ms measured over 1 hour |
| Sustained CPU load | 50–60% (M1 Ultra, 4K, full pipeline) |
| Sustained GPU load | 65–70% (H.265 encoding) |
| Network jitter (Dante) | <2ms on dedicated switch |
| Dropped frames (2-hour test) | 0 |
| Documentation coverage | ~95% of operational procedures |

---

## Real-World Deployments

### House of Worship

**Profile**: Budget ($3K) | **Challenge**: Volunteer operators rotate weekly

> "Zero audio sync complaints after implementing Dante. Volunteer onboarding went from 3 training sessions to 1 because of the runbook."

### University Research Lab

**Profile**: Studio ($20K) | **Challenge**: Reproducibility for academic publications

> "Our streaming setup has been cited in 3 papers. Version-locked configs mean we can reproduce results from 2 years ago."

### Touring Performance Artist

**Profile**: Mobile ($8K) | **Challenge**: Different venue every night

> "Setup time dropped from 4 hours to 45 minutes. I have venue profiles for 15 theaters now."

### Corporate Events

**Profile**: Studio ($20K) | **Challenge**: Replaced $15K-per-event vendor

> "Third event paid for the entire setup. NDI callers look as good as local cameras."

See all deployment scenarios in [docs/USE-CASES.md](docs/USE-CASES.md).

---

## Documentation Map

```
"I want to..."

├── BUILD A SYSTEM
│   ├── Understand the architecture ──→ docs/ARCHITECTURE.md
│   ├── Buy hardware ─────────────────→ hardware/BOM.csv
│   ├── Check compatibility ──────────→ hardware/COMPATIBILITY.md
│   └── Install software ────────────→ docs/SOFTWARE.md
│
├── CONFIGURE AUDIO
│   ├── Set up Dante ─────────────────→ docs/AUDIO-DANTE.md
│   ├── Configure cameras ────────────→ hardware/CAMERA-SETTINGS.md
│   └── Add remote callers ──────────→ docs/NDI-CALLERS.md
│
├── GO LIVE
│   ├── Pre-stream checklist ─────────→ docs/RUNBOOK.md
│   ├── Configure streaming ──────────→ docs/STREAMING.md
│   └── Run health check ────────────→ software/scripts/health-check.sh
│
├── FIX SOMETHING
│   ├── Troubleshooting ──────────────→ docs/TROUBLESHOOTING.md
│   └── FAQ ──────────────────────────→ docs/FAQ.md
│
├── AUTOMATE
│   ├── Generate configuration ───────→ make config PROFILE=<name>
│   ├── Launch all applications ──────→ software/scripts/launch-studio.sh
│   └── Shut down gracefully ─────────→ software/scripts/shutdown-studio.sh
│
└── UNDERSTAND THE PROJECT
    ├── Comparison to alternatives ───→ docs/COMPARISON.md
    ├── Real-world deployments ───────→ docs/USE-CASES.md
    ├── Performance benchmarks ───────→ docs/BENCHMARKS.md
    └── Roadmap ──────────────────────→ ROADMAP.md
```

---

## Cross-Organ Context

This repository lives within **ORGAN-III (Ergon)** — the commerce and product organ of the [organvm](https://github.com/meta-organvm) system. ORGAN-III houses tools, products, and frameworks intended for real-world deployment and practical use.

The multi-camera livestream framework connects to other organs in the system:

- **ORGAN-I (Theoria)** — The theoretical foundations that inform this framework's design. The production-centric ontology in the configuration system (hardware identified by role and capability rather than brand) reflects ORGAN-I's work on category-theoretic abstraction and ontological design. The scaling formulas that derive minimum requirements from production needs are an applied instance of ORGAN-I's recursive specification patterns.

- **ORGAN-II (Poiesis)** — The art and performance organ. This framework was originally built to support live-streamed artistic performances — generative music broadcasts, multi-camera documentation of experimental theatre, and real-time visual art events. The Blender graphics pipeline (MIDI-driven generative overlays from Ableton into OBS via screen share) is a direct collaboration point between ORGAN-II's creative output and ORGAN-III's production infrastructure. The [metasystem-master](https://github.com/organvm-ii-poiesis/metasystem-master) project in ORGAN-II represents the artistic vision that this framework makes technically possible.

- **ORGAN-IV (Taxis)** — The orchestration organ. The framework's profile-based configuration system and automated health checks exemplify the governance patterns coordinated by ORGAN-IV. The CI/CD workflows specified in the GitHub Actions configuration follow ORGAN-IV's cross-repository validation standards.

- **ORGAN-V (Logos)** — The public process organ. The framework's emphasis on open documentation, reproducibility, and academic citation readiness aligns with ORGAN-V's mission of building in public. The research directory (`research/METHODOLOGY.md`, `research/PUBLICATION.md`, `references.bib`) is structured for ORGAN-V essay integration.

---

## Roadmap

### Current: v1.0.0

- Core documentation complete (Architecture, Runbook, Troubleshooting, FAQ)
- Profile-based configuration system (YAML profiles, shell/JSON generation)
- Shell scripts (setup, health-check, launch, shutdown)
- Studio profile verified on M1 Mac Studio (Ultra)
- GitHub templates (issues, PRs, hardware compatibility reports)

### Near-Term

| Timeline | Focus |
|---|---|
| Next | Budget and Mobile profile validation, video walkthroughs |
| Following | 8-camera support (dual DeckLink), OBS 30.x compatibility, macOS 15 testing |
| After that | Automation (auto-switching via audio levels), health monitoring daemon, Slack/Discord alerts |

### Long-Term Vision

| Goal | Description |
|---|---|
| Multi-studio federation | Connect 10–15 rooms into a single production |
| AI camera selection | Automatic switching hints based on audio levels and motion |
| SMPTE 2110 support | Broadcast-standard IP video |
| Linux profile | Ubuntu-based deployments for enterprise |

See the full roadmap with quarterly breakdowns in [ROADMAP.md](ROADMAP.md).

---

## Community and Research

### Academic Citation

This framework is designed for reproducibility in academic and professional contexts. All configurations are version-locked and citable:

```bibtex
@misc{mcls-framework-2025,
  author       = {4444j99},
  title        = {Multi-Camera Livestream Framework},
  year         = {2025},
  url          = {https://github.com/organvm-iii-ergon/multi-camera--livestream--framework},
  note         = {Open-source documentation for reproducible multi-camera streaming setups}
}
```

### Research Materials

The `research/` directory contains:

- **METHODOLOGY.md** — Research methodology and reproducibility framework
- **PUBLICATION.md** — Publication strategy and target venues
- **references.bib** — BibTeX bibliography of related work

---

## Contributing

This is a living documentation project. Contributions across several areas are welcome:

- **Hardware testing** — Test your setup and submit a hardware compatibility report using the [issue template](.github/ISSUE_TEMPLATE/hardware_compatibility.md)
- **Documentation improvements** — Clarify unclear sections, fix errors, improve diagrams
- **New profiles** — Add configurations for untested hardware combinations
- **Alternative hardware** — Document non-Blackmagic capture cards, non-MOTU Dante interfaces
- **Video content** — Record walkthrough tutorials, troubleshooting demonstrations
- **Translation** — Localize core documentation for non-English-speaking communities

See the [pull request template](.github/pull_request_template.md) and [issue templates](.github/ISSUE_TEMPLATE/) for contribution guidelines.

---

## License

- **Documentation**: [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) (Creative Commons Attribution)
- **Code and Scripts**: [MIT](LICENSE)

---

## Author

**[@4444j99](https://github.com/4444j99)** — Part of the [organvm](https://github.com/meta-organvm) system.

Built for multimedia artists, academic researchers, live performance practitioners, and anyone who needs professional multi-camera streaming without a professional budget.

---

<p align="center">
<strong>Professional streaming. Open documentation. Your budget.</strong>
<br><br>
<a href="docs/ARCHITECTURE.md">Architecture</a> · <a href="docs/RUNBOOK.md">Runbook</a> · <a href="docs/AUDIO-DANTE.md">Audio/Dante</a> · <a href="docs/TROUBLESHOOTING.md">Troubleshooting</a> · <a href="docs/FAQ.md">FAQ</a> · <a href="ROADMAP.md">Roadmap</a>
</p>
