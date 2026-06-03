#!/bin/bash
# Adds check-hosts.sh to crontab to run every minute.
# Run once: bash setup-cron.sh

SCRIPT_PATH="$(realpath "$(dirname "$0")/check-hosts.sh")"
CRON_JOB="* * * * * $SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "Cron job already exists:"
    crontab -l | grep "$SCRIPT_PATH"
    exit 0
fi

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo "Cron job added: $CRON_JOB"
