#!/bin/bash
# ============================================================
#  Box.com Daily Documents Backup
#  Destination: Box:/Docs-Daily/
#  Method: rclone copy (one-way, never deletes from Box)
#  Scheduled: Daily at 2:00 AM via launchd
# ============================================================

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SOURCE="$HOME/Documents/"
DESTINATION="box:Docs-Daily"
LOG_DIR="$HOME/Library/Logs/box-backup"
LOG_FILE="$LOG_DIR/backup-$(date +%Y-%m-%d).log"

mkdir -p "$LOG_DIR"

# ── Lock file: prevent duplicate concurrent runs ──────────────
LOCKFILE="/tmp/box-backup.lock"
if [ -f "$LOCKFILE" ] && ps -p "$(cat "$LOCKFILE")" > /dev/null 2>&1; then
  echo "⚠️  Backup already running (PID $(cat "$LOCKFILE")). Skipping this run." | tee -a "$LOG_FILE"
  exit 0
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT
# ─────────────────────────────────────────────────────────────

EXCLUDES=(
  --exclude "node_modules/**"
  --exclude ".git/**"
  --exclude ".venv/**"
  --exclude "venv/**"
  --exclude "*-venv/**"
  --exclude "*.venv/**"
  --exclude ".DS_Store"
  --exclude "*.cache"
  --exclude "__pycache__/**"
  --exclude ".next/**"
  --exclude "dist/**"
  --exclude ".astro/**"
)

# Resilience Settings
MAX_RETRIES=4
RETRY_DELAY=30
TIMEOUT_FLAGS="--timeout 5m --contimeout 1m"

run_backup() {
  local attempt=$1
  local mode_tag=$2

  # Common rclone flags
  local rclone_args=(
    "copy" "$SOURCE" "$DESTINATION"
    --transfers=4
    --checkers=8
    --log-level=INFO
    --log-file="$LOG_FILE"
    $TIMEOUT_FLAGS
    "${EXCLUDES[@]}"
  )

  if [ -t 1 ]; then
    # ── Interactive Mode ──────────────────────────────
    if [ $attempt -gt 1 ]; then echo "🔄 Retry Attempt $attempt/$MAX_RETRIES..."; fi
    
    caffeinate -s rclone "${rclone_args[@]}" --progress
  else
    # ── Headless Mode ─────────────────────────────────
    echo "Attempt $attempt Started ($mode_tag): $(date)" >> "$LOG_FILE"
    
    caffeinate -s rclone "${rclone_args[@]}" --stats=60s --stats-one-line
  fi
}

# ── Main Loop ────────────────────────────────────────────────
SUCCESS=false
MODE="SCHEDULED"
if [ -t 1 ]; then MODE="MANUAL"; fi

for ((i=1; i<=MAX_RETRIES; i++)); do
  if [ $i -eq 1 ]; then
    echo "========================================" >> "$LOG_FILE"
    echo "Box Backup Started [$MODE]: $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    if [ "$MODE" = "MANUAL" ]; then
      echo "📦 Box Backup Starting..."
      echo "   Source:      $SOURCE"
      echo "   Destination: $DESTINATION"
      echo "   Log File:    $LOG_FILE"
      echo ""
    fi
  fi

  run_backup $i "$MODE"
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    SUCCESS=true
    break
  else
    if [ $i -lt $MAX_RETRIES ]; then
      echo "❌ Attempt $i failed (code $EXIT_CODE). Retrying in ${RETRY_DELAY}s..." | tee -a "$LOG_FILE"
      sleep $RETRY_DELAY
    fi
  fi
done

# ── Final Status ─────────────────────────────────────────────
if [ "$SUCCESS" = true ]; then
  FINAL_MSG="✅ Backup completed successfully: $(date)"
  echo "$FINAL_MSG" >> "$LOG_FILE"
  
  if [ "$MODE" = "MANUAL" ]; then
    echo ""
    echo "$FINAL_MSG"
  fi
  osascript -e 'display notification "Documents backed up to Box successfully." with title "📦 Box Backup Complete" sound name "Glass"'
else
  FINAL_MSG="🚫 Backup failed after $MAX_RETRIES attempts: $(date)"
  echo "$FINAL_MSG" >> "$LOG_FILE"

  if [ "$MODE" = "MANUAL" ]; then
    echo ""
    echo "$FINAL_MSG"
  fi
  osascript -e 'display notification "Backup failed after multiple attempts." with title "⚠️ Box Backup Failed" sound name "Basso"'
  exit 1
fi
