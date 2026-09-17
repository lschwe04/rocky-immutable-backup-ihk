#!/usr/bin/env bash
set -euo pipefail

# Umgebungsvariablen laden
source /etc/restic/aws_credentials.env

LOG_FILE="/var/log/restic_backup.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starte automatisches Restic-Backup..."

# Initialisierung des Repositories, falls noch nicht vorhanden
if ! restic snapshots >/dev/null 2>&1; then
    log "Initialisiere neues Restic Repository im S3 WORM Storage..."
    restic init >> "$LOG_FILE" 2>&1
fi

# Snapshots erstellen
log "Erstelle Backup von /var/www/html und /etc..."
restic backup /var/www/html /etc \
    --exclude="/etc/shadow" \
    --exclude="/etc/gshadow" \
    --tag "ihk-daily" >> "$LOG_FILE" 2>&1

# Pruning anwenden (Retention Policy)
log "Bereinige veraltete Snapshots (Prune Policy)..."
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune >> "$LOG_FILE" 2>&1

log "Backup erfolgreich abgeschlossen."
exit 0
