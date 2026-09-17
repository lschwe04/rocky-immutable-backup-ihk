# Service Level Objectives (SLO) und Business Impact

Basierend auf der Business Impact Analysis (BIA) für den Web- und Konfigurationsserver wurden folgende Service Level Agreements (SLA) definiert und technisch im Projekt umgesetzt.

## 1. Recovery Point Objective (RPO)
Das RPO definiert den maximal tolerierbaren Datenverlust.
- **Kritikalität:** Änderungen an der Webpräsenz (`/var/www/html`) und Systemkonfiguration (`/etc`) finden maximal einmal täglich statt.
- **Geschäftliche Anforderung:** Max. 24 Stunden RPO.
- **Technische Umsetzung:** Die Erreichung wird durch den Systemd-Timer (`restic-backup.timer`) garantiert, welcher starr täglich um 02:00 Uhr auslöst.

## 2. Recovery Time Objective (RTO)
Das RTO definiert die maximale Ausfallzeit, bis die gesicherten Dienste nach einem Totalausfall wieder operativ sind.
- **Kritikalität:** Bei Ausfall des Webportals entstehen Reputationsverluste. Die Wiederherstellung der Rohdaten muss binnen 5 Minuten möglich sein.
- **Geschäftliche Anforderung:** Max. 300 Sekunden RTO.
- **Technische Überwachung:** Das Skript `restore_test.sh` simuliert wöchentlich den Ausfall, stoppt die Dauer des Daten-Restores und wertet diese gegen einen Schwellenwert (`MAX_RTO_SECONDS=300`) aus. Die Validierung umfasst zudem einen echten Syntax-Check der wiederhergestellten Nginx-Dienste.

## 3. Compliance, WORM & Exfiltrations-Schutz (Datensicherheit)
- **Ransomware-Schutz:** Um DSGVO-Konformität sicherzustellen, wird Object Lock im `COMPLIANCE`-Modus für 30 Tage erzwungen. Selbst Root-Administratoren können Backups in diesem Zeitraum nicht mutieren.
- **Verschlüsselung:** Alle Backups werden vor dem Upload durch Restic per AES-256 (Client-Side) sowie durch AWS S3 (Server-Side) verschlüsselt.
- **Schutz vor Datenabfluss (Exfiltration):** Sollte der lokale Backup-Server kompromittiert und die Credentials gestohlen werden, verhindert eine IAM-Policy mit striktem IP-Whitelisting (`aws:SourceIp`), dass ein Angreifer Backups von außerhalb des definierten Firmennetzwerks herunterladen kann. Zudem blockiert ein Terraform `PublicAccessBlock` jegliche öffentliche S3-Exposition.
