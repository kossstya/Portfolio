#!/bin/bash
# Adds check-logins.sh to crontab to run every day at 08:00.
# Run once: sudo bash setup-cron.sh

SCRIPT_PATH="$(realpath "$(dirname "$0")/check-logins.sh")"
CRON_JOB="0 8 * * * $SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "Cron job already exists:"
    crontab -l | grep "$SCRIPT_PATH"
    exit 0
fi

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo "Cron job added: $CRON_JOB"
