# Remote Monitoring Guide

> Monitor streaming systems remotely and receive alerts for issues.

**Last Updated:** 2025-01-20
**Version:** 1.0.0

---

## Overview

Remote monitoring enables you to:
- Check system health without physical access
- Receive alerts when issues occur
- Monitor multiple streaming setups from one location
- Review historical performance data

---

## Quick Setup (SSH-Based)

### Prerequisites

1. Enable Remote Login on Mac:
   ```
   System Preferences → General → Sharing → Remote Login: ON
   ```

2. Note your Mac's IP address:
   ```bash
   ipconfig getifaddr en0
   ```

### Basic Remote Health Check

```bash
# From remote machine
ssh user@streaming-mac "./multi-camera-livestream-framework/software/scripts/health-check.sh"
```

### JSON Output for Automation

```bash
# Get machine-readable status
ssh user@streaming-mac "./software/scripts/health-check.sh --json" | jq .
```

**Example Output:**
```json
{
  "timestamp": "2025-01-20T14:30:00Z",
  "status": "healthy",
  "checks": {
    "disk_space_gb": 234,
    "memory_free_gb": 45,
    "cpu_usage_percent": 35,
    "decklink_detected": true,
    "motu_detected": true,
    "obs_running": true,
    "ableton_running": true
  }
}
```

---

## Monitoring Solutions

### Option 1: Cron + Email Alerts (Simple)

**Setup periodic health checks with email alerts:**

```bash
# On the streaming Mac, edit crontab
crontab -e

# Add this line (check every 5 minutes, email on failure)
*/5 * * * * /path/to/health-check.sh --quiet || mail -s "ALERT: Stream Health Check Failed" you@email.com < /tmp/health-check-output.txt
```

**Configure mail (macOS):**
```bash
# Install mailutils
brew install msmtp

# Configure ~/.msmtprc with your SMTP settings
```

### Option 2: Webhook Alerts (Slack/Discord)

**Create alert script:**

```bash
#!/bin/bash
# File: software/scripts/monitor-alert.sh

WEBHOOK_URL="${SLACK_WEBHOOK:-https://hooks.slack.com/services/YOUR/WEBHOOK/URL}"

# Run health check
OUTPUT=$("$(dirname "$0")/health-check.sh" --json 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    # Send alert
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"⚠️ Stream Health Alert\n\`\`\`${OUTPUT}\`\`\`\"}" \
        "$WEBHOOK_URL"
fi
```

**Cron for webhook alerts:**
```bash
*/5 * * * * SLACK_WEBHOOK="https://hooks.slack.com/..." /path/to/monitor-alert.sh
```

### Option 3: Prometheus + Grafana (Advanced)

**Architecture:**
```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Mac Studio │───▶│  Prometheus  │───▶│   Grafana    │
│   (exporter) │    │  (metrics)   │    │ (dashboard)  │
└──────────────┘    └──────────────┘    └──────────────┘
```

**Install node_exporter on Mac:**
```bash
brew install node_exporter
brew services start node_exporter
```

**Custom metrics exporter script:**
```bash
#!/bin/bash
# File: software/scripts/prometheus-exporter.sh
# Run with: ./prometheus-exporter.sh | nc -l 9101

# Output Prometheus format metrics
echo "# HELP stream_cpu_usage CPU usage percentage"
echo "# TYPE stream_cpu_usage gauge"
echo "stream_cpu_usage $(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')"

echo "# HELP stream_disk_free_gb Disk space free in GB"
echo "# TYPE stream_disk_free_gb gauge"
echo "stream_disk_free_gb $(df -g / | tail -1 | awk '{print $4}')"

echo "# HELP stream_obs_running OBS running status"
echo "# TYPE stream_obs_running gauge"
pgrep -x OBS > /dev/null && echo "stream_obs_running 1" || echo "stream_obs_running 0"
```

**Prometheus scrape config:**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'streaming-mac'
    static_configs:
      - targets: ['streaming-mac.local:9101']
