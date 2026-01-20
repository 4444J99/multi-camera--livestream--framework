#!/usr/bin/env bash
#
# health-check.sh - Pre-stream health check for Multi-Camera Livestream Framework
#
# Run this script 30-45 minutes before going live to verify all
# hardware and software is functioning correctly.
#
# Usage: ./health-check.sh [--verbose] [--json]
#   --verbose    Show detailed information for each check
#   --json       Output results in JSON format
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical failures detected
#   2 - Warnings detected but can proceed
#
# Author: Multi-Camera Livestream Framework
# Version: 2.0.0

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration Loading
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Attempt to load configuration from generated config
CONFIG_LOADED=false
if [[ -f "$SCRIPT_DIR/../lib/config-utils.sh" ]]; then
    # shellcheck source=../lib/config-utils.sh
    source "$SCRIPT_DIR/../lib/config-utils.sh"
    if load_config 2>/dev/null; then
        CONFIG_LOADED=true
    fi
fi

# =============================================================================
# PRODUCTION REQUIREMENTS (from config)
# =============================================================================

PROD_CAMERAS="${CONFIG_PRODUCTION_VIDEO_CAMERAS:-4}"
PROD_VIDEO_RES="${CONFIG_PRODUCTION_VIDEO_CAPTURE_RESOLUTION:-1080p30}"
PROD_AUDIO_IN="${CONFIG_PRODUCTION_AUDIO_INPUT_CHANNELS:-8}"
PROD_AUDIO_OUT="${CONFIG_PRODUCTION_AUDIO_OUTPUT_CHANNELS:-2}"
PROD_SAMPLE_RATE="${CONFIG_PRODUCTION_AUDIO_SAMPLE_RATE:-48000}"
PROD_STREAM_RES="${CONFIG_PRODUCTION_STREAMING_OUTPUT_RESOLUTION:-1080p60}"
PROD_BITRATE="${CONFIG_PRODUCTION_STREAMING_BITRATE_KBPS:-6000}"

# =============================================================================
# SCALING FORMULAS (from config)
# =============================================================================

# RAM: base + (cameras * per_camera)
RAM_BASE="${CONFIG_SCALING_COMPUTE_RAM_BASE_GB:-8}"
RAM_PER_CAM="${CONFIG_SCALING_COMPUTE_RAM_PER_CAMERA_GB:-4}"
REQUIRED_RAM_GB=$((RAM_BASE + (PROD_CAMERAS * RAM_PER_CAM)))

# Network: base + (cameras * per_camera)
NET_BASE="${CONFIG_SCALING_NETWORK_BANDWIDTH_BASE_MBPS:-100}"
NET_PER_CAM="${CONFIG_SCALING_NETWORK_BANDWIDTH_PER_CAMERA_MBPS:-150}"
REQUIRED_NET_MBPS=$((NET_BASE + (PROD_CAMERAS * NET_PER_CAM)))

# =============================================================================
# HARDWARE SPECS (from config - for display and validation)
# =============================================================================

# Compute
COMPUTE_CATEGORY="${CONFIG_HARDWARE_COMPUTE_CATEGORY:-workstation}"
COMPUTE_RAM="${CONFIG_HARDWARE_COMPUTE_RAM_GB:-32}"
COMPUTE_CORES="${CONFIG_HARDWARE_COMPUTE_CPU_CORES:-8}"

# Video capture
VIDEO_CATEGORY="${CONFIG_HARDWARE_VIDEO_CAPTURE_CATEGORY:-capture}"
VIDEO_INPUTS="${CONFIG_HARDWARE_VIDEO_CAPTURE_INPUTS:-4}"
VIDEO_MAX_RES="${CONFIG_HARDWARE_VIDEO_CAPTURE_MAX_RESOLUTION:-1080p30}"
VIDEO_INTERFACE="${CONFIG_HARDWARE_VIDEO_CAPTURE_INTERFACE:-hdmi}"
VIDEO_CAPTURE_PATTERNS="${CONFIG_HARDWARE_VIDEO_CAPTURE_DETECTION_PATTERNS:-decklink blackmagic}"

