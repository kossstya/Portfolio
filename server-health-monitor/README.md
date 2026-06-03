# Server Health Monitor

A lightweight Bash script that monitors CPU, RAM, disk usage, and service status. Logs results every 5 minutes via cron and writes alerts when thresholds are exceeded.

## What it does

- Checks **CPU** usage (via `vmstat`)
- Checks **RAM** usage (via `free`)
- Checks **disk** usage on all block devices (via `df`)
- Checks that specified **services** are running (via `systemctl`)
- Writes timestamped entries to `logs/health.log`
- Writes alerts to `logs/alerts.log` when any threshold is breached

## Project structure

```
server-health-monitor/
├── monitor.sh       # main script
├── config.sh        # thresholds and service list
├── setup-cron.sh    # registers cron job (run once)
└── logs/
    ├── health.log   # all check results
    └── alerts.log   # threshold breaches only
```

## Quick start

```bash
git clone https://github.com/kossstya/server-health-monitor.git
cd server-health-monitor

# Edit thresholds and service names if needed
nano config.sh

# Register cron job (runs monitor.sh every 5 minutes)
bash setup-cron.sh

# Or run manually
bash monitor.sh && cat logs/health.log
```

## Configuration (`config.sh`)

| Variable | Default | Description |
|---|---|---|
| `CPU_THRESHOLD` | `80` | Alert if CPU usage ≥ this % |
| `RAM_THRESHOLD` | `80` | Alert if RAM usage ≥ this % |
| `DISK_THRESHOLD` | `85` | Alert if any disk partition ≥ this % |
| `SERVICES` | `ssh cron` | Space-separated systemd service names |

## Sample output

`logs/health.log`
```
[2026-06-03 14:29:15] CPU: 7%
[2026-06-03 14:29:15] RAM: 41% (6578MB / 15714MB)
[2026-06-03 14:29:15] Disk /: 57%
[2026-06-03 14:29:15] Disk /boot/efi: 2%
[2026-06-03 14:29:15] Service [ssh]: running
[2026-06-03 14:29:15] Service [cron]: running
[2026-06-03 14:29:15] --- check complete ---
```

`logs/alerts.log`
```
[2026-06-03 14:29:15] ALERT: Disk / is 92% full (threshold: 85%)
```

## Requirements

- Linux with `systemd`
- `vmstat` (package: `procps`)
- `bash 4+`

## Cron schedule

`setup-cron.sh` adds this entry to your crontab:

```
*/5 * * * * /path/to/monitor.sh
```

Meaning: run every 5 minutes, every hour, every day.