```

### Option 4: Uptime Kuma (Self-Hosted)

**Uptime Kuma** is a self-hosted monitoring tool with a web UI.

**Docker setup:**
```bash
docker run -d -p 3001:3001 -v uptime-kuma:/app/data louislam/uptime-kuma:1
```

**Configure monitoring:**
1. Open `http://localhost:3001`
2. Add new monitor: SSH type
3. Host: `streaming-mac.local`
4. Command: `./software/scripts/health-check.sh --quiet`
5. Expected exit code: `0`
6. Set notification preferences

---

## OBS-Specific Monitoring

### OBS WebSocket API

OBS has a built-in WebSocket server for remote control and monitoring.

**Enable in OBS:**
```
Tools → WebSocket Server Settings
├── Enable WebSocket server: ✓
├── Server Port: 4455
└── Enable Authentication: ✓ (set password)
```

**Python monitoring script:**
```python
#!/usr/bin/env python3
# File: software/scripts/obs-monitor.py
# Requires: pip install obsws-python

import obsws_python as obs
import time
import json

def monitor_obs():
    client = obs.ReqClient(host='streaming-mac.local', port=4455, password='your-password')

    while True:
        try:
            stats = client.get_stats()
            status = client.get_stream_status()

            metrics = {
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "streaming": status.output_active,
                "cpu_usage": stats.cpu_usage,
                "memory_usage_mb": stats.memory_usage,
                "available_disk_space_mb": stats.available_disk_space,
                "active_fps": stats.active_fps,
                "render_skipped_frames": stats.render_skipped_frames,
                "output_skipped_frames": stats.output_skipped_frames,
            }

            print(json.dumps(metrics))

            # Alert conditions
            if stats.cpu_usage > 80:
                send_alert(f"High CPU: {stats.cpu_usage}%")
            if stats.render_skipped_frames > 100:
                send_alert(f"Dropped frames: {stats.render_skipped_frames}")

        except Exception as e:
            send_alert(f"OBS connection error: {e}")

        time.sleep(30)

def send_alert(message):
    # Implement your alerting mechanism
    print(f"ALERT: {message}")

if __name__ == "__main__":
    monitor_obs()
```

### OBS Stats File Parsing

OBS can write stats to a file for external monitoring:

```bash
# In OBS Settings → Advanced → Enable stats logging
# Then parse the log file:

tail -f ~/Library/Application\ Support/obs-studio/logs/$(ls -t ~/Library/Application\ Support/obs-studio/logs/ | head -1) | \
    grep -E "Dropped|CPU|Memory"
```

---

## Platform Monitoring

### YouTube Live API

Monitor stream health via YouTube API:

```bash
#!/bin/bash
# Requires: YouTube API key and broadcast ID

API_KEY="YOUR_API_KEY"  # allow-secret (placeholder for documentation)
BROADCAST_ID="YOUR_BROADCAST_ID"

curl -s "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=status&id=$BROADCAST_ID&key=$API_KEY" | \
    jq '.items[0].status'
```

### Twitch API

Monitor Twitch stream status:

```bash
#!/bin/bash
# Requires: Twitch Client ID and OAuth token

CLIENT_ID="YOUR_CLIENT_ID"
OAUTH_TOKEN="YOUR_OAUTH_TOKEN"
CHANNEL="YOUR_CHANNEL"

curl -s -H "Client-ID: $CLIENT_ID" -H "Authorization: Bearer $OAUTH_TOKEN" \
    "https://api.twitch.tv/helix/streams?user_login=$CHANNEL" | \
    jq '.data[0]'
```

---

## Alert Thresholds

### Recommended Alert Levels

| Metric | Warning | Critical |
|--------|---------|----------|
| CPU Usage | >70% | >85% |
| Memory Usage | >80% | >90% |
| Disk Space | <50 GB | <20 GB |
| CPU Temperature | >75°C | >82°C |
| Dropped Frames/min | >10 | >50 |
| Network Latency | >100ms | >500ms |
| Stream Bitrate Drop | >20% | >50% |