# Format category for display (e.g., "pcie_capture" -> "PCIe capture")
format_category() {
    local cat="$1"
    # Replace underscores with spaces, then capitalize each word
    # Handle special cases first
    cat="${cat/pcie/PCIe}"
    cat="${cat/usb/USB}"
    cat="${cat/ndi/NDI}"
    cat="${cat/sdi/SDI}"
    cat="${cat/nvme/NVMe}"
    cat="${cat/ssd/SSD}"
    cat="${cat/hdd/HDD}"
    cat="${cat/10gbe/10GbE}"
    # Replace underscores with spaces
    cat="${cat//_/ }"
    # Capitalize first letter of each word (awk for portability)
    echo "$cat" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

VIDEO_CAPTURE_DESC="$(format_category "$VIDEO_CATEGORY") (${VIDEO_INPUTS} ${VIDEO_INTERFACE^^} inputs)"

# Enclosure (if applicable)
ENCLOSURE_CATEGORY="${CONFIG_HARDWARE_VIDEO_CAPTURE_ENCLOSURE_CATEGORY:-}"
ENCLOSURE_INTERFACE="${CONFIG_HARDWARE_VIDEO_CAPTURE_ENCLOSURE_INTERFACE:-thunderbolt3}"
ENCLOSURE_PATTERNS="${CONFIG_HARDWARE_VIDEO_CAPTURE_ENCLOSURE_DETECTION_PATTERNS:-}"
if [[ -n "$ENCLOSURE_CATEGORY" ]]; then
    ENCLOSURE_DESC="$(format_category "$ENCLOSURE_CATEGORY")"
else
    ENCLOSURE_DESC=""
fi

# Audio
AUDIO_CATEGORY="${CONFIG_HARDWARE_AUDIO_INTERFACE_CATEGORY:-interface}"
AUDIO_IN="${CONFIG_HARDWARE_AUDIO_INTERFACE_CHANNELS_IN:-8}"
AUDIO_OUT="${CONFIG_HARDWARE_AUDIO_INTERFACE_CHANNELS_OUT:-8}"
AUDIO_NETWORK="${CONFIG_HARDWARE_AUDIO_INTERFACE_NETWORK_AUDIO:-false}"
AUDIO_PATTERNS="${CONFIG_HARDWARE_AUDIO_INTERFACE_DETECTION_PATTERNS:-}"
AUDIO_DESC="$(format_category "$AUDIO_CATEGORY") (${AUDIO_IN}-in/${AUDIO_OUT}-out)"

# Network
NET_CATEGORY="${CONFIG_HARDWARE_NETWORK_CATEGORY:-gigabit_ethernet}"
NET_BANDWIDTH="${CONFIG_HARDWARE_NETWORK_BANDWIDTH_GBPS:-1}"

# Thresholds from config or defaults
MIN_DISK_SPACE_GB="${CONFIG_THRESHOLDS_MIN_DISK_SPACE_GB:-50}"
MIN_MEMORY_FREE_PERCENT="${CONFIG_THRESHOLDS_MIN_MEMORY_FREE_PERCENT:-20}"
MAX_CPU_USAGE_PERCENT="${CONFIG_THRESHOLDS_MAX_CPU_USAGE_PERCENT:-70}"
MIN_MEMORY_FREE_MB="${CONFIG_THRESHOLDS_MIN_MEMORY_FREE_MB:-4000}"
RECOMMENDED_MEMORY_FREE_MB="${CONFIG_THRESHOLDS_RECOMMENDED_MEMORY_FREE_MB:-8000}"

# =============================================================================
# CLI Arguments
# =============================================================================

VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json|-j)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Color Output
# -----------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Disable colors for JSON output
if $JSON_OUTPUT; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

print_header() {
    if ! $JSON_OUTPUT; then
        echo ""
        echo -e "${BOLD}${BLUE}── $1 ──${NC}"
    fi
}

print_pass() {
    if ! $JSON_OUTPUT; then
        echo -e "  ${GREEN}✓${NC} $1"
    fi
}

print_fail() {
    if ! $JSON_OUTPUT; then
        echo -e "  ${RED}✗${NC} $1"
    fi
}

print_warn() {
    if ! $JSON_OUTPUT; then
        echo -e "  ${YELLOW}⚠${NC} $1"
    fi
}

print_info() {
    if ! $JSON_OUTPUT && $VERBOSE; then
        echo -e "    ${BLUE}→${NC} $1"
    fi
}

print_hint() {
    if ! $JSON_OUTPUT; then
        echo -e "    Check: $1"
    fi
}

# -----------------------------------------------------------------------------
# Result Tracking
# -----------------------------------------------------------------------------

declare -A RESULTS
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

