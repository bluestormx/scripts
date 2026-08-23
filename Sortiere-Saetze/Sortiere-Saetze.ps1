<#
.SYNOPSIS
    Sortiert Datei-Saetze (ZIP + Bild) in eigene Ordner.

.DESCRIPTION
    Stufe 1: Scannt den Ordner, in dem das Skript liegt, nach ZIP-Dateien
             und erstellt fuer jede ZIP-Datei einen passend benannten Ordner.
             - Unterstriche werden durch Leerzeichen ersetzt
             - Die Zusaetze "4k" / "8k" werden entfernt
             - Jedes Wort wird gross geschrieben (Titel-Schreibweise)

    Stufe 2: Verschiebt jede ZIP-Datei zusammen mit allen Begleitdateien, die
             denselben Namen bzw. Namens-Anfang tragen (z.B. .png, .fbx,
             .blend, ...), in den in Stufe 1 erstellten Ordner. Die Endung
             spielt dabei keine Rolle.

    Beide Stufen unterstuetzen -DryRun, um vorher zu pruefen, was passieren wuerde,
    ohne dass etwas angelegt oder verschoben wird.

.PARAMETER Stage
    1 = nur Ordner erstellen
    2 = nur Dateien verschieben (Ordner muessen bereits existieren)

.PARAMETER DryRun
    Wenn gesetzt, werden nur die geplanten Aktionen angezeigt, es wird
    nichts angelegt oder verschoben.

.EXAMPLE
    .\Sortiere-Saetze.ps1 -Stage 1 -DryRun
    .\Sortiere-Saetze.ps1 -Stage 1
    .\Sortiere-Saetze.ps1 -Stage 2 -DryRun
    .\Sortiere-Saetze.ps1 -Stage 2
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(1, 2)]
    [int]$Stage,

    [switch]$DryRun
)

# Ordner, in dem das Skript selbst liegt
$RootPath = $PSScriptRoot

function Get-CleanFolderName {
    param([string]$BaseName)

    $name = $BaseName

    # Unterstriche durch Leerzeichen ersetzen
    $name = $name -replace '_', ' '

    # 4k / 8k Zusaetze inkl. davorstehendem Trenner (Leerzeichen/Bindestrich)
    # entfernen, damit keine Reste wie "Table 5-" uebrig bleiben
    $name = $name -replace '(?i)[\s-]*\b4k\b', ''
    $name = $name -replace '(?i)[\s-]*\b8k\b', ''

    # Mehrfache Leerzeichen zusammenfassen und trimmen
    $name = $name -replace '\s+', ' '
    $name = $name.Trim()

    # Jedes Wort gross schreiben (Titel-Schreibweise)
    $culture = Get-Culture
    $name = $culture.TextInfo.ToTitleCase($name.ToLower())

    return $name
}

function Get-ZipFiles {
    Get-ChildItem -LiteralPath $RootPath -File -Filter '*.zip'
}

function Get-ImageMatchBaseName {
    param([string]$BaseName)

    # Entfernt einen abschliessenden 4k/8k-Zusatz (mit optionalem Trenner davor),
    # da Begleitdateien (Bilder, .fbx, .blend, ...) diesen Zusatz oft nicht
    # im Dateinamen haben.
    # Beispiel: "office_notepads_4k" -> "office_notepads"
    $name = $BaseName -replace '(?i)[_\s-]*(4k|8k)\s*$', ''
    return $name.Trim()
}

function Test-BelongsToGroup {
    param(
        [string]$FileBaseName,
        [string]$GroupKey
    )

    # 1) Exakte Uebereinstimmung mit dem Gruppen-Schluessel
    if ($FileBaseName -eq $GroupKey) { return $true }

    # 2) Uebereinstimmung nach Entfernen eines eigenen 4k/8k-Zusatzes
    #    (z.B. weitere ZIP-Variante "table_1-vxd-8K")
    $stripped = Get-ImageMatchBaseName -BaseName $FileBaseName
    if ($stripped -eq $GroupKey) { return $true }

    # 3) Praefix-Uebereinstimmung mit klarer Trennung danach
    #    (z.B. "table_1-vxd_preview" gehoert zu "table_1-vxd")
    if ($stripped -match "^$([regex]::Escape($GroupKey))[_\-\s.]") { return $true }

    return $false
}

