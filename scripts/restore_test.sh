#!/usr/bin/env bash
set -euo pipefail

# Umgebungsvariablen laden
source /etc/restic/aws_credentials.env

RESTORE_DIR="/tmp/restore_test_$(date +%s)"
MAX_RTO_SECONDS=300 # SLA Limit: 5 Minuten

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Trap für sauberes Cleanup im Fehlerfall
trap 'log "ERROR: Unerwarteter Abbruch. Säubere $RESTORE_DIR"; rm -rf "$RESTORE_DIR"; exit 1' ERR

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
log "Validiere Datenintegrität und Systemzustand..."

if [ ! -f "$RESTORE_DIR/etc/hosts" ] || [ ! -d "$RESTORE_DIR/var/www/html" ]; then
    log "ERROR [FAILURE]: Kritische Systemdateien fehlen nach Restore!"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

# 3.1 Syntax-Check der wiederhergestellten Nginx-Konfiguration
if [ -f "$RESTORE_DIR/etc/nginx/nginx.conf" ] && command -v nginx >/dev/null 2>&1; then
    log "Führe Nginx Syntax-Validierung der wiederhergestellten Konfiguration durch..."
    if ! nginx -t -c "$RESTORE_DIR/etc/nginx/nginx.conf" -g "pid /tmp/nginx_test.pid;"; then
        log "ERROR [FAILURE]: Wiederhergestellte Webserver-Konfiguration ist fehlerhaft!"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi
fi

# 3.2 SELinux Label Warnung (Rocky Linux / RHEL Spezifikum)
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
    log "INFO: SELinux ist aktiv. Nach einem echten Restore in die Root-Verzeichnisse muss 'restorecon -Rv /etc /var/www/html' ausgeführt werden."
fi

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