record_result() {
    local check_name=$1
    local status=$2  # pass, fail, warn
    local message=$3

    RESULTS["$check_name"]="$status:$message"

    case $status in
        pass) PASS_COUNT=$((PASS_COUNT + 1)) ;;
        fail) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
        warn) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    esac
}

# =============================================================================
# PRODUCTION REQUIREMENTS DISPLAY
# =============================================================================

show_production_requirements() {
    print_header "Production Requirements"
    if ! $JSON_OUTPUT; then
        echo "  Video: ${PROD_CAMERAS} cameras @ ${PROD_VIDEO_RES}"
        echo "  Audio: ${PROD_AUDIO_IN} inputs, ${PROD_AUDIO_OUT} outputs @ ${PROD_SAMPLE_RATE}Hz"
        echo "  Stream: ${PROD_STREAM_RES} @ ${PROD_BITRATE}kbps"
    fi
}

# =============================================================================
# COMPUTE RESOURCES CHECKS
# =============================================================================

check_compute_capacity() {
    print_header "Compute Resources"

    # RAM check - get actual system RAM
    local system_ram
    system_ram=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    system_ram=$((system_ram / 1024 / 1024 / 1024))  # Convert to GB

    local category_display
    category_display="$(format_category "$COMPUTE_CATEGORY")"

    if [[ $system_ram -ge $REQUIRED_RAM_GB ]]; then
        print_pass "${category_display}: ${system_ram}GB RAM (need ${REQUIRED_RAM_GB}GB min)"
        record_result "compute_ram" "pass" "${system_ram}GB available"
    else
        print_fail "${category_display}: ${system_ram}GB RAM (need ${REQUIRED_RAM_GB}GB min)"
        print_hint "Insufficient RAM for ${PROD_CAMERAS} camera production"
        record_result "compute_ram" "fail" "Insufficient RAM"
    fi

    # CPU cores check
    local cpu_cores
    cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "0")
    print_info "CPU: ${cpu_cores} cores available"
    record_result "compute_cores" "pass" "${cpu_cores} cores"

    # Storage type check
    if $VERBOSE; then
        local storage_info
        storage_info=$(diskutil info / 2>/dev/null | command grep "Solid State" || echo "")
        if echo "$storage_info" | command grep -qi "yes"; then
            print_info "Storage: SSD/NVMe detected"
        else
            print_info "Storage: Type unknown (check manually)"
        fi
    fi
}

# =============================================================================
# VIDEO CAPTURE CHECKS
# =============================================================================

check_video_capture() {
    print_header "Video Capture"

    # First show capacity requirement
    if [[ $VIDEO_INPUTS -ge $PROD_CAMERAS ]]; then
        print_pass "Capacity: ${PROD_CAMERAS} cameras → ${VIDEO_INPUTS} inputs available"
        record_result "video_capacity" "pass" "Sufficient inputs"
    else
        print_fail "Capacity: Need ${PROD_CAMERAS} cameras, only ${VIDEO_INPUTS} inputs configured"
        record_result "video_capacity" "fail" "Insufficient inputs"
    fi

    # Check for video capture hardware via system profiler
    local pci_devices
    pci_devices=$(system_profiler SPPCIDataType 2>/dev/null || echo "")

    # Check using detection patterns
    local capture_detected=false
    for pattern in $VIDEO_CAPTURE_PATTERNS; do
        if echo "$pci_devices" | command grep -qi "$pattern"; then
            capture_detected=true
            break
        fi
    done

    if $capture_detected; then
        print_pass "${VIDEO_CAPTURE_DESC} detected"
        record_result "video_capture_hw" "pass" "Hardware found"

        if $VERBOSE; then
            local capture_info
            for pattern in $VIDEO_CAPTURE_PATTERNS; do
                capture_info=$(echo "$pci_devices" | command grep -i "$pattern" -A3 | head -4)
                if [[ -n "$capture_info" ]]; then
                    print_info "$capture_info"
                    break
                fi
            done
        fi
    else
        # Check Thunderbolt for enclosure if applicable
        if [[ -n "$ENCLOSURE_CATEGORY" ]]; then
            local tb_devices
            tb_devices=$(system_profiler SPThunderboltDataType 2>/dev/null || echo "")

            local enclosure_detected=false
            for pattern in $ENCLOSURE_PATTERNS $VIDEO_CAPTURE_PATTERNS; do
                if echo "$tb_devices" | command grep -qi "$pattern"; then
                    enclosure_detected=true
                    break
                fi
            done

            if $enclosure_detected; then
                print_warn "${ENCLOSURE_DESC} detected, verify capture card"
                record_result "video_capture_hw" "warn" "Chassis detected, verify card"
            else
                print_fail "${VIDEO_CAPTURE_DESC} not detected"
                print_hint "${ENCLOSURE_DESC} powered on?"
                print_hint "Thunderbolt cable connected?"
                record_result "video_capture_hw" "fail" "Hardware not found"
            fi
        else
            # No enclosure expected (USB capture, etc.)
            # Check USB devices
            local usb_devices
            usb_devices=$(system_profiler SPUSBDataType 2>/dev/null || echo "")

            local usb_capture_detected=false
            for pattern in $VIDEO_CAPTURE_PATTERNS; do
                if echo "$usb_devices" | command grep -qi "$pattern"; then
                    usb_capture_detected=true
                    break
                fi
            done

            if $usb_capture_detected; then
                print_pass "${VIDEO_CAPTURE_DESC} detected"
                record_result "video_capture_hw" "pass" "USB capture found"
            else
                print_fail "${VIDEO_CAPTURE_DESC} not detected"
                print_hint "USB capture devices connected?"
                record_result "video_capture_hw" "fail" "Hardware not found"
            fi
        fi
    fi
}

