# Path to SSH auth log
AUTH_LOG="/var/log/auth.log"

# Flag IP if it has this many failed attempts or more
ATTEMPT_THRESHOLD=5

# Where to store daily reports
REPORT_DIR="$(dirname "$0")/reports"