# ---------------------------------------------------------------------------
# STUFE 1: Ordner anhand der ZIP-Dateien anlegen
# ---------------------------------------------------------------------------
function Invoke-Stage1 {
    $zipFiles = Get-ZipFiles

    if (-not $zipFiles) {
        Write-Host "Keine ZIP-Dateien in '$RootPath' gefunden." -ForegroundColor Yellow
        return
    }

    Write-Host "=== STUFE 1: Ordner-Erstellung ($(if($DryRun){'DRYRUN'}else{'AUSFUEHRUNG'})) ===" -ForegroundColor Cyan

    foreach ($zip in $zipFiles) {
        $baseName   = $zip.BaseName
        $folderName = Get-CleanFolderName -BaseName $baseName
        $targetPath = Join-Path -Path $RootPath -ChildPath $folderName

        if (Test-Path -LiteralPath $targetPath) {
            Write-Host "  [existiert bereits] '$folderName'"
            continue
        }

        if ($DryRun) {
            Write-Host "  [WUERDE ANLEGEN] '$folderName'  (aus: $($zip.Name))" -ForegroundColor Gray
        }
        else {
            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
            Write-Host "  [ANGELEGT] '$folderName'  (aus: $($zip.Name))" -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------------------------
# STUFE 2: ZIP + alle zugehoerigen Begleitdateien in den passenden Ordner
#          verschieben (endungsunabhaengig)
# ---------------------------------------------------------------------------
function Invoke-Stage2 {
    $zipFiles = Get-ZipFiles

    if (-not $zipFiles) {
        Write-Host "Keine ZIP-Dateien in '$RootPath' gefunden." -ForegroundColor Yellow
        return
    }

    Write-Host "=== STUFE 2: Dateien verschieben ($(if($DryRun){'DRYRUN'}else{'AUSFUEHRUNG'})) ===" -ForegroundColor Cyan

    # Gruppen-Schluessel je Satz ermitteln (4k/8k entfernt), Duplikate vermeiden
    # z.B. "table_1-vxd-4K.zip" und "table_1-vxd-8K.zip" -> beide "table_1-vxd"
    $groupKeys = $zipFiles |
        ForEach-Object { Get-ImageMatchBaseName -BaseName $_.BaseName } |
        Select-Object -Unique

    foreach ($groupKey in $groupKeys) {
        $folderName = Get-CleanFolderName -BaseName $groupKey
        $targetPath = Join-Path -Path $RootPath -ChildPath $folderName

        if (-not (Test-Path -LiteralPath $targetPath)) {
            Write-Host "  [ORDNER FEHLT] '$folderName' existiert nicht (erst Stufe 1 ausfuehren) -> uebersprungen" -ForegroundColor Yellow
            continue
        }

        # Alle Dateien im Root-Ordner finden, die zu diesem Satz gehoeren -
        # unabhaengig von der Dateiendung (.zip, .png, .fbx, .blend, ...)
        $groupFiles = Get-ChildItem -LiteralPath $RootPath -File |
            Where-Object { Test-BelongsToGroup -FileBaseName $_.BaseName -GroupKey $groupKey }

        if (-not $groupFiles) {
            Write-Host "  [KEINE DATEIEN GEFUNDEN] fuer Satz '$groupKey' -> uebersprungen" -ForegroundColor Yellow
            continue
        }

        foreach ($file in $groupFiles) {
            $target = Join-Path -Path $targetPath -ChildPath $file.Name

            if ($DryRun) {
                Write-Host "  [WUERDE VERSCHIEBEN] '$($file.Name)' -> '$folderName'" -ForegroundColor Gray
            }
            else {
                Move-Item -LiteralPath $file.FullName -Destination $target -Force
                Write-Host "  [VERSCHOBEN] '$($file.Name)' -> '$folderName'" -ForegroundColor Green
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Ausfuehrung
# ---------------------------------------------------------------------------
switch ($Stage) {
    1 { Invoke-Stage1 }
    2 { Invoke-Stage2 }
}

Write-Host ""
Write-Host "Fertig." -ForegroundColor Cyan
