# Backup with Deduplication Script
# Finds duplicates and only backs up unique files

$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BACKUP WITH DEDUPLICATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Find Dropbox
$dropboxInfoPath = "$env:LOCALAPPDATA\Dropbox\info.json"
$dropboxPath = $null

if (Test-Path $dropboxInfoPath) {
    $dropboxInfo = Get-Content $dropboxInfoPath | ConvertFrom-Json
    $dropboxPath = $dropboxInfo.personal.path
    if (-not $dropboxPath) { $dropboxPath = $dropboxInfo.business.path }
}

if (-not $dropboxPath) {
    @("$env:USERPROFILE\Dropbox", "$env:USERPROFILE\Dropbox (Personal)", "C:\Dropbox", "D:\Dropbox") | ForEach-Object {
        if ((Test-Path $_) -and -not $dropboxPath) { $dropboxPath = $_ }
    }
}

if (-not $dropboxPath) {
    Write-Host "[ERROR] Dropbox not found!" -ForegroundColor Red
    exit
}

Write-Host "[OK] Dropbox: $dropboxPath" -ForegroundColor Green
$userFolder = $env:USERPROFILE
$backupDest = "$dropboxPath\laptop-handoff-backup"

function Format-Size {
    param($bytes)
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes bytes" }
}

# Build hash index of all Dropbox files
Write-Host "`n[1/4] Building Dropbox file index (this takes a few minutes)..." -ForegroundColor Yellow

$dropboxIndex = @{}
$dropboxFiles = Get-ChildItem -Path $dropboxPath -Recurse -File -Force -ErrorAction SilentlyContinue

$total = $dropboxFiles.Count
$i = 0

foreach ($file in $dropboxFiles) {
    $i++
    if ($i % 500 -eq 0) {
        Write-Progress -Activity "Indexing Dropbox" -Status "$i of $total files" -PercentComplete (($i / $total) * 100)
    }

    # Use name+size as quick key (faster than hashing everything)
    $key = "$($file.Name)|$($file.Length)"
    if (-not $dropboxIndex.ContainsKey($key)) {
        $dropboxIndex[$key] = @()
    }
    $dropboxIndex[$key] += $file.FullName
}
Write-Progress -Activity "Indexing Dropbox" -Completed

Write-Host "   Indexed $($dropboxFiles.Count) files in Dropbox" -ForegroundColor Green

# Scan folders to back up
Write-Host "`n[2/4] Scanning folders for duplicates..." -ForegroundColor Yellow

$foldersToBackup = @(
    @{Name="Documents"; Path="$userFolder\Documents"},
    @{Name="Desktop"; Path="$userFolder\Desktop"},
    @{Name="Downloads"; Path="$userFolder\Downloads"},
    @{Name="Pictures"; Path="$userFolder\Pictures"},
    @{Name="Videos"; Path="$userFolder\Videos"},
    @{Name="Music"; Path="$userFolder\Music"}
)

$duplicates = @()
$uniqueFiles = @()
$totalDupSize = 0
$totalUniqueSize = 0

