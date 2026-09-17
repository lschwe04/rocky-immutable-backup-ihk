#!/usr/bin/env bash
set -euo pipefail

# Umgebungsvariablen laden
source /etc/restic/aws_credentials.env

RESTORE_DIR="/tmp/restore_test_$(date +%s)"
MAX_RTO_SECONDS=300 # SLA Limit: 5 Minuten für Systemkonfiguration

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starte SLA-konformen Disaster Recovery Test..."
START_TIME=$(date +%s)

# Integritätscheck des S3-Buckets
log "Prüfe Repository-Integrität (5% Subset)..."
restic check --read-data-subset=5%

# Restore des aktuellsten Backups
log "Führe Restore des aktuellen Snapshots nach $RESTORE_DIR aus..."
mkdir -p "$RESTORE_DIR"
restic restore latest --target "$RESTORE_DIR" --path "/etc"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Validierung der wiederhergestellten Daten
if [ -f "$RESTORE_DIR/etc/hosts" ]; then
    if [ "$DURATION" -le "$MAX_RTO_SECONDS" ]; then
        log "SUCCESS [SLA COMPLIANT]: Restore in ${DURATION}s abgeschlossen (Limit: ${MAX_RTO_SECONDS}s). Daten verifiziert."
        rm -rf "$RESTORE_DIR"
        exit 0
    else
        log "WARNING [SLA BREACH]: Restore erfolgreich, aber Dauer (${DURATION}s) überschreitet RTO-Limit (${MAX_RTO_SECONDS}s)!"
        rm -rf "$RESTORE_DIR"
        exit 2
    fi
else
    log "ERROR [FAILURE]: Kritische Datei /etc/hosts fehlt nach Restore!"
    rm -rf "$RESTORE_DIR"
    exit 1
fi
