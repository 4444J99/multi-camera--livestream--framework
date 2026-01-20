# Software Installation & Configuration

> Version-pinned software installation guide for the Multi-Camera Livestream Framework.

**Generated from profile:** studio
**Last Updated:** 2026-01-20
**Version:** 1.0.0

---

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Version Pinning](#version-pinning)
4. [Installation Guide](#installation-guide)
5. [Configuration Files](#configuration-files)
6. [Updates & Maintenance](#updates--maintenance)

---

## Overview

This document provides the definitive software installation guide for the Multi-Camera Livestream Framework. All software versions are **pinned** for reproducibility—do not upgrade without testing in a non-production environment.

### Software Stack

| Category | Software | Version | Purpose |
|----------|----------|---------|---------|
| Video Mixing |  |  | Main production switcher |
| Audio Mixing |  |  | DAW, Dante clock master |
| Audio Network |  |  | Dante routing |
| Video Capture | Desktop Video |  | DeckLink drivers |
| Audio Interface |  Drivers |  |  support |
| Graphics |  (optional) | - | Real-time graphics |

---

## System Requirements

### Hardware Requirements

| Component | Current Setup |
|-----------|---------------|
| Computer |  |
| Chip |  |
| RAM | GB |
| Video Capture |   |
| Audio Interface |   |
| Thunderbolt Chassis |  |

### macOS Requirements

| Requirement | Version |
|-------------|---------|
| macOS | .0+ () |
| Current OS |  () |

> ⚠️ Do not upgrade macOS without verifying driver compatibility.

---

## Version Pinning

### Current Pinned Versions

These versions are tested and known to work together:

| Software | Version | Bundle ID |
|----------|---------|-----------|
| macOS |  | - |
|  |  | `com.obsproject.obs-studio` |
|  |  | `` |
|  |  | `com.audinate.dante.DanteController` |
| Desktop Video (DeckLink) |  | - |
|  Drivers |  | - |

---

## Installation Guide

### 1. macOS Preparation

```bash
# Check current macOS version
sw_vers -productVersion
# Expected:  or compatible

# Verify Apple Silicon
uname -m
# Expected: 
```

### 2. Install Required Applications

1. **** v
   - Role: Video mixing, encoding, streaming
   - Download from official source

2. **** v
   - Role: 
   - Download from official source

3. **** v
   - Role: Audio network routing and monitoring
   - Download from Audinate

### 3. Install Hardware Drivers

1. ** Desktop Video** v
   - For 
   - Architecture: 

2. ** Drivers** v
   - For 

---

## Configuration Files

Configuration is managed via the profile system. Current profile: **studio**

```bash
# View current configuration
cat software/generated/config.sh

# Switch profiles
./software/scripts/generate-config.sh [profile_name]
```

---

## Updates & Maintenance

Before updating any software:

1. Test in non-production environment
2. Verify all drivers are compatible
3. Update the profile YAML if versions change
4. Regenerate config: `./software/scripts/generate-config.sh`
5. Regenerate docs: `make docs`
