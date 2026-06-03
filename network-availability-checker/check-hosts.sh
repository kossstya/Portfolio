#!/bin/bash
# network-availability-checker/check-hosts.sh
# Pings hosts and checks TCP ports from hosts.conf.
# Tracks state changes (UP/DOWN) — alerts only when status actually changes.
# Cron example: * * * * * /path/to/check-hosts.sh

source "$(dirname "$0")/config.sh"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/status.log"
ALERT_FILE="$LOG_DIR/alerts.log"

log()   { echo "[$TIMESTAMP] $1" >> "$LOG_FILE"; }
alert() { echo "[$TIMESTAMP] ALERT: $1" | tee -a "$ALERT_FILE" >> "$LOG_FILE"; }

# --- Ping check ---
check_ping() {
    ping -c1 -W"$PING_TIMEOUT" "$1" &>/dev/null
}

# --- Port check via bash built-in /dev/tcp (no netcat needed) ---
check_port() {
    local host="$1" port="$2"
    (echo > /dev/tcp/"$host"/"$port") 2>/dev/null
}

if [ ! -f "$HOSTS_CONF" ]; then
    echo "ERROR: hosts.conf not found: $HOSTS_CONF" >&2
    exit 1
fi

UP_COUNT=0
DOWN_COUNT=0

# --- Main loop ---
while IFS=' ' read -r HOST PORT LABEL; do
    # Skip comments and empty lines
    [[ "$HOST" =~ ^#|^[[:space:]]*$ ]] && continue
    [ -z "$HOST" ] || [ -z "$PORT" ] && continue

    LABEL="${LABEL:-$HOST:$PORT}"

    # State file in /tmp — tracks last known status across runs
    # Filename is sanitized to avoid path issues with special chars
    STATE_KEY="${HOST//[^a-zA-Z0-9]/_}_${PORT}"
    STATE_FILE="/tmp/nac_${STATE_KEY}"
    PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "UNKNOWN")

    # Step 1: ping
    if ! check_ping "$HOST"; then
        log "DOWN | $LABEL | $HOST:$PORT | host unreachable"
        [ "$PREV_STATE" != "DOWN" ] && alert "$LABEL ($HOST) is unreachable — was $PREV_STATE"
        echo "DOWN" > "$STATE_FILE"
        ((DOWN_COUNT++))
        continue
    fi

    # Step 2: port check
    if check_port "$HOST" "$PORT"; then
        log "UP   | $LABEL | $HOST:$PORT"
        [ "$PREV_STATE" = "DOWN" ] && alert "$LABEL ($HOST:$PORT) recovered — back UP"
        echo "UP" > "$STATE_FILE"
        ((UP_COUNT++))
    else
        log "DOWN | $LABEL | $HOST:$PORT | port $PORT closed"
        [ "$PREV_STATE" != "DOWN" ] && alert "$LABEL ($HOST:$PORT) port $PORT is unreachable — was $PREV_STATE"
        echo "DOWN" > "$STATE_FILE"
        ((DOWN_COUNT++))
    fi

done < "$HOSTS_CONF"

log "SUMMARY | UP: $UP_COUNT  DOWN: $DOWN_COUNT"
log "--- scan complete ---"
