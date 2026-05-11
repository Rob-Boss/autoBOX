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
  # Node / JS
  --exclude "node_modules/**"
  # Git history (already on GitHub)
  --exclude ".git/**"
  # Python virtual environments
  --exclude ".venv/**"
  --exclude "venv/**"
  --exclude "*-venv/**"
  --exclude "*.venv/**"
  # Build output & caches
  --exclude ".DS_Store"
  --exclude "*.cache"
  --exclude "__pycache__/**"
  --exclude ".next/**"
  --exclude "dist/**"
  --exclude ".astro/**"
)

if [ -t 1 ]; then
  # ── Interactive (manual run) ──────────────────────────────
  echo "📦 Box Backup Starting..."
  echo "   Source:      $SOURCE"
  echo "   Destination: $DESTINATION"
  echo ""

  caffeinate -s rclone copy "$SOURCE" "$DESTINATION" \
    --progress \
    --transfers=4 \
    --checkers=8 \
    "${EXCLUDES[@]}"

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Backup completed: $(date)"
    osascript -e 'display notification "Documents backed up to Box successfully." with title "📦 Box Backup Complete" sound name "Glass"'
  else
    echo ""
    echo "❌ Backup failed (exit code $EXIT_CODE)"
    osascript -e 'display notification "Backup failed. Check terminal for details." with title "⚠️ Box Backup Failed" sound name "Basso"'
  fi

else
  # ── Headless (launchd nightly run) ───────────────────────
  echo "========================================" >> "$LOG_FILE"
  echo "Box Backup Started: $(date)" >> "$LOG_FILE"
  echo "========================================" >> "$LOG_FILE"

  caffeinate -s rclone copy "$SOURCE" "$DESTINATION" \
    --transfers=4 \
    --checkers=8 \
    --log-level=INFO \
    --log-file="$LOG_FILE" \
    --stats=60s \
    --stats-one-line \
    "${EXCLUDES[@]}"

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Backup completed: $(date)" >> "$LOG_FILE"
    osascript -e 'display notification "Documents backed up to Box successfully." with title "📦 Box Backup Complete" sound name "Glass"'
  else
    echo "❌ Backup failed (exit code $EXIT_CODE): $(date)" >> "$LOG_FILE"
    osascript -e 'display notification "Check ~/Library/Logs/box-backup for details." with title "⚠️ Box Backup Failed" sound name "Basso"'
  fi
fi
