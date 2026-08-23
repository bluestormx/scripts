# Sortiere-Saetze.ps1

PowerShell-Skript für Windows 11, das Datei-Sätze aus einer ZIP-Datei und einem
dazugehörigen Bild automatisch in passend benannte Ordner sortiert.

## Funktionsweise

Das Skript arbeitet in zwei Stufen:

- **Stufe 1** – Scannt den Ordner, in dem das Skript liegt, nach `*.zip`-Dateien
  und erstellt für jede ZIP-Datei einen Ordner. Der Ordnername wird dabei
  bereinigt:
  - Unterstriche `_` werden durch Leerzeichen ersetzt
  - Die Zusätze `4k` / `8k` werden entfernt
  - Jedes Wort wird groß geschrieben (Titel-Schreibweise)

  Beispiel: `office_notepads_4k.zip` → Ordner `Office Notepads`

- **Stufe 2** – Verschiebt jede ZIP-Datei zusammen mit dem passenden Bild
  (`.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.webp`, `.tiff`) in den in Stufe 1
  erstellten Ordner. Das Bild wird zuerst mit identischem Dateinamen gesucht;
  falls keins gefunden wird, zusätzlich ohne den `4k`/`8k`-Zusatz.

  Beispiel: `office_notepads_4k.zip` + `office_notepads.png` → beide landen in
  `Office Notepads`

Beide Stufen unterstützen `-DryRun`, um vorab zu prüfen, was passieren würde,
ohne dass etwas angelegt oder verschoben wird.

## Verwendung

Skript in den Ordner mit den ZIP- und Bilddateien legen, dann in PowerShell:

```powershell
# Stufe 1 – Ordner erstellen
.\Sortiere-Saetze.ps1 -Stage 1 -DryRun    # Vorschau
.\Sortiere-Saetze.ps1 -Stage 1            # ausführen

# Stufe 2 – Dateien verschieben
.\Sortiere-Saetze.ps1 -Stage 2 -DryRun    # Vorschau
.\Sortiere-Saetze.ps1 -Stage 2            # ausführen
```

### Ausführung erlauben

Falls Windows die Ausführung mit `UnauthorizedAccess` blockiert, einmalig pro
Sitzung:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

oder dauerhaft für den eigenen Benutzer:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## Voraussetzungen

- Windows 11
- PowerShell (integriert)
- ZIP- und Bilddatei eines Satzes liegen im selben Ordner wie das Skript

## Hinweise

- Fehlt zu einer ZIP-Datei ein passendes Bild oder der zugehörige Ordner
  (Stufe 1 noch nicht ausgeführt), wird der Satz übersprungen und im
  Konsolen-Log entsprechend markiert.
- Bereits existierende Ordner werden in Stufe 1 nicht erneut angelegt.

---

*Erstellt mit Claude.*
