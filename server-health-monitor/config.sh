# Thresholds (%)
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=85

# Services to monitor (systemd service names)
SERVICES=("ssh" "cron")

# Log directory (relative to script location)
LOG_DIR="$(dirname "$0")/logs"
