# --- ASCII Art: Bart Simpson ---
Write-Host "       |\/\/\/\/|" -ForegroundColor Yellow
Write-Host "       |        |"
Write-Host "       |  (o) (o)"
Write-Host "       C        _)"
Write-Host "        |  ,____|"
Write-Host "        |     /"
Write-Host "       /______\"
Write-Host "      /        \        - Bart Simpson"

Write-Host "Made By ThereWasVelocity" -ForegroundColor Cyan
Write-Host ""

# --- Check Admin Privileges ---
$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run as admin" -ForegroundColor Red
    return
}

# --- Helper Functions ---
function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        $eventTime = $event.TimeCreated.ToString("MM/dd/yyyy hh:mm:ss tt")
        Write-Host "$message at: " -NoNewline -ForegroundColor Magenta
        Write-Host $eventTime -ForegroundColor Yellow
    } else {
        Write-Host "$message logs were not found." -ForegroundColor Magenta
    }
}

# --- System Info ---
$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$formattedBootTime = $lastBootTime.ToString("yyyy-MM-dd hh:mm tt")
Write-Host "Last PC Boot Time: " -NoNewline -ForegroundColor Cyan
Write-Host $formattedBootTime -ForegroundColor Yellow

$currentUserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$recycleBinFolderPath = "C:\`$Recycle.Bin\$currentUserSID"
if (Test-Path -Path $recycleBinFolderPath) {
    try {
        $recycleBinFolder = Get-Item -Path $recycleBinFolderPath -Force
        $lastModifiedTime = $recycleBinFolder.LastWriteTime.ToString("MM/dd/yyyy hh:mm:ss tt")
        Write-Host -ForegroundColor Cyan "Recycle Bin was modified at: " -NoNewline
        Write-Host -ForegroundColor Yellow $lastModifiedTime
    } catch {
        Write-Host "Unable to access the Recycle Bin folder for the current user." -ForegroundColor Red
    }
} else {
    Write-Host "Recycle Bin folder for the current user not found at $recycleBinFolderPath." -ForegroundColor Red
}

# --- Prefetch Check ---
$prefetchKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
$prefetchValueName = "EnablePrefetcher"
try {
    $prefetchStatus = (Get-ItemProperty -Path $prefetchKeyPath -Name $prefetchValueName -ErrorAction Stop).EnablePrefetcher
    if ($prefetchStatus -gt 0) {
        Write-Host "Prefetching is enabled." -ForegroundColor Green
    } else {
        Write-Host "Prefetching is disabled." -ForegroundColor Red
    }
} catch {
    Write-Host "Unable to retrieve Prefetching setting." -ForegroundColor Red
}
Write-Host ""

# --- Connected Drives ---
$drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Host "Connected Drives:" -ForegroundColor Yellow
    foreach ($drive in $drives) {
        Write-Host "$($drive.DeviceID): $($drive.FileSystem)" -ForegroundColor Green
    }
} else {
    Write-Host "No drives found." -ForegroundColor Red
}
Write-Host ""

# --- Services Status ---
$services = @(
    @{ServiceName = 'DPS';        DisplayName = 'DPS'},
    @{ServiceName = 'SysMain';    DisplayName = 'SysMain'},
    @{ServiceName = 'PcaSvc';     DisplayName = 'PcaSvc'},
    @{ServiceName = 'DusmSvc';    DisplayName = 'DusmSvc'},
    @{ServiceName = 'EventLog';   DisplayName = 'EventLog'},
    @{ServiceName = 'AppInfo';    DisplayName = 'AppInfo'},
    @{ServiceName = 'DcomLaunch'; DisplayName = 'DcomLaunch'}
)

Write-Host "Services Status:" -ForegroundColor Yellow
foreach ($entry in $services) {
    $serviceQuery = sc.exe query $($entry.ServiceName) | Out-String
    if ($serviceQuery -match "STATE\s+:\s+4\s+RUNNING") {
        Write-Host "$($entry.DisplayName): Running" -ForegroundColor Green
    } elseif ($serviceQuery -match "STATE\s+:\s+1\s+STOPPED") {
        Write-Host "$($entry.DisplayName): Not Running" -ForegroundColor Green
    } else {
        Write-Host "$($entry.DisplayName): Service Not Found" -ForegroundColor Green
    }
}
Write-Host ""

# --- Event Log Checks ---
Write-Host "Event Log Checks:" -ForegroundColor Yellow
Check-EventLog "Application" 3079 "USN Journal last deleted"
Check-EventLog "System" 1074 "User recent PC Shutdown"
Check-EventLog "Security" 4616 "System time changed"
Check-EventLog "System" 6005 "Event Log Service started"
Write-Host ""

# --- Scheduled Tasks ---
Write-Host "Scheduled Tasks:" -ForegroundColor Yellow
$tasks = Get-ScheduledTask | Where-Object {$_.State -eq 'Ready' -or $_.State -eq 'Running'}
foreach ($task in $tasks) {
    Write-Host "$($task.TaskName) - State: $($task.State)" -ForegroundColor Cyan
}
Write-Host ""

# --- Prefetch Files Integrity ---
Write-Host "Prefetch Files Integrity:" -ForegroundColor Yellow
$prefetchPath = "C:\Windows\Prefetch"
$hiddenFiles = Get-ChildItem -Path $prefetchPath -Force | Where-Object { $_.Attributes -match "Hidden" }
if ($hiddenFiles) {
    Write-Host "$($hiddenFiles.Count) Hidden files found in Prefetch:" -ForegroundColor Red
    foreach ($file in $hiddenFiles) { Write-Host $file.Name -ForegroundColor Red }
} else { Write-Host "No hidden files found in Prefetch." -ForegroundColor Green }

$readOnlyFiles = Get-ChildItem -Path $prefetchPath -Force | Where-Object { $_.Attributes -match "ReadOnly" }
if ($readOnlyFiles) {
    Write-Host "$($readOnlyFiles.Count) Read-only files found in Prefetch:" -ForegroundColor Red
    foreach ($file in $readOnlyFiles) { Write-Host $file.Name -ForegroundColor Red }
} else { Write-Host "No read-only files found in Prefetch." -ForegroundColor Green }
Write-Host ""

# --- .jar File Scan ---
$ScanPath = "$env:USERPROFILE\Downloads"  
$SuspiciousStrings = @("exec", "Runtime", "ProcessBuilder", "loadLibrary")  
$OutputFile = "$env:USERPROFILE\Desktop\JarScanResults.csv"

Write-Host "Scanning .jar files for suspicious strings..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
$results = @()
$jarFiles = Get-ChildItem -Path $ScanPath -Recurse -Filter *.jar -File

if (-not $jarFiles) {
    Write-Host "[INFO] No .jar files found in $ScanPath." -ForegroundColor Red
} else {
    $total = $jarFiles.Count
    $counter = 0
    $startTime = Get-Date

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
}

Write-Host ""
Read-Host "Press any key to exit..."
