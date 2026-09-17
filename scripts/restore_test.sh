#!/usr/bin/env bash
set -euo pipefail

# Umgebungsvariablen laden
source /etc/restic/aws_credentials.env

RESTORE_DIR="/tmp/restore_test_$(date +%s)"
MAX_RTO_SECONDS=300 # SLA Limit: 5 Minuten

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starte SLA-konformen Disaster Recovery Test..."
START_TIME=$(date +%s)

# 1. Integritätscheck des Cloud-Speichers
log "Prüfe Repository-Integrität (5% Subset der Daten)..."
restic check --read-data-subset=5%

# 2. Restore des aktuellsten Backups
log "Führe Restore des aktuellen Snapshots nach $RESTORE_DIR aus..."
mkdir -p "$RESTORE_DIR"
restic restore latest --target "$RESTORE_DIR" --path "/etc" --path "/var/www/html"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 3. Funktionale und strukturelle Validierung
log "Validiere Datenintegrität der wiederhergestellten Artefakte..."

# Prüfe, ob kritische Web-Daten und Konfigurationen vorhanden sind
if [ ! -f "$RESTORE_DIR/etc/hosts" ]; then
    log "ERROR [FAILURE]: Kritische Datei /etc/hosts fehlt nach Restore!"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

if [ ! -d "$RESTORE_DIR/var/www/html" ]; then
    log "ERROR [FAILURE]: Web-Root /var/www/html wurde nicht wiederhergestellt!"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

# (Optional: Syntax-Check für wiederhergestellte Nginx/Apache-Configs könnte hier ergänzt werden)

# 4. RTO SLA Prüfung
if [ "$DURATION" -le "$MAX_RTO_SECONDS" ]; then
    log "SUCCESS [SLA COMPLIANT]: Restore und Validierung in ${DURATION}s abgeschlossen (Limit: ${MAX_RTO_SECONDS}s)."
    rm -rf "$RESTORE_DIR"
    exit 0
else
    log "WARNING [SLA BREACH]: Restore funktional erfolgreich, aber Dauer (${DURATION}s) überschreitet das RTO-Limit (${MAX_RTO_SECONDS}s)!"
    rm -rf "$RESTORE_DIR"
    exit 2
fi
