# Remove-Prefix

Ein kleines PowerShell-Skript für Windows 11, das einen definierten Prefix aus allen Dateinamen im selben Ordner entfernt.

## Beispiel

```
draft_chalkboard_2.zip  ->  chalkboard_2.zip
```

mit Prefix `draft_`

## Verwendung

Skript in den Ordner legen, in dem die betroffenen Dateien liegen, dann in PowerShell ausführen:

```powershell
# Testlauf - es wird nichts verändert, nur angezeigt was passieren würde
.\Remove-Prefix.ps1 -Prefix "draft_" -DryRun

# Tatsächliches Umbenennen
.\Remove-Prefix.ps1 -Prefix "draft_"
```

Falls PowerShell das Ausführen von Skripten blockiert, einmalig als Administrator:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Verhalten

- Betrachtet nur Dateien im selben Ordner wie das Skript (keine Unterordner).
- Nur Dateien, deren Name mit dem angegebenen Prefix beginnt, werden umbenannt.
- Existiert bereits eine Datei mit dem Zielnamen, wird die Umbenennung übersprungen und eine Warnung ausgegeben.
- `-DryRun` zeigt alle geplanten Änderungen an, ohne Dateien tatsächlich zu verändern.

## Hinweis

Dieses Skript wurde mit Unterstützung von [Claude](https://claude.ai) (Anthropic) erstellt.
