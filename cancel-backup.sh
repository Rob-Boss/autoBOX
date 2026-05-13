#!/bin/bash
# ============================================================
#  Force Stop Box Backup
# ============================================================

LOCKFILE="/tmp/box-backup.lock"

echo "🛑 Stopping Box Backup processes..."

# 1. Kill the main script if running
if [ -f "$LOCKFILE" ]; then
    PID=$(cat "$LOCKFILE")
    echo "   Killing main script (PID $PID)"
    kill -9 "$PID" 2>/dev/null
    rm -f "$LOCKFILE"
fi

# 2. Kill rclone processes specific to this backup
echo "   Killing rclone transfers..."
pkill -f "rclone copy.*box:Docs-Daily"

# 3. Kill caffeinate
echo "   Releasing power management..."
pkill -f "caffeinate -s rclone"

osascript -e 'display notification "Backup processes terminated and lock file cleared." with title "🛑 Box Backup Cancelled" sound name "Basso"'

echo "✅ Done."
