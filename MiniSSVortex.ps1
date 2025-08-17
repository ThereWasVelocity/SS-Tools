<#
.SYNOPSIS
  Mini SS Vortex
  Scans recursively for .jar files and detects suspicious strings.
  Exports findings to CSV.
#>

# --- Banner ---
Write-Host @"
=============================================
   This Tool Made By: ThereWasVelocity
=============================================

       |\/\/\/\/|
       |        |
       |  (o) (o)
       C        _)
        |  ,____|
        |     /
       /______\
      /        \
      
          Bart Simpson
=============================================
"@ -ForegroundColor Yellow

Write-Host -ForegroundColor Cyan " __  __  _        _        ___  ___"
Write-Host -ForegroundColor Cyan "|  \/  |(_) _ _  (_)      / __|/ __|"
Write-Host -ForegroundColor White "| |\/| || || ' \ | |      \__ \\__ \"
Write-Host -ForegroundColor White "|_|  |_||_||_||_||_|      |___/|___/"
Write-Host
Write-Host -ForegroundColor White "      Mini SS VORTEX"

# --- Settings ---
$extensions = "*.jar"
$strings    = "mod_d.classUT"
$path       = "C:\Users"

# --- Progress ---
$i = 0
$total = (Get-ChildItem -Path $path -Include $extensions -Recurse -File -ErrorAction SilentlyContinue).Count
Write-Progress -Activity "Expanding subdirectories..." -Status "Analyzing" -PercentComplete 0

$ErrorActionPreference = 'SilentlyContinue'
$results = @()

# --- Scan Files ---
Get-ChildItem -Path $path -Include $extensions -Recurse -File | ForEach-Object { 
    $file = $_
    $content = Get-Content $file.FullName -Raw
    foreach($string in $strings){
        if($content.Contains($string)){
            $results += [PSCustomObject]@{
                FileName      = $file.FullName
                StringMatched = $string
            }
        }
    }
    $i++
    Write-Progress -Activity "Searching for files" -Status "Processing" -PercentComplete (($i/$total)*100)
}

$ErrorActionPreference = 'Continue'

# --- Export Results ---
$results | Export-Csv -Path "FullScan.csv" -NoTypeInformation -Force
Write-Host "`nResults saved in current directory as FullScan.csv" -ForegroundColor Green
