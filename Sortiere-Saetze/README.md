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

- **Stufe 2** – Verschiebt die ZIP-Datei zusammen mit **allen Begleitdateien**,
  die denselben Namen bzw. Namens-Anfang tragen, in den in Stufe 1 erstellten
  Ordner. Die Dateiendung spielt dabei keine Rolle (`.png`, `.jpg`, `.fbx`,
  `.blend`, `.psd`, usw.) – es werden also nicht nur zwei, sondern beliebig
  viele zusammengehörige Dateien pro Satz erkannt und verschoben. Auch mehrere
  ZIP-Varianten (z.B. `4k`- und `8k`-Version) desselben Satzes werden erkannt.

  Beispiel:
  ```
  table_1-vxd-4K.zip
  table_1-vxd.fbx
  table_1-vxd.blend
  ```
  → alle drei Dateien landen im Ordner `Table 1 Vxd`

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

- Fehlt zu einem Satz der zugehörige Ordner (Stufe 1 noch nicht ausgeführt),
  wird der komplette Satz übersprungen und im Konsolen-Log entsprechend
  markiert.
- Werden zu einem Namens-Anfang keine weiteren Dateien gefunden, wird das
  ebenfalls im Log vermerkt.
- Bereits existierende Ordner werden in Stufe 1 nicht erneut angelegt.
- Stage 2 arbeitet ausschließlich mit Dateien im selben Ordner wie das Skript
  (keine Unterordner werden durchsucht).

---

*Erstellt mit Claude.*
