#!/bin/bash
# failed-login-monitor/check-logins.sh
# Parses auth.log for failed SSH attempts, groups by IP, flags suspicious ones.
# Cron example: 0 8 * * * /path/to/check-logins.sh
#
# Usage:
#   ./check-logins.sh              — use log from config.sh
#   ./check-logins.sh /custom/path — use a different log file (useful for testing)

source "$(dirname "$0")/config.sh"

# Allow overriding the log file via argument (for testing)
[ -n "$1" ] && AUTH_LOG="$1"

DATE=$(date '+%Y-%m-%d')
REPORT_FILE="$REPORT_DIR/report-$DATE.txt"
mkdir -p "$REPORT_DIR"

# --- Validation ---
if [ ! -f "$AUTH_LOG" ]; then
    echo "ERROR: Log file not found: $AUTH_LOG" >&2
    exit 1
fi

if [ ! -r "$AUTH_LOG" ]; then
    echo "ERROR: Cannot read $AUTH_LOG — try running with sudo" >&2
    exit 1
fi

# --- Parse log ---
# Typical line: Jun 3 10:05:01 host sshd[123]: Failed password for root from 1.2.3.4 port 22 ssh2
# "for invalid user admin from" — IP is always the word after "from"
FAILED_LINES=$(grep "Failed password" "$AUTH_LOG")
TOTAL=$(echo "$FAILED_LINES" | grep -v '^$' | wc -l)

# --- Build report ---
{
    echo "========================================"
    echo "  Failed SSH Login Report — $DATE"
    echo "========================================"
    echo "  Log      : $AUTH_LOG"
    echo "  Generated: $(date '+%H:%M:%S')"
    echo ""

    if [ "$TOTAL" -eq 0 ]; then
        echo "  No failed login attempts found in log."
        echo "========================================"
    else
        # Extract IPs: take the word that comes right after "from"
        IP_LIST=$(echo "$FAILED_LINES" | awk '{
            for (i=1; i<=NF; i++)
                if ($i == "from") print $(i+1)
        }')

        UNIQUE=$(echo "$IP_LIST" | sort -u | wc -l)

        # Count attempts per IP, sorted by most attempts first
        IP_COUNTS=$(echo "$IP_LIST" | sort | uniq -c | sort -rn)

        echo "--- Top 10 offenders ---"
        echo "$IP_COUNTS" | head -10 | awk '{printf "  %-18s %d attempts\n", $2, $1}'
        echo ""

        echo "--- Flagged IPs (>= $ATTEMPT_THRESHOLD attempts) ---"
        FLAGGED=$(echo "$IP_COUNTS" | awk -v t="$ATTEMPT_THRESHOLD" '$1 >= t')
        if [ -z "$FLAGGED" ]; then
            echo "  None — no IP reached the threshold of $ATTEMPT_THRESHOLD"
        else
            echo "$FLAGGED" | awk '{printf "  %-18s %d attempts\n", $2, $1}'
        fi
        echo ""

        FLAGGED_COUNT=$(echo "$FLAGGED" | grep -v '^[[:space:]]*$' | wc -l)

        echo "--- Summary ---"
        printf "  Total failed attempts : %d\n" "$TOTAL"
        printf "  Unique source IPs     : %d\n" "$UNIQUE"
        printf "  Flagged IPs           : %d\n" "$FLAGGED_COUNT"
        echo "========================================"
    fi
} | tee "$REPORT_FILE"

echo ""
echo "Report saved: $REPORT_FILE"