foreach ($folder in $foldersToBackup) {
    if (-not (Test-Path $folder.Path)) { continue }

    Write-Host "`n   Scanning $($folder.Name)..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $folder.Path -Recurse -File -Force -ErrorAction SilentlyContinue
    $folderDups = 0
    $folderUnique = 0
    $folderDupSize = 0
    $folderUniqueSize = 0

    foreach ($file in $files) {
        $key = "$($file.Name)|$($file.Length)"

        if ($dropboxIndex.ContainsKey($key)) {
            # Potential duplicate - verify with hash for files > 1MB
            $isDup = $true

            if ($file.Length -gt 1MB) {
                $sourceHash = (Get-FileHash $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                $targetPath = $dropboxIndex[$key][0]
                $targetHash = (Get-FileHash $targetPath -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                $isDup = ($sourceHash -eq $targetHash)
            }

            if ($isDup) {
                $duplicates += @{
                    Source = $file.FullName
                    ExistsIn = $dropboxIndex[$key][0]
                    Size = $file.Length
                    Folder = $folder.Name
                }
                $folderDups++
                $folderDupSize += $file.Length
                $totalDupSize += $file.Length
            } else {
                $uniqueFiles += @{Path = $file.FullName; Size = $file.Length; Folder = $folder.Name}
                $folderUnique++
                $folderUniqueSize += $file.Length
                $totalUniqueSize += $file.Length
            }
        } else {
            $uniqueFiles += @{Path = $file.FullName; Size = $file.Length; Folder = $folder.Name}
            $folderUnique++
            $folderUniqueSize += $file.Length
            $totalUniqueSize += $file.Length
        }
    }

    Write-Host "      Duplicates: $folderDups files ($(Format-Size $folderDupSize))" -ForegroundColor Gray
    Write-Host "      Unique: $folderUnique files ($(Format-Size $folderUniqueSize))" -ForegroundColor White
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DUPLICATE ANALYSIS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "DUPLICATES (already in Dropbox): $($duplicates.Count) files = $(Format-Size $totalDupSize)" -ForegroundColor Yellow
Write-Host "UNIQUE (need backup): $($uniqueFiles.Count) files = $(Format-Size $totalUniqueSize)" -ForegroundColor Green
Write-Host "SPACE SAVED by skipping duplicates: $(Format-Size $totalDupSize)" -ForegroundColor Cyan

# Show sample duplicates
if ($duplicates.Count -gt 0) {
    Write-Host "`nSample duplicates (showing first 15):" -ForegroundColor Yellow
    $duplicates | Select-Object -First 15 | ForEach-Object {
        Write-Host "  [DUP] $(Format-Size $_.Size) - $($_.Source)" -ForegroundColor Gray
        Write-Host "        Already in: $($_.ExistsIn)" -ForegroundColor DarkGray
    }
}

# Confirm backup
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  READY TO BACKUP" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Will copy $($uniqueFiles.Count) unique files ($(Format-Size $totalUniqueSize)) to:" -ForegroundColor White
Write-Host "$backupDest" -ForegroundColor Cyan
Write-Host "`nSkipping $($duplicates.Count) duplicates ($(Format-Size $totalDupSize))" -ForegroundColor Yellow

$confirm = Read-Host "`nProceed with backup? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Red

    # Still save the report
    $reportPath = "$userFolder\Desktop\dedup-report.txt"
    @"
DEDUPLICATION REPORT - $(Get-Date)

DUPLICATES (safe to skip): $($duplicates.Count) files = $(Format-Size $totalDupSize)
UNIQUE (need backup): $($uniqueFiles.Count) files = $(Format-Size $totalUniqueSize)

=== DUPLICATE FILES ===
$($duplicates | ForEach-Object { "$($_.Source) => $($_.ExistsIn)" } | Out-String)

=== UNIQUE FILES ===
$($uniqueFiles | ForEach-Object { $_.Path } | Out-String)
"@ | Out-File $reportPath -Encoding UTF8

    Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
    exit
}

# Perform backup
Write-Host "`n[3/4] Backing up unique files..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path $backupDest -Force | Out-Null

$copied = 0
$failed = 0

foreach ($file in $uniqueFiles) {
    $relativePath = $file.Path.Replace($userFolder, "").TrimStart("\")
    $destPath = Join-Path $backupDest $relativePath
    $destDir = Split-Path $destPath -Parent

    try {
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $file.Path -Destination $destPath -Force
        $copied++

        if ($copied % 100 -eq 0) {
            Write-Progress -Activity "Copying files" -Status "$copied of $($uniqueFiles.Count)" -PercentComplete (($copied / $uniqueFiles.Count) * 100)
        }
    } catch {
        $failed++
        Write-Host "  [FAILED] $($file.Path): $_" -ForegroundColor Red
    }
}
Write-Progress -Activity "Copying files" -Completed

# Option to delete duplicates from source
Write-Host "`n[4/4] Cleanup duplicates?" -ForegroundColor Yellow
Write-Host "`nYou have $($duplicates.Count) duplicate files ($(Format-Size $totalDupSize)) that exist in Dropbox." -ForegroundColor White
Write-Host "These can be safely deleted from their original locations." -ForegroundColor White

$deleteConfirm = Read-Host "`nDelete duplicate files from source locations? (Y/N)"

$deleted = 0
if ($deleteConfirm -eq "Y" -or $deleteConfirm -eq "y") {
    foreach ($dup in $duplicates) {
        try {
            Remove-Item -Path $dup.Source -Force
            $deleted++
        } catch {
            Write-Host "  [FAILED TO DELETE] $($dup.Source)" -ForegroundColor Red
        }
    }
    Write-Host "Deleted $deleted duplicate files, freed $(Format-Size $totalDupSize)" -ForegroundColor Green
}

# Final summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  COMPLETE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Backed up: $copied files ($(Format-Size $totalUniqueSize))" -ForegroundColor Green
Write-Host "Skipped duplicates: $($duplicates.Count) files ($(Format-Size $totalDupSize))" -ForegroundColor Yellow
if ($deleted -gt 0) {
    Write-Host "Deleted duplicates: $deleted files" -ForegroundColor Cyan
}
if ($failed -gt 0) {
    Write-Host "Failed: $failed files" -ForegroundColor Red
}

Write-Host "`nBackup location: $backupDest" -ForegroundColor Cyan

# Save final report
$reportPath = "$userFolder\Desktop\backup-complete-report.txt"
@"
BACKUP COMPLETE - $(Get-Date)

BACKED UP: $copied files ($(Format-Size $totalUniqueSize))
SKIPPED DUPLICATES: $($duplicates.Count) files ($(Format-Size $totalDupSize))
DELETED DUPLICATES: $deleted files
FAILED: $failed files

BACKUP LOCATION: $backupDest

=== UNIQUE FILES BACKED UP ===
$($uniqueFiles | ForEach-Object { $_.Path } | Out-String)

=== DUPLICATES SKIPPED ===
$($duplicates | ForEach-Object { "$($_.Source) => already in $($_.ExistsIn)" } | Out-String)
"@ | Out-File $reportPath -Encoding UTF8

Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
