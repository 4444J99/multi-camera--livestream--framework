#!/bin/bash
#
# load-test.sh - Stress test the streaming system
#
# Usage:
#   ./load-test.sh                    # Run default 30-minute test
#   ./load-test.sh --duration 60      # Run 60-minute test
#   ./load-test.sh --quick            # Run 5-minute quick test
#   ./load-test.sh --report           # Generate report only (from last test)
#
# This script:
#   - Monitors CPU, GPU, memory, and temperature
#   - Records metrics to CSV for analysis
#   - Alerts if thresholds are exceeded
#   - Generates a summary report
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$REPO_ROOT/tests/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
METRICS_FILE="$LOG_DIR/metrics_${TIMESTAMP}.csv"
REPORT_FILE="$LOG_DIR/report_${TIMESTAMP}.txt"

# Default test duration (minutes)
DURATION=30
INTERVAL=10  # seconds between samples

# Thresholds
WARN_CPU=70
CRIT_CPU=85
WARN_TEMP=75
CRIT_TEMP=82
WARN_MEM=80
CRIT_MEM=90

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "\n${GREEN}=== $1 ===${NC}\n"; }

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --duration MINUTES    Test duration in minutes (default: 30)
  --quick               Quick test (5 minutes)
  --extended            Extended test (4 hours)
  --report              Generate report from last test only
  --help                Show this help message

Examples:
  $(basename "$0")                  # Run 30-minute test
  $(basename "$0") --quick          # Run 5-minute quick test
  $(basename "$0") --duration 120   # Run 2-hour test
EOF
    exit 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

REPORT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --quick)
            DURATION=5
            shift
            ;;
        --extended)
            DURATION=240
            shift
            ;;
        --report)
            REPORT_ONLY=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# =============================================================================
# Setup
# =============================================================================

mkdir -p "$LOG_DIR"

# =============================================================================
# Metric Collection Functions
# =============================================================================

get_cpu_usage() {
    # Get CPU usage percentage (macOS)
    top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | tr -d '%'
}

get_memory_usage() {
    # Get memory usage percentage (macOS)
    vm_stat | awk '
    /Pages active/ {active=$3}
    /Pages wired/ {wired=$4}
    /Pages free/ {free=$3}
    END {
        gsub(/\./, "", active); gsub(/\./, "", wired); gsub(/\./, "", free)
        total = active + wired + free
        used = active + wired
        printf "%.1f", (used / total) * 100
    }'
}

get_temperatures() {
    # Get CPU and GPU temperatures (requires sudo for full access)
    # Returns: cpu_temp,gpu_temp
    if command -v powermetrics &> /dev/null; then
        # Try to get temps without sudo (may be limited)
        local temps
        temps=$(sudo powermetrics -n 1 -i 100 --samplers smc 2>/dev/null | \
                grep -E "CPU die|GPU die" | \
                head -2 | \
                awk '{print $NF}' | \
                tr '\n' ',' | \
                sed 's/,$//')
        if [[ -n "$temps" ]]; then
            echo "$temps"
        else
            echo "0,0"  # Fallback if no data
        fi
    else
        echo "0,0"
    fi
}

get_disk_free_gb() {
    df -g / | tail -1 | awk '{print $4}'
}

get_obs_stats() {
    # Check if OBS is running and get basic stats
    if pgrep -x "OBS" > /dev/null; then
        local obs_cpu
        obs_cpu=$(ps -p "$(pgrep -x OBS)" -o %cpu | tail -1 | tr -d ' ')
        echo "$obs_cpu"
    else
        echo "0"
    fi
}

