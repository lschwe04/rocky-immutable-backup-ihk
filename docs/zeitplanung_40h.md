# Zeitplanung IHK-Abschlussprojekt (40 Stunden)

Das Projekt wird nach dem Wasserfall-Modell mit agilen Elementen (iteratives Testing) in fünf Hauptphasen gegliedert.

## 1. Analyse und Planung (10 Stunden)
- Ist-Analyse der bestehenden Backup-Prozesse und Schutzbedarfsfeststellung: 2h
- Erstellung Soll-Konzept und Definition von RTO/RPO-Zielen: 2h
- Make-or-Buy-Entscheidung (Cloud vs. On-Premise) & TCO-Berechnung: 3h
- Nutzwertanalyse der Backup-Software (Restic vs. Borg vs. Duplicati): 2h
- Architektur- und Security-Design (S3 WORM, IAM Least Privilege): 1h

## 2. Realisierung (14 Stunden)
- Programmierung der AWS S3 Cloud-Infrastruktur (Terraform): 3h
- Implementierung der Base-Hardening-Rollen via Ansible: 3h
- Entwicklung der Backup-Rollen und Secret-Management (Ansible Vault): 4h
- Erstellung der Bash-Automatisierung (`execute_pull_backup.sh`): 4h

## 3. Qualitätssicherung / Testing (6 Stunden)
- Entwicklung des automatisierten SLA-Restore-Tests (`restore_test.sh`): 3h
- Durchführung von Funktionstests (Webserver-Recovery): 2h
- Verifizierung der Immutability (Simulierter Ransomware-Angriff auf S3): 1h

## 4. Dokumentation (10 Stunden)
- Erstellung der prozessorientierten IHK-Projektdokumentation: 8h
- Erstellung einer kurzen Betriebsanweisung für Administratoren: 2h

**Gesamtzeitaufwand: 40 Stunden**
