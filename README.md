# AutoBOX 📦

Automated daily backup of `~/Documents` to Box.com using **rclone** + **macOS launchd**.

- ✅ One-way backup (never deletes from Box)
- ✅ Only uploads new/changed files — not a full re-upload every night
- ✅ Runs silently at **2:00 AM** via launchd
- ✅ **Self-healing**: Automatically retries 4x if the connection hangs or fails
- ✅ **Battery Aware**: Prevents idle sleep during backup, and aborts if unplugged and battery drops below 5%
- ✅ **Unified Logs**: Every run (manual or scheduled) is recorded in a daily log file
- ✅ **Desktop Tools**: One-click apps for managing, watching, and cancelling backups
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

> [!WARNING]
> **macOS Permissions (TCC) Rule:** You MUST use a hard copy (`cp`) for the script in `~/scripts/`. Do NOT use a symlink (`ln -s`) pointing to the script in your `Documents` folder. macOS will block `launchd` from reading symlinks inside protected folders like `Documents` and the backup will fail to start silently. 
> 
> **Updating:** If you edit `box-backup.sh` in this project folder, you must manually run the `cp` command above again to deploy your changes.

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

### 6. Create the Desktop Tools
I've created a folder on your Desktop called **Box Backup Tools** with these "one-click" apps:

1.  **Manual Backup.app**: Runs the backup script immediately in a visible Terminal window so you can see the live progress bar.
2.  **Watch Progress.app**: Opens a Terminal that tails the current log file. Use this to check on a nightly backup that is already running.
3.  **Cancel Backup.app**: Forces any running backup to stop and clears the "already running" lock file. Use this if a backup hangs or you need to stop it immediately.
4.  **View Logs.app**: Opens the `~/Library/Logs/box-backup/` folder in Finder.

Drag this folder to your Dock (on the right side near the Trash) to have a "pop-up" menu of your backup tools.

---

## Manual Backup

Double-click **Manual Backup.app** or run:
```bash
~/scripts/box-backup.sh
```

## Watch a Running Backup

Double-click **Watch Progress.app** or run:
```bash
tail -f ~/Library/Logs/box-backup/backup-$(date +%Y-%m-%d).log
```

> [!TIP]
> Pressing `Ctrl+C` in the "Watch Progress" window only stops the *viewing* of the log. To actually stop the backup process itself, use the **Cancel Backup.app**.

---

## Files

| File | Installed Location |
|---|---|
| `box-backup.sh` | `~/scripts/box-backup.sh` |
| `cancel-backup.sh` | `~/scripts/cancel-backup.sh` |
| `com.swardy.box-backup.plist` | `~/Library/LaunchAgents/com.swardy.box-backup.plist` |
| Logs | `~/Library/Logs/box-backup/` |
| Box destination | `box:Docs-Daily/` |
| Desktop Tools | `~/Desktop/Box Backup Tools/` |