check_dropped_frames() {
    # Parse OBS log for dropped frames (if available)
    local obs_log_dir="$HOME/Library/Application Support/obs-studio/logs"
    local latest_log
    latest_log=$(ls -t "$obs_log_dir"/*.txt 2>/dev/null | head -1)

    if [[ -n "$latest_log" ]]; then
        local drops
        drops=$(grep -c "Dropped frame" "$latest_log" 2>/dev/null || echo "0")
        echo "$drops"
    else
        echo "0"
    fi
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
    local metrics_file="${1:-$(ls -t "$LOG_DIR"/metrics_*.csv 2>/dev/null | head -1)}"

    if [[ ! -f "$metrics_file" ]]; then
        print_error "No metrics file found"
        exit 1
    fi

    local report_file="${metrics_file%.csv}_report.txt"

    print_header "Generating Report"

    cat > "$report_file" << EOF
================================================================================
                    LOAD TEST REPORT
================================================================================

Test Date: $(date)
Metrics File: $(basename "$metrics_file")

--------------------------------------------------------------------------------
SUMMARY STATISTICS
--------------------------------------------------------------------------------
EOF

    # Calculate statistics using awk
    awk -F',' 'NR>1 {
        # CPU
        cpu_sum += $2; cpu_count++
        if ($2 > cpu_max) cpu_max = $2
        if (cpu_min == "" || $2 < cpu_min) cpu_min = $2

        # Memory
        mem_sum += $3; mem_count++
        if ($3 > mem_max) mem_max = $3
        if (mem_min == "" || $3 < mem_min) mem_min = $3

        # CPU Temp
        temp_sum += $4; temp_count++
        if ($4 > temp_max) temp_max = $4
        if (temp_min == "" || $4 < temp_min) temp_min = $4

        # Warnings
        if ($2 > 70) cpu_warn++
        if ($2 > 85) cpu_crit++
        if ($4 > 75) temp_warn++
        if ($4 > 82) temp_crit++
    }
    END {
        printf "CPU Usage:\n"
        printf "  Min: %.1f%%  Max: %.1f%%  Avg: %.1f%%\n", cpu_min, cpu_max, cpu_sum/cpu_count
        printf "  Warnings (>70%%): %d  Critical (>85%%): %d\n\n", cpu_warn, cpu_crit

        printf "Memory Usage:\n"
        printf "  Min: %.1f%%  Max: %.1f%%  Avg: %.1f%%\n", mem_min, mem_max, mem_sum/mem_count

        printf "\nCPU Temperature:\n"
        printf "  Min: %.1f°C  Max: %.1f°C  Avg: %.1f°C\n", temp_min, temp_max, temp_sum/temp_count
        printf "  Warnings (>75°C): %d  Critical (>82°C): %d\n", temp_warn, temp_crit
    }' "$metrics_file" >> "$report_file"

    # Add test result
    local cpu_max gpu_temp_max
    cpu_max=$(awk -F',' 'NR>1 {if ($2 > max) max=$2} END {print max}' "$metrics_file")
    gpu_temp_max=$(awk -F',' 'NR>1 {if ($5 > max) max=$5} END {print max}' "$metrics_file")

    echo "" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"
    echo "TEST RESULT" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"

    local result="PASS"
    local notes=""

    if (( $(echo "$cpu_max > $CRIT_CPU" | bc -l) )); then
        result="FAIL"
        notes="$notes\n- CPU exceeded critical threshold ($cpu_max% > $CRIT_CPU%)"
    fi

    if [[ -n "$gpu_temp_max" ]] && (( $(echo "$gpu_temp_max > $CRIT_TEMP" | bc -l 2>/dev/null || echo 0) )); then
        result="FAIL"
        notes="$notes\n- Temperature exceeded critical threshold"
    fi

    echo "" >> "$report_file"
    echo "Result: $result" >> "$report_file"
    if [[ -n "$notes" ]]; then
        echo -e "Notes:$notes" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"
    echo "RECOMMENDATIONS" >> "$report_file"
    echo "--------------------------------------------------------------------------------" >> "$report_file"

    if [[ "$result" == "PASS" ]]; then
        echo "- System is stable for streaming workloads" >> "$report_file"
        echo "- Consider testing with longer duration for production validation" >> "$report_file"
    else
        echo "- Review system cooling and ambient temperature" >> "$report_file"
        echo "- Consider reducing streaming workload (lower resolution, fewer sources)" >> "$report_file"
        echo "- Check for background processes consuming resources" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "=================================================================================" >> "$report_file"

    print_info "Report saved to: $report_file"
    cat "$report_file"
}

# =============================================================================
# Main Test Loop
# =============================================================================

run_test() {
    print_header "Load Test Starting"
    print_info "Duration: $DURATION minutes"
    print_info "Interval: $INTERVAL seconds"
    print_info "Metrics file: $METRICS_FILE"
    echo ""

    # Check if OBS is running
    if ! pgrep -x "OBS" > /dev/null; then
        print_warn "OBS is not running. Start OBS for accurate streaming metrics."
        print_info "Continuing with system metrics only..."
    fi

    # Write CSV header
    echo "timestamp,cpu_usage,memory_usage,cpu_temp,gpu_temp,disk_free_gb,obs_cpu,dropped_frames" > "$METRICS_FILE"

    local end_time=$(($(date +%s) + DURATION * 60))
    local sample_count=0
    local warn_count=0
    local crit_count=0

    print_info "Starting metrics collection..."
    echo ""
    printf "%-20s %8s %8s %8s %8s %8s\n" "Timestamp" "CPU%" "Mem%" "CPU°C" "GPU°C" "Status"
    printf "%-20s %8s %8s %8s %8s %8s\n" "--------------------" "--------" "--------" "--------" "--------" "--------"

    while [[ $(date +%s) -lt $end_time ]]; do
        local ts=$(date +%Y-%m-%dT%H:%M:%S)
        local cpu=$(get_cpu_usage)
        local mem=$(get_memory_usage)
        local temps=$(get_temperatures)
        local cpu_temp=$(echo "$temps" | cut -d',' -f1)
        local gpu_temp=$(echo "$temps" | cut -d',' -f2)
        local disk=$(get_disk_free_gb)
        local obs_cpu=$(get_obs_stats)
        local drops=$(check_dropped_frames)

        # Handle empty values
        cpu_temp=${cpu_temp:-0}
        gpu_temp=${gpu_temp:-0}

        # Determine status
        local status="${GREEN}OK${NC}"
        if (( $(echo "$cpu > $WARN_CPU" | bc -l) )) || (( $(echo "${cpu_temp:-0} > $WARN_TEMP" | bc -l 2>/dev/null || echo 0) )); then
            status="${YELLOW}WARN${NC}"
            ((warn_count++))
        fi
        if (( $(echo "$cpu > $CRIT_CPU" | bc -l) )) || (( $(echo "${cpu_temp:-0} > $CRIT_TEMP" | bc -l 2>/dev/null || echo 0) )); then
            status="${RED}CRIT${NC}"
            ((crit_count++))
        fi

        # Write to CSV
        echo "$ts,$cpu,$mem,$cpu_temp,$gpu_temp,$disk,$obs_cpu,$drops" >> "$METRICS_FILE"

        # Display
        printf "%-20s %7.1f%% %7.1f%% %7.1f° %7.1f° " \
            "$(date +%H:%M:%S)" "$cpu" "$mem" "$cpu_temp" "$gpu_temp"
        echo -e "$status"

        ((sample_count++))
        sleep "$INTERVAL"
    done

    echo ""
    print_header "Test Complete"
    print_info "Samples collected: $sample_count"
    print_info "Warnings: $warn_count"
    print_info "Critical: $crit_count"
    echo ""

    # Generate report
    generate_report "$METRICS_FILE"
}

# =============================================================================
# Entry Point
# =============================================================================

if $REPORT_ONLY; then
    generate_report
else
    # Check for sudo access for temperature monitoring
    if ! sudo -n true 2>/dev/null; then
        print_warn "Temperature monitoring requires sudo access."
        print_info "Run 'sudo true' first for full metrics, or continue with limited metrics."
        echo ""
    fi

    run_test
fi
