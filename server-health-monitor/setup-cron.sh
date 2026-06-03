#!/bin/bash
# Adds monitor.sh to crontab to run every 5 minutes.
# Run once: bash setup-cron.sh

SCRIPT_PATH="$(realpath "$(dirname "$0")/monitor.sh")"
CRON_JOB="*/5 * * * * $SCRIPT_PATH"

# Check if already added
if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "Cron job already exists:"
    crontab -l | grep "$SCRIPT_PATH"
    exit 0
fi

# Add to existing crontab (preserving other jobs)
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo "Cron job added: $CRON_JOB"