# =============================================================================
# AUDIO INTERFACE CHECKS
# =============================================================================

check_audio_interface() {
    print_header "Audio Interface"

    # Capacity check
    if [[ $AUDIO_IN -ge $PROD_AUDIO_IN ]]; then
        print_pass "Capacity: ${PROD_AUDIO_IN} inputs → ${AUDIO_IN} available"
        record_result "audio_capacity" "pass" "Sufficient channels"
    else
        print_fail "Capacity: Need ${PROD_AUDIO_IN} inputs, only ${AUDIO_IN} configured"
        record_result "audio_capacity" "fail" "Insufficient channels"
    fi

    # Check for audio devices via ioreg
    local audio_devices
    audio_devices=$(ioreg -r -c IOAudioDevice 2>/dev/null || true)

    # Check using detection patterns
    local interface_detected=false
    for pattern in $AUDIO_PATTERNS; do
        if echo "$audio_devices" | command grep -qi "$pattern"; then
            interface_detected=true
            break
        fi
    done

    if $interface_detected; then
        print_pass "${AUDIO_DESC} detected"
        record_result "audio_interface" "pass" "Hardware found"

        if $VERBOSE; then
            local device_info
            for pattern in $AUDIO_PATTERNS; do
                device_info=$(echo "$audio_devices" | command grep -i "$pattern" -A5 | head -6)
                if [[ -n "$device_info" ]]; then
                    print_info "Device: $device_info"
                    break
                fi
            done
        fi
    else
        print_fail "${AUDIO_DESC} not detected"
        print_hint "Audio interface powered on and connected?"
        record_result "audio_interface" "fail" "Hardware not found"
    fi

    # Check for network audio (Dante/AVB) if enabled
    if [[ "$AUDIO_NETWORK" == "true" ]]; then
        if ioreg -r -c IOAudioDevice 2>/dev/null | command grep -qi "dante"; then
            print_pass "Network audio driver active"
            record_result "network_audio" "pass" "Driver active"
        else
            print_info "Network audio driver not detected (may not be required)"
            record_result "network_audio" "warn" "Driver not active"
        fi
    fi
}

# =============================================================================
# NETWORK CHECKS
# =============================================================================

