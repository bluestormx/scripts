<#
.SYNOPSIS
    Entfernt einen definierten Prefix aus allen Dateinamen im selben Ordner wie das Skript.

.DESCRIPTION
    Das Skript durchsucht den Ordner, in dem es liegt, nach Dateien, deren Name mit
    dem angegebenen Prefix beginnt, und benennt sie um (Prefix wird entfernt).
    Mit -DryRun wird nur angezeigt, was passieren würde, ohne tatsächlich etwas zu ändern.

.PARAMETER Prefix
    Der Prefix, der am Anfang der Dateinamen entfernt werden soll (z.B. "3D_").

.PARAMETER DryRun
    Wenn gesetzt, werden keine Dateien umbenannt, sondern nur die geplanten Änderungen ausgegeben.

.EXAMPLE
    .\Remove-Prefix.ps1 -Prefix "3D_" -DryRun

.EXAMPLE
    .\Remove-Prefix.ps1 -Prefix "3D_"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Prefix,

    [switch]$DryRun
)

# Ordner, in dem dieses Skript liegt
$ScriptFolder = $PSScriptRoot

if (-not $ScriptFolder) {
    Write-Error "Konnte den Skript-Ordner nicht ermitteln. Bitte das Skript als Datei ausfuehren (nicht ueber die Konsole einfuegen)."
    exit 1
}

Write-Host "Ordner: $ScriptFolder"
Write-Host "Prefix: '$Prefix'"
if ($DryRun) {
    Write-Host "Modus: DryRun (es werden KEINE Dateien geaendert)" -ForegroundColor Yellow
} else {
    Write-Host "Modus: Aktiv (Dateien werden umbenannt)" -ForegroundColor Red
}
Write-Host ""

# Alle Dateien im Ordner holen, die mit dem Prefix beginnen (Unterordner werden ignoriert)
# Das eigene Skript wird ausgeschlossen, damit es sich nicht selbst umbenennt
$files = Get-ChildItem -LiteralPath $ScriptFolder -File | Where-Object {
    $_.Name.StartsWith($Prefix) -and $_.FullName -ne $PSCommandPath
}

if ($files.Count -eq 0) {
    Write-Host "Keine Dateien mit dem Prefix '$Prefix' gefunden."
    exit 0
}

$renamedCount = 0
$skippedCount = 0

foreach ($file in $files) {
    $newName = $file.Name.Substring($Prefix.Length)

    if ([string]::IsNullOrWhiteSpace($newName)) {
        Write-Warning "Ueberspringe '$($file.Name)': neuer Name waere leer."
        $skippedCount++
        continue
    }

    $newFullPath = Join-Path -Path $ScriptFolder -ChildPath $newName

    if (Test-Path -LiteralPath $newFullPath) {
        Write-Warning "Ueberspringe '$($file.Name)': Zieldatei '$newName' existiert bereits."
        $skippedCount++
        continue
    }

    if ($DryRun) {
        Write-Host "[DryRun] '$($file.Name)' -> '$newName'"
    } else {
        Rename-Item -LiteralPath $file.FullName -NewName $newName
        Write-Host "'$($file.Name)' -> '$newName'" -ForegroundColor Green
    }

    $renamedCount++
}

Write-Host ""
if ($DryRun) {
    Write-Host "DryRun abgeschlossen: $renamedCount Datei(en) waeren umbenannt worden, $skippedCount uebersprungen."
} else {
    Write-Host "Fertig: $renamedCount Datei(en) umbenannt, $skippedCount uebersprungen."
}
