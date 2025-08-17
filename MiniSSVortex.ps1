<#
.SYNOPSIS
  Mini SS Vortex - Pro Version with ASCII Art
  Scans .jar files for suspicious strings and exports results to CSV.
#>

param (
    [string]$ScanPath = "C:\Users",
    [string[]]$SuspiciousStrings = @("mod_d.classUT", "Lcom/mojang/brigadier/"),
    [string]$OutputFile = "$PSScriptRoot\ScanResults.csv"
)

# --- Clear & Themed Header ---
Clear-Host
Write-Host "==================================================" -ForegroundColor DarkGray
Write-Host "               Mini SS VORTEX SCANNER             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor DarkGray
Write-Host " Target Path         : $ScanPath" -ForegroundColor Gray
Write-Host " Suspicious Strings  : $($SuspiciousStrings -join ', ')" -ForegroundColor Gray
Write-Host " Output File         : $OutputFile" -ForegroundColor Gray
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# --- ASCII Art with custom author ---
Write-Host "       |\/\/\/\/|" -ForegroundColor Yellow
Write-Host "       |        |"
Write-Host "       |  (o) (o)"
Write-Host "       C        _)"
Write-Host "        |  ,____|"
Write-Host "        |     /"
Write-Host "       /______\"
Write-Host "      /        \        - Made By ThereWasVelocity"
Write-Host ""

# --- Initialization ---
$ErrorActionPreference = "SilentlyContinue"
$results = @()
$jarFiles = Get-ChildItem -Path $ScanPath -Recurse -Filter *.jar -File

if (-not $jarFiles) {
    Write-Host "[ERROR] No .jar files found in path." -ForegroundColor Red
    Read-Host "`nPress ENTER to exit"
    exit
}

$total = $jarFiles.Count
$counter = 0
$startTime = Get-Date
Write-Host "[INFO] Found $total .jar files. Starting scan..." -ForegroundColor Cyan
Write-Host ""

# --- Main Scan Loop ---
foreach ($file in $jarFiles) {
    $hits = Select-String -Path $file.FullName -Pattern $SuspiciousStrings -SimpleMatch
    foreach ($hit in $hits) {
        $results += [PSCustomObject]@{
            File       = $file.FullName
            Line       = $hit.Line.Trim()
            LineNumber = $hit.LineNumber
        }
    }

    $counter++
    Write-Progress -Activity "Scanning .jar files..." -Status "$counter / $total" -PercentComplete (($counter / $total) * 100)
}

# --- Output Results ---
Write-Host ""
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputFile -NoTypeInformation -Force
    Write-Host "[DONE] Found $($results.Count) suspicious entries." -ForegroundColor Yellow
    Write-Host "[DONE] Results exported to: $OutputFile" -ForegroundColor Green
} else {
    Write-Host "[DONE] No suspicious strings were found." -ForegroundColor Green
}

$elapsed = (Get-Date) - $startTime
Write-Host "[TIME] Scan completed in $([math]::Round($elapsed.TotalSeconds, 2)) seconds." -ForegroundColor DarkGray

# --- Exit Pause ---
Write-Host ""
Read-Host "Press ENTER to close"
