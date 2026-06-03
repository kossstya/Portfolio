#!/bin/bash
# server-health-monitor/monitor.sh
# Checks CPU, RAM, disk, and service status. Logs results and alerts on threshold breach.
# Cron example: */5 * * * * /path/to/monitor.sh

source "$(dirname "$0")/config.sh"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/health.log"
ALERT_FILE="$LOG_DIR/alerts.log"

log()   { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; }
alert() { echo "[$TIMESTAMP] ALERT: $1" | tee -a "$ALERT_FILE" >> "$LOG_FILE"; }

# --- CPU ---
# vmstat 1 2: runs vmstat twice with 1s interval, take last line (actual average)
CPU_IDLE=$(vmstat 1 2 | tail -1 | awk '{print $15}')
CPU_USED=$((100 - CPU_IDLE))
log "CPU: ${CPU_USED}%"
[ "$CPU_USED" -ge "$CPU_THRESHOLD" ] && alert "CPU is ${CPU_USED}% (threshold: ${CPU_THRESHOLD}%)"

# --- RAM ---
# LANG=C forces English output regardless of system locale
RAM_TOTAL=$(LANG=C free -m | awk '/^Mem:/{print $2}')
RAM_USED=$(LANG=C free -m  | awk '/^Mem:/{print $3}')
RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
log "RAM: ${RAM_PCT}% (${RAM_USED}MB / ${RAM_TOTAL}MB)"
[ "$RAM_PCT" -ge "$RAM_THRESHOLD" ] && alert "RAM is ${RAM_PCT}% (threshold: ${RAM_THRESHOLD}%)"

# --- Disk ---
# Loop over all real block devices, skip tmpfs/loop etc.
while IFS= read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    log "Disk $MOUNT: ${USAGE}%"
    [ "$USAGE" -ge "$DISK_THRESHOLD" ] && alert "Disk $MOUNT is ${USAGE}% full (threshold: ${DISK_THRESHOLD}%)"
done < <(df -h | awk 'NR>1 && $1 ~ /^\/dev\// {print}')

# --- Services ---
for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$SERVICE"; then
        log "Service [$SERVICE]: running"
    else
        alert "Service [$SERVICE] is NOT running"
    fi
done

log "--- check complete ---"
