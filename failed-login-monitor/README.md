# Failed Login Monitor

A Bash script that parses `/var/log/auth.log` for failed SSH login attempts, groups them by source IP, and generates a daily report highlighting suspicious IPs.

## What it does

- Finds all `Failed password` entries in the auth log
- Extracts source IP addresses
- Ranks IPs by number of attempts
- Flags IPs that exceed a configurable threshold (default: 5 attempts)
- Saves a timestamped report to `reports/`

## Project structure

```
failed-login-monitor/
├── check-logins.sh       # main script
├── config.sh             # log path and threshold settings
├── setup-cron.sh         # registers daily cron job (run once)
├── reports/              # generated reports stored here
└── test/
    └── sample-auth.log   # test log for demo without root access
```

## Quick start

```bash
git clone https://github.com/kossstya/failed-login-monitor.git
cd failed-login-monitor

# Test with sample data (no root needed)
bash check-logins.sh test/sample-auth.log

# Run against real auth.log
sudo bash check-logins.sh

# Set up daily cron job (runs every day at 08:00)
sudo bash setup-cron.sh
```

## Configuration (`config.sh`)

| Variable | Default | Description |
|---|---|---|
| `AUTH_LOG` | `/var/log/auth.log` | Path to SSH auth log |
| `ATTEMPT_THRESHOLD` | `5` | Flag IP if it has this many failed attempts |
| `REPORT_DIR` | `./reports` | Where to save daily reports |

## Sample output

```
========================================
  Failed SSH Login Report — 2026-06-03
========================================
  Log      : /var/log/auth.log
  Generated: 08:00:01

--- Top 10 offenders ---
  185.220.101.42     6 attempts
  91.230.34.77       5 attempts
  45.33.32.156       3 attempts

--- Flagged IPs (>= 5 attempts) ---
  185.220.101.42     6 attempts
  91.230.34.77       5 attempts

--- Summary ---
  Total failed attempts : 17
  Unique source IPs     : 5
  Flagged IPs           : 2
========================================
```

## How it works

1. `grep "Failed password"` — filters relevant lines from the log
2. `awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}'` — extracts IP (always the word after "from")
3. `sort | uniq -c | sort -rn` — counts and ranks by frequency
4. Compares each count against `$ATTEMPT_THRESHOLD` and flags violators

## Requirements

- Linux with `systemd` / OpenSSH logging to `/var/log/auth.log`
- `bash 4+`, standard GNU coreutils (`grep`, `awk`, `sort`, `uniq`)
- Read access to auth.log (typically requires root or `adm` group membership)

## Cron schedule

`setup-cron.sh` adds this entry:

```
0 8 * * * /path/to/check-logins.sh
```

Meaning: run at 08:00 every day.
