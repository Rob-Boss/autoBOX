# AutoBOX 📦

Automated daily backup of `~/Documents` to Box.com using **rclone** + **macOS launchd**.

- ✅ One-way backup (never deletes from Box)
- ✅ Only uploads new/changed files — not a full re-upload every night
- ✅ Runs silently at **2:00 AM** via launchd
- ✅ macOS notification on success or failure
- ✅ Live progress display when run manually

---

## What Gets Excluded

| Excluded | Reason |
|---|---|
| `node_modules/` | npm packages — reinstall with `npm install` |
| `.git/` | Git history — already on GitHub |
| `.venv/`, `venv/`, `*-venv/` | Python envs — reinstall with `pip install -r requirements.txt` |
| `__pycache__/` | Python bytecode — auto-regenerates |
| `.next/`, `dist/`, `.astro/` | Build output — regenerates with build command |
| `.DS_Store`, `*.cache` | macOS/system junk |

---

## Setup (Fresh Machine)

### 1. Install rclone
```bash
brew install rclone
```

### 2. Authenticate with Box
```bash
rclone config
```
Follow the prompts:
- `n` → New remote
- Name: `box` (must be exactly this)
- Storage type: `box`
- Client ID / Secret: press Enter (use defaults)
- Advanced config: `n`
- Auto config: `y` → log in via browser
- `q` to quit config

### 3. Install the backup script
```bash
mkdir -p ~/scripts
cp box-backup.sh ~/scripts/box-backup.sh
chmod +x ~/scripts/box-backup.sh
```

### 4. Install the launchd scheduler
```bash
cp com.swardy.box-backup.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.swardy.box-backup.plist
```

### 5. Schedule Mac to auto-wake at 1:55am (recommended)
Wakes the Mac 5 minutes before the backup fires — only works when plugged into power.
```bash
sudo pmset repeat wake MTWRFSU 01:55:00
```
To verify: `pmset -g sched`
To cancel: `sudo pmset repeat cancel`

### 6. (Optional) Create a Desktop launcher
```bash
osacompile -o ~/Desktop/Box\ Backup.app << 'EOF'
tell application "Terminal"
    activate
    do script "/Users/swardy/scripts/box-backup.sh"
end tell
EOF
```
Drag it to your Dock for one-click manual backups.

---

## Manual Backup

Double-click **Box Backup.app** in your Dock, or run:
```bash
~/scripts/box-backup.sh
```

## Watch a Running Backup
```bash
tail -f ~/Library/Logs/box-backup/backup-$(date +%Y-%m-%d).log
```

## Run Without Keeping Terminal Open
```bash
nohup ~/scripts/box-backup.sh &
```

---

## Files

| File | Installed Location |
|---|---|
| `box-backup.sh` | `~/scripts/box-backup.sh` |
| `com.swardy.box-backup.plist` | `~/Library/LaunchAgents/com.swardy.box-backup.plist` |
| Logs | `~/Library/Logs/box-backup/` |
| Box destination | `box:Docs-Daily/` |