### Alert Escalation

```
Level 1 (Warning):
├── Send Slack/Discord notification
└── Log to monitoring dashboard

Level 2 (Critical):
├── Send SMS/Phone call
├── Flash visual alert on secondary display
└── Consider automatic failover

Level 3 (Emergency):
├── All Level 2 actions
├── Switch to emergency scene
└── Notify backup operator
```

---

## Dashboard Setup

### Grafana Dashboard JSON

```json
{
  "title": "Streaming System Monitor",
  "panels": [
    {
      "title": "CPU Usage",
      "type": "gauge",
      "targets": [{"expr": "stream_cpu_usage"}],
      "thresholds": {"steps": [
        {"color": "green", "value": 0},
        {"color": "yellow", "value": 70},
        {"color": "red", "value": 85}
      ]}
    },
    {
      "title": "Stream Status",
      "type": "stat",
      "targets": [{"expr": "stream_obs_running"}],
      "mappings": [
        {"value": "1", "text": "LIVE", "color": "green"},
        {"value": "0", "text": "OFFLINE", "color": "red"}
      ]
    },
    {
      "title": "Dropped Frames",
      "type": "graph",
      "targets": [{"expr": "rate(stream_dropped_frames[5m])"}]
    }
  ]
}
```

### Simple HTML Dashboard

```html
<!-- File: monitoring-dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Stream Monitor</title>
    <style>
        .status { font-size: 48px; padding: 20px; margin: 10px; }
        .healthy { background: #4CAF50; color: white; }
        .warning { background: #FFC107; }
        .critical { background: #F44336; color: white; }
    </style>
</head>
<body>
    <h1>Streaming System Status</h1>
    <div id="status" class="status">Loading...</div>
    <pre id="details"></pre>

    <script>
        async function checkHealth() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();

                const statusDiv = document.getElementById('status');
                statusDiv.textContent = data.status.toUpperCase();
                statusDiv.className = 'status ' + data.status;

                document.getElementById('details').textContent =
                    JSON.stringify(data.checks, null, 2);
            } catch (e) {
                document.getElementById('status').textContent = 'ERROR';
                document.getElementById('status').className = 'status critical';
            }
        }

        setInterval(checkHealth, 5000);
        checkHealth();
    </script>
</body>
</html>
```

---

## Multi-Site Monitoring

### Centralized Dashboard Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  MONITORING CENTER                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │           Grafana / Uptime Kuma                   │   │
│  └──────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Site A    │  │   Site B    │  │   Site C    │
│ VPN/Tailnet │  │ VPN/Tailnet │  │ VPN/Tailnet │
│   Agent     │  │   Agent     │  │   Agent     │
└─────────────┘  └─────────────┘  └─────────────┘
```

### Using Tailscale for Secure Access

```bash
# Install Tailscale on streaming Mac
brew install tailscale
sudo tailscale up

# Now accessible via Tailscale IP from anywhere
ssh user@100.x.x.x  # Tailscale IP
```

---

## Automated Recovery

### Auto-Restart OBS on Crash

```bash
#!/bin/bash
# File: software/scripts/watchdog.sh
# Run in background: nohup ./watchdog.sh &

while true; do
    if ! pgrep -x "OBS" > /dev/null; then
        echo "$(date): OBS not running, restarting..."
        open -a "OBS"

        # Send alert
        curl -X POST "$SLACK_WEBHOOK" \
            -d '{"text":"⚠️ OBS crashed and was auto-restarted"}'
    fi
    sleep 10
done
```

### Auto-Reconnect Stream

OBS has built-in reconnect functionality:
```
Settings → Advanced → Automatically Reconnect
├── Enable: ✓
├── Retry Delay: 10 sec
└── Maximum Retries: 20
```

---

## See Also

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Diagnosing issues
- [BENCHMARKS.md](BENCHMARKS.md) - Performance baselines
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design

---

*For complex monitoring setups, consider consulting with a DevOps specialist.*