check_network() {
    print_header "Network"

    # Calculate bandwidth in Mbps for comparison
    local available_mbps=$((NET_BANDWIDTH * 1000))

    if [[ $available_mbps -ge $REQUIRED_NET_MBPS ]]; then
        print_pass "Bandwidth: ${REQUIRED_NET_MBPS}Mbps needed, ${available_mbps}Mbps available"
        record_result "network_capacity" "pass" "Sufficient bandwidth"
    else
        print_warn "Bandwidth: ${REQUIRED_NET_MBPS}Mbps needed, ${available_mbps}Mbps available"
        record_result "network_capacity" "warn" "Limited bandwidth"
    fi

    # Check for active network connection
    local active_interface
    active_interface=$(route get default 2>/dev/null | command grep interface | awk '{print $2}')

    if [[ -n "$active_interface" ]]; then
        local net_type_display
        net_type_display="$(format_category "$NET_CATEGORY")"
        print_pass "Active interface: $active_interface (${net_type_display})"

        local ip_addr
        ip_addr=$(ifconfig "$active_interface" 2>/dev/null | command grep "inet " | awk '{print $2}')
        if [[ -n "$ip_addr" ]]; then
            print_info "IP Address: $ip_addr"
        fi

        record_result "network_interface" "pass" "$active_interface"
    else
        print_fail "No active network connection"
        record_result "network_interface" "fail" "No connection"
    fi

    # Test internet connectivity (RTMP endpoint)
    if ping -c 1 -t 5 a.rtmp.youtube.com &>/dev/null; then
        print_pass "Streaming endpoint reachable"
        record_result "streaming_endpoint" "pass" "Reachable"
    else
        # Try general internet
        if ping -c 1 -t 5 8.8.8.8 &>/dev/null; then
            print_warn "Internet available but streaming endpoint may be blocked"
            record_result "streaming_endpoint" "warn" "Possible block"
        else
            print_fail "No internet connectivity"
            record_result "streaming_endpoint" "fail" "No internet"
        fi
    fi
}

# =============================================================================
# APPLICATION STATE CHECKS
# =============================================================================

check_application_state() {
    print_header "Application State"

    if pgrep -x "OBS" > /dev/null 2>&1 || pgrep -x "obs" > /dev/null 2>&1; then
        print_warn "Video mixer already running"
        print_info "Close before launching via launch-studio.sh for clean state"
        record_result "video_mixer_not_running" "warn" "Already running"
    else
        print_pass "Video mixer not running (clean state)"
        record_result "video_mixer_not_running" "pass" "Clean state"
    fi

    if pgrep -x "Ableton Live" > /dev/null 2>&1 || pgrep -f "Ableton" > /dev/null 2>&1; then
        print_warn "Audio mixer already running"
        record_result "audio_mixer_not_running" "warn" "Already running"
    else
        print_pass "Audio mixer not running (clean state)"
        record_result "audio_mixer_not_running" "pass" "Clean state"
    fi
}

# =============================================================================
# SYSTEM RESOURCE CHECKS
# =============================================================================

check_disk_space() {
    print_header "Storage"

    local free_space
    free_space=$(df -g / | tail -1 | awk '{print $4}')

    if [[ $free_space -ge $MIN_DISK_SPACE_GB ]]; then
        print_pass "Disk space: ${free_space}GB free"
        record_result "disk_space" "pass" "${free_space}GB free"
    else
        print_fail "Disk space: ${free_space}GB free (minimum ${MIN_DISK_SPACE_GB}GB required)"
        print_hint "Free up space before streaming to ensure recording buffer"
        record_result "disk_space" "fail" "Only ${free_space}GB free"
    fi
}

check_cpu_memory() {
    print_header "System Load"

    # CPU usage (rough estimate via top)
    local cpu_idle
    cpu_idle=$(top -l 1 -n 0 2>/dev/null | command grep "CPU usage" | awk -F'idle' '{print $1}' | awk '{print $NF}' | tr -d '%')

    if [[ -n "$cpu_idle" ]]; then
        local cpu_used=$((100 - ${cpu_idle%.*}))

        if [[ $cpu_used -le $MAX_CPU_USAGE_PERCENT ]]; then
            print_pass "CPU usage: ${cpu_used}% (${cpu_idle}% idle)"
            record_result "cpu_usage" "pass" "${cpu_used}% used"
        else
            print_warn "CPU usage: ${cpu_used}% (high load detected)"
            print_hint "Close unnecessary applications before streaming"
            record_result "cpu_usage" "warn" "${cpu_used}% used"
        fi
    else
        print_info "Could not determine CPU usage"
        record_result "cpu_usage" "warn" "Unknown"
    fi

    # Memory usage
    local mem_info
    mem_info=$(vm_stat 2>/dev/null)

    if [[ -n "$mem_info" ]]; then
        local pages_free
        pages_free=$(echo "$mem_info" | command grep "Pages free" | awk '{print $3}' | tr -d '.')
        local pages_inactive
        pages_inactive=$(echo "$mem_info" | command grep "Pages inactive" | awk '{print $3}' | tr -d '.')

        local page_size=16384  # 16KB on Apple Silicon
        local free_mb=$(( (pages_free + pages_inactive) * page_size / 1024 / 1024 ))

        if [[ $free_mb -ge $RECOMMENDED_MEMORY_FREE_MB ]]; then
            print_pass "Memory: ~${free_mb}MB available"
            record_result "memory" "pass" "${free_mb}MB available"
        elif [[ $free_mb -ge $MIN_MEMORY_FREE_MB ]]; then
            print_warn "Memory: ~${free_mb}MB available (recommend 8GB+ free)"
            record_result "memory" "warn" "${free_mb}MB available"
        else
            print_fail "Memory: ~${free_mb}MB available (low memory)"
            print_hint "Close applications to free memory before streaming"
            record_result "memory" "fail" "${free_mb}MB available"
        fi
    else
        print_info "Could not determine memory usage"
        record_result "memory" "warn" "Unknown"
    fi
}

