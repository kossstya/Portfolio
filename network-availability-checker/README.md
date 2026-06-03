# Network Availability Checker

A Bash script that monitors hosts and TCP ports from a config file. Runs every minute via cron and logs UP/DOWN status — alerts only when the state actually changes (not every minute).

## What it does

- **Pings** each host to check basic reachability
- **Checks TCP port** availability using bash's built-in `/dev/tcp` (no netcat required)
- **Tracks state** across runs via `/tmp` state files — alerts only on UP→DOWN or DOWN→UP transitions
- Logs all results to `logs/status.log`
- Logs state changes to `logs/alerts.log`

## Project structure

```
network-availability-checker/
├── check-hosts.sh    # main script
├── config.sh         # timeouts and paths
├── hosts.conf        # list of hosts/ports to monitor
├── setup-cron.sh     # registers cron job (run once)
└── logs/
    ├── status.log    # every scan result
    └── alerts.log    # UP↔DOWN transitions only
```

## Quick start

```bash
git clone https://github.com/kossstya/network-availability-checker.git
cd network-availability-checker

# Edit hosts list
nano hosts.conf

# Run once manually
bash check-hosts.sh

# Register cron (runs every minute)
bash setup-cron.sh
```

## hosts.conf format

```
# HOST          PORT   LABEL
8.8.8.8         53     Google-DNS
1.1.1.1         53     Cloudflare-DNS
google.com      443    Google-HTTPS
192.168.1.1     80     Local-Router
```

## Sample output

`logs/status.log`
```
[2026-06-03 14:51:39] UP   | Google-DNS      | 8.8.8.8:53
[2026-06-03 14:51:39] UP   | Cloudflare-DNS  | 1.1.1.1:53
[2026-06-03 14:51:39] UP   | Google-HTTPS    | google.com:443
[2026-06-03 14:51:39] DOWN | Local-Router    | 192.168.1.1:80 | host unreachable
[2026-06-03 14:51:39] SUMMARY | UP: 3  DOWN: 1
```

`logs/alerts.log`
```
[2026-06-03 14:51:39] ALERT: Local-Router (192.168.1.1) is unreachable — was UNKNOWN
[2026-06-03 15:03:12] ALERT: Local-Router (192.168.1.1:80) recovered — back UP
```

## How state tracking works

Each host/port pair has a state file in `/tmp/nac_<host>_<port>`. On every run:

1. Read previous state (`UP`, `DOWN`, or `UNKNOWN` on first run)
2. Run ping + port check → get current state
3. Write current state back to file
4. Alert **only if** current state differs from previous

This means if a host is DOWN for 60 minutes, you get **1 alert** — not 60.

## Requirements

- Linux with `bash 4+`
- Standard tools: `ping`, `grep`, `awk`
- No external dependencies — port check uses bash's `/dev/tcp`

## Cron schedule

`setup-cron.sh` adds this entry:

```
* * * * * /path/to/check-hosts.sh
```

Meaning: run every minute.
