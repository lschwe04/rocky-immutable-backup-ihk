# Wirtschaftlichkeits- und TCO-Analyse (3-Jahres-Betrachtung)

Im Rahmen der Make-or-Buy-Entscheidung wurde evaluiert, ob die bestehenden Daten (ca. 500 GB Grundbestand, 5 GB tägliches Delta) über ein lokales LTO-Tape-Laufwerk (On-Premise) oder über eine Cloud-Native WORM-Lösung (AWS S3 Object Lock) gesichert werden sollen.

## 1. Total Cost of Ownership (TCO) über 36 Monate

| Kostenfaktor | Variante A: On-Premise (LTO-8 Laufwerk + NAS) | Variante B: Cloud-Hybrid (AWS S3 WORM) |
| :--- | :--- | :--- |
| **Hardware (Capex)** | 3.200,00 € (SAS-Laufwerk, Controller, NAS-Cache) | 0,00 € (Nutzung bestehender Server) |
| **Medien** | 350,00 € (10x LTO-8 Tapes) | 0,00 € |
| **Storage (Opex, 3 Jahre)**| 0,00 € | ~ 610,00 € (0,024 € / GB bei avg. 850 GB Speichernutzung) |
| **API & Traffic (Opex, 3 J.)**| 0,00 € | ~ 140,00 € (S3 PUT/GET Requests & Restore-Tests) |
| **Wartung / Strom / RZ (3 J.)**| 450,00 € | 0,00 € (SaaS durch AWS) |
| **Gesamtkosten (TCO)** | **4.000,00 €** | **750,00 €** |

**Entscheidung:** Variante B (Cloud) bietet eine Kosteneinsparung von 81,25 %. Zusätzlich erfordert Variante A einen manuellen Medienwechsel (Personalaufwand, Fehleranfälligkeit), weshalb die Entscheidung auf AWS S3 fällt.

## 2. Nutzwertanalyse Backup-Software
Es wurde bewertet, welches Tool die Übertragung in den S3-Speicher übernimmt (Gewichtung in Klammern, Punkte 1-5).

| Kriterium | Restic | BorgBackup | Duplicati |
| :--- | :--- | :--- | :--- |
| **Native S3 Unterstützung (30%)** | 5 (1,5) | 1 (0,3 - benötigt Wrapper) | 4 (1,2) |
| **Deduplizierungs-Effizienz (30%)** | 4 (1,2) | 5 (1,5) | 3 (0,9) |
| **Security / Encryption (20%)** | 5 (1,0) | 5 (1,0) | 4 (0,8) |
| **Headless CLI & Automatisierung (20%)**| 5 (1,0) | 5 (1,0) | 2 (0,4 - stark GUI-fokussiert) |
| **Gesamtscore** | **4,7** | **3,8** | **3,3** |

**Entscheidung:** Restic wird als Backup-Lösung implementiert, da es im Gegensatz zu BorgBackup natively mit der S3-API und Object Lock kommunizieren kann.
