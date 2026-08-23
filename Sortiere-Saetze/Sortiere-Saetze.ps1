<#
.SYNOPSIS
    Sortiert Datei-Saetze (ZIP + Bild) in eigene Ordner.

.DESCRIPTION
    Stufe 1: Scannt den Ordner, in dem das Skript liegt, nach ZIP-Dateien
             und erstellt fuer jede ZIP-Datei einen passend benannten Ordner.
             - Unterstriche werden durch Leerzeichen ersetzt
             - Die Zusaetze "4k" / "8k" werden entfernt
             - Jedes Wort wird gross geschrieben (Titel-Schreibweise)

    Stufe 2: Verschiebt jede ZIP-Datei zusammen mit dem dazugehoerigen Bild
             (gleicher Dateiname, andere Endung) in den in Stufe 1 erstellten
             Ordner.

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

# Erlaubte Bild-Endungen, die zu einer ZIP-Datei gehoeren koennen
$ImageExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.tiff')

function Get-CleanFolderName {
    param([string]$BaseName)

    $name = $BaseName

    # Unterstriche durch Leerzeichen ersetzen
    $name = $name -replace '_', ' '

    # 4k / 8k Zusaetze entfernen (als eigenes "Wort", Gross-/Kleinschreibung egal)
    $name = $name -replace '(?i)\b4k\b', ''
    $name = $name -replace '(?i)\b8k\b', ''

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
    # da die Bilder diesen Zusatz oft nicht im Dateinamen haben.
    # Beispiel: "office_notepads_4k" -> "office_notepads"
    $name = $BaseName -replace '(?i)[_\s-]*(4k|8k)\s*$', ''
    return $name.Trim()
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
# STUFE 2: ZIP + Bild in den passenden Ordner verschieben
# ---------------------------------------------------------------------------
function Invoke-Stage2 {
    $zipFiles = Get-ZipFiles

    if (-not $zipFiles) {
        Write-Host "Keine ZIP-Dateien in '$RootPath' gefunden." -ForegroundColor Yellow
        return
    }

    Write-Host "=== STUFE 2: Dateien verschieben ($(if($DryRun){'DRYRUN'}else{'AUSFUEHRUNG'})) ===" -ForegroundColor Cyan

    foreach ($zip in $zipFiles) {
        $baseName   = $zip.BaseName
        $folderName = Get-CleanFolderName -BaseName $baseName
        $targetPath = Join-Path -Path $RootPath -ChildPath $folderName

        # Passendes Bild suchen. Erst mit identischem Basisnamen versuchen,
        # falls nichts gefunden wird, ohne 4k/8k-Zusatz erneut versuchen
        # (z.B. "office_notepads_4k.zip" -> "office_notepads.png").
        $imageMatchBase = Get-ImageMatchBaseName -BaseName $baseName

        $image = Get-ChildItem -LiteralPath $RootPath -File |
            Where-Object {
                $ImageExtensions -contains $_.Extension.ToLower() -and
                ($_.BaseName -eq $baseName -or $_.BaseName -eq $imageMatchBase)
            } | Select-Object -First 1

        if (-not $image) {
            Write-Host "  [KEIN BILD GEFUNDEN] fuer '$($zip.Name)' (gesucht: '$baseName' / '$imageMatchBase') -> uebersprungen" -ForegroundColor Yellow
            continue
        }

        if (-not (Test-Path -LiteralPath $targetPath)) {
            Write-Host "  [ORDNER FEHLT] '$folderName' existiert nicht (erst Stufe 1 ausfuehren) -> uebersprungen" -ForegroundColor Yellow
            continue
        }

        $zipTarget   = Join-Path -Path $targetPath -ChildPath $zip.Name
        $imageTarget = Join-Path -Path $targetPath -ChildPath $image.Name

        if ($DryRun) {
            Write-Host "  [WUERDE VERSCHIEBEN] '$($zip.Name)' + '$($image.Name)' -> '$folderName'" -ForegroundColor Gray
        }
        else {
            Move-Item -LiteralPath $zip.FullName -Destination $zipTarget -Force
            Move-Item -LiteralPath $image.FullName -Destination $imageTarget -Force
            Write-Host "  [VERSCHOBEN] '$($zip.Name)' + '$($image.Name)' -> '$folderName'" -ForegroundColor Green
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