check_thermal() {
    print_header "Thermal Status"

    # Simple thermal check via CPU temperature if available
    if command -v osx-cpu-temp &>/dev/null; then
        local cpu_temp
        cpu_temp=$(osx-cpu-temp 2>/dev/null)
        print_info "CPU Temperature: $cpu_temp"
    fi

    # Check if thermal throttling might be occurring
    local thermal_state
    thermal_state=$(pmset -g therm 2>/dev/null | command grep -i "thermal" || echo "")

    if [[ -n "$thermal_state" ]]; then
        if echo "$thermal_state" | command grep -qi "no thermal"; then
            print_pass "No thermal throttling"
            record_result "thermal" "pass" "No throttling"
        else
            print_warn "Thermal conditions detected"
            print_hint "Ensure adequate ventilation"
            record_result "thermal" "warn" "Check ventilation"
        fi
    else
        print_pass "Thermal status normal"
        record_result "thermal" "pass" "Normal"
    fi
}

# -----------------------------------------------------------------------------
# Output Summary
# -----------------------------------------------------------------------------

print_summary() {
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"profile\": \"${CONFIG_PROFILE_NAME:-unknown}\","
        echo "  \"production\": {"
        echo "    \"cameras\": $PROD_CAMERAS,"
        echo "    \"resolution\": \"$PROD_VIDEO_RES\","
        echo "    \"audio_inputs\": $PROD_AUDIO_IN"
        echo "  },"
        echo "  \"pass_count\": $PASS_COUNT,"
        echo "  \"fail_count\": $FAIL_COUNT,"
        echo "  \"warn_count\": $WARN_COUNT,"
        echo "  \"status\": \"$([ $FAIL_COUNT -eq 0 ] && echo "ready" || echo "not_ready")\","
        echo "  \"checks\": {"

        local first=true
        for key in "${!RESULTS[@]}"; do
            if ! $first; then echo ","; fi
            first=false
            local value="${RESULTS[$key]}"
            local status="${value%%:*}"
            local message="${value#*:}"
            echo -n "    \"$key\": {\"status\": \"$status\", \"message\": \"$message\"}"
        done

        echo ""
        echo "  }"
        echo "}"
        return
    fi

    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HEALTH CHECK SUMMARY${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $PASS_COUNT"
    echo -e "  ${RED}Failed:${NC}   $FAIL_COUNT"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        if [[ $WARN_COUNT -eq 0 ]]; then
            echo -e "${GREEN}${BOLD}✓ All systems ready for streaming!${NC}"
            echo ""
            echo "Next: Run ./launch-studio.sh to start applications"
        else
            echo -e "${YELLOW}${BOLD}⚠ Ready with warnings - review items above${NC}"
            echo ""
            echo "You can proceed but address warnings when possible."
            echo "Next: Run ./launch-studio.sh to start applications"
        fi
    else
        echo -e "${RED}${BOLD}✗ Critical issues detected - DO NOT proceed${NC}"
        echo ""
        echo "Resolve the failed checks above before streaming."
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    if ! $JSON_OUTPUT; then
        echo ""
        echo -e "${BOLD}Livestream Framework - Pre-Stream Health Check${NC}"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')"
        if [[ "$CONFIG_LOADED" == "true" ]]; then
            echo -e "Profile: ${BLUE}${CONFIG_PROFILE_NAME:-unknown}${NC}"
        fi
    fi

    show_production_requirements
    check_compute_capacity
    check_video_capture
    check_audio_interface
    check_network
    check_application_state
    check_disk_space
    check_cpu_memory
    check_thermal

    print_summary

    # Exit codes
    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit 1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

main
