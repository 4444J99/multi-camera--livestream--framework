#!/bin/bash
#
# stress-generator.sh - Generate system load for stress testing
#
# Usage:
#   ./stress-generator.sh cpu 70        # Target 70% CPU load
#   ./stress-generator.sh memory 80     # Allocate to 80% memory
#   ./stress-generator.sh encoding      # Simulate encoding load
#   ./stress-generator.sh stop          # Stop all stress processes
#
# Use with load-test.sh to validate system stability under load.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# PID file for tracking stress processes
PID_FILE="/tmp/stress-generator.pids"

usage() {
    cat << EOF
Usage: $(basename "$0") <command> [args]

Commands:
  cpu <percent>       Generate CPU load targeting specified percentage
  memory <percent>    Allocate memory to specified percentage of total
  encoding            Simulate video encoding workload (FFmpeg)
  combined            Run CPU + encoding simulation together
  status              Show running stress processes
  stop                Stop all stress generators

Examples:
  $(basename "$0") cpu 70         # Generate ~70% CPU load
  $(basename "$0") encoding       # Simulate transcoding
  $(basename "$0") combined       # Run both CPU and encoding
  $(basename "$0") stop           # Stop all stress processes

Notes:
  - Run 'load-test.sh' in another terminal to monitor metrics
  - Use 'stop' to clean up all stress processes when done
  - Memory stress uses temporary files (cleaned on stop)
EOF
    exit 0
}

# =============================================================================
# CPU Stress
# =============================================================================

stress_cpu() {
    local target=${1:-50}
    local cores=$(sysctl -n hw.ncpu)
    local workers=$((cores * target / 100))
    [[ $workers -lt 1 ]] && workers=1

    print_info "Starting CPU stress: targeting ~${target}% with $workers workers"

    # Use yes command piped to /dev/null for CPU load
    for ((i=1; i<=workers; i++)); do
        yes > /dev/null &
        echo $! >> "$PID_FILE"
    done

    print_info "CPU stress started. PIDs saved to $PID_FILE"
    print_info "Run '$(basename "$0") stop' to end stress test"
}

# =============================================================================
# Memory Stress
# =============================================================================

stress_memory() {
    local target=${1:-50}
    local total_mb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024)}')
    local target_mb=$((total_mb * target / 100))

    print_info "Starting memory stress: allocating ~${target_mb}MB (${target}% of ${total_mb}MB)"

    # Create a memory-mapped file
    local mem_file="/tmp/stress-memory-$$"
    dd if=/dev/zero of="$mem_file" bs=1M count="$target_mb" 2>/dev/null &
    local pid=$!

    echo "$pid" >> "$PID_FILE"
    echo "$mem_file" >> "/tmp/stress-generator.files"

    # Keep the file mapped in memory
    (
        sleep 1
        cat "$mem_file" > /dev/null
        while true; do
            sleep 60
            cat "$mem_file" > /dev/null
        done
    ) &
    echo $! >> "$PID_FILE"

    print_info "Memory stress started. Target: ${target_mb}MB"
}

# =============================================================================
# Encoding Stress (simulates video processing)
# =============================================================================

stress_encoding() {
    print_info "Starting encoding stress (FFmpeg simulation)"

    if ! command -v ffmpeg &> /dev/null; then
        print_warn "FFmpeg not found. Installing via Homebrew..."
        brew install ffmpeg 2>/dev/null || {
            print_error "Could not install FFmpeg. Using CPU stress instead."
            stress_cpu 60
            return
        }
    fi

    # Generate test pattern and encode in loop
    local output="/tmp/stress-encoding-$$.mp4"

    (
        while true; do
            ffmpeg -f lavfi -i testsrc=duration=60:size=1920x1080:rate=60 \
                   -c:v libx264 -preset medium -b:v 6000k \
                   -y "$output" 2>/dev/null

            # Small pause between iterations
            sleep 1
        done
    ) &
    local pid=$!

    echo "$pid" >> "$PID_FILE"
    echo "$output" >> "/tmp/stress-generator.files"

    print_info "Encoding stress started (PID: $pid)"
    print_info "Simulating 1080p60 H.264 encoding at 6Mbps"
}

# =============================================================================
# Combined Stress
# =============================================================================

stress_combined() {
    print_info "Starting combined stress test"

    # Start encoding (uses ~30-40% CPU on Apple Silicon)
    stress_encoding

    # Add additional CPU load
    sleep 2
    stress_cpu 40

    print_info "Combined stress running"
}

# =============================================================================
# Status
# =============================================================================

show_status() {
    print_info "Stress generator status:"
    echo ""

    if [[ -f "$PID_FILE" ]]; then
        local running=0
        local stopped=0

        while read -r pid; do
            if ps -p "$pid" > /dev/null 2>&1; then
                local cmd
                cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                echo "  PID $pid: RUNNING ($cmd)"
                ((running++))
            else
                echo "  PID $pid: STOPPED"
                ((stopped++))
            fi
        done < "$PID_FILE"

        echo ""
        print_info "Running: $running, Stopped: $stopped"
    else
        print_info "No stress processes recorded"
    fi

    # Show current system load
    echo ""
    print_info "Current system load:"
    echo "  CPU: $(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}')"
    echo "  Memory: $(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.') pages active"
}

# =============================================================================
# Stop All
# =============================================================================

stop_all() {
    print_info "Stopping all stress generators..."

    if [[ -f "$PID_FILE" ]]; then
        while read -r pid; do
            if ps -p "$pid" > /dev/null 2>&1; then
                kill "$pid" 2>/dev/null && echo "  Stopped PID $pid"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi

    # Clean up any orphaned yes processes
    pkill -f "^yes$" 2>/dev/null || true

    # Clean up temp files
    if [[ -f "/tmp/stress-generator.files" ]]; then
        while read -r file; do
            rm -f "$file" 2>/dev/null && echo "  Removed $file"
        done < "/tmp/stress-generator.files"
        rm -f "/tmp/stress-generator.files"
    fi

    # Clean up any stray encoding files
    rm -f /tmp/stress-encoding-*.mp4 2>/dev/null
    rm -f /tmp/stress-memory-* 2>/dev/null

    print_info "All stress generators stopped"
}

# =============================================================================
# Entry Point
# =============================================================================

[[ $# -lt 1 ]] && usage

case "$1" in
    cpu)
        stress_cpu "${2:-50}"
        ;;
    memory)
        stress_memory "${2:-50}"
        ;;
    encoding)
        stress_encoding
        ;;
    combined)
        stress_combined
        ;;
    status)
        show_status
        ;;
    stop)
        stop_all
        ;;
    --help|-h)
        usage
        ;;
    *)
        print_error "Unknown command: $1"
        usage
        ;;
esac
