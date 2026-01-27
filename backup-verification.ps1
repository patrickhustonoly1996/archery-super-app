# Backup Verification Script for Windows
# Run this in PowerShell on your Windows machine before laptop handoff

$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BACKUP VERIFICATION SCRIPT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Find Dropbox folder
$dropboxInfoPath = "$env:LOCALAPPDATA\Dropbox\info.json"
$dropboxPath = $null

if (Test-Path $dropboxInfoPath) {
    $dropboxInfo = Get-Content $dropboxInfoPath | ConvertFrom-Json
    $dropboxPath = $dropboxInfo.personal.path
    if (-not $dropboxPath) {
        $dropboxPath = $dropboxInfo.business.path
    }
}

if (-not $dropboxPath) {
    # Try common locations
    $commonPaths = @(
        "$env:USERPROFILE\Dropbox",
        "$env:USERPROFILE\Dropbox (Personal)",
        "C:\Dropbox",
        "D:\Dropbox"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $dropboxPath = $path
            break
        }
    }
}

if ($dropboxPath) {
    Write-Host "[OK] Dropbox found at: $dropboxPath" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Dropbox folder not found!" -ForegroundColor Red
    $dropboxPath = "NOT_FOUND"
}

$userFolder = $env:USERPROFILE
Write-Host "[OK] User folder: $userFolder`n" -ForegroundColor Green

# Function to check if path is inside Dropbox
function Test-InDropbox {
    param($path)
    if ($dropboxPath -eq "NOT_FOUND") { return $false }
    $resolvedPath = (Resolve-Path $path -ErrorAction SilentlyContinue).Path
    if ($resolvedPath) {
        return $resolvedPath.StartsWith($dropboxPath, [System.StringComparison]::OrdinalIgnoreCase)
    }
    return $false
}

# Function to get folder size
function Get-FolderSize {
    param($path)
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return $size
    }
    return 0
}

function Format-Size {
    param($bytes)
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes bytes" }
}

$notBackedUp = @()
$totalUnbackedSize = 0

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  1. KEY USER FOLDERS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

$keyFolders = @(
    @{Name="Documents"; Path="$userFolder\Documents"},
    @{Name="Desktop"; Path="$userFolder\Desktop"},
    @{Name="Downloads"; Path="$userFolder\Downloads"},
    @{Name="Pictures"; Path="$userFolder\Pictures"},
    @{Name="Videos"; Path="$userFolder\Videos"},
    @{Name="Music"; Path="$userFolder\Music"}
)

foreach ($folder in $keyFolders) {
    if (Test-Path $folder.Path) {
        $size = Get-FolderSize $folder.Path
        $sizeStr = Format-Size $size
        $inDropbox = Test-InDropbox $folder.Path

        # Check if it's a symlink to Dropbox
        $item = Get-Item $folder.Path -Force
        $isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

        if ($inDropbox -or $isSymlink) {
            Write-Host "[BACKED UP] $($folder.Name): $sizeStr" -ForegroundColor Green
        } else {
            Write-Host "[NOT BACKED UP] $($folder.Name): $sizeStr" -ForegroundColor Red
            $notBackedUp += @{Name=$folder.Name; Path=$folder.Path; Size=$size}
            $totalUnbackedSize += $size
        }
    } else {
        Write-Host "[EMPTY/MISSING] $($folder.Name)" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "  2. DEV/PROJECT FOLDERS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

$devFolders = @(
    "$userFolder\Projects",
    "$userFolder\Dev",
    "$userFolder\Development",
    "$userFolder\Code",
    "$userFolder\Source",
    "$userFolder\Repos",
    "$userFolder\GitHub",
    "$userFolder\workspace",
    "C:\Projects",
    "C:\Dev",
    "D:\Projects",
    "D:\Dev"
)

foreach ($path in $devFolders) {
    if (Test-Path $path) {
        $size = Get-FolderSize $path
        $sizeStr = Format-Size $size
        $inDropbox = Test-InDropbox $path

        if ($inDropbox) {
            Write-Host "[BACKED UP] $path : $sizeStr" -ForegroundColor Green
        } else {
            Write-Host "[NOT BACKED UP] $path : $sizeStr" -ForegroundColor Red
            $notBackedUp += @{Name=$path; Path=$path; Size=$size}
            $totalUnbackedSize += $size
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "  3. COMMONLY FORGOTTEN FILES" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# SSH Keys
$sshPath = "$userFolder\.ssh"
if (Test-Path $sshPath) {
    $sshFiles = Get-ChildItem $sshPath -Force
    $hasKeys = $sshFiles | Where-Object { $_.Name -match "id_|known_hosts|config" }
    if ($hasKeys) {
        Write-Host "[CRITICAL] SSH keys found in $sshPath :" -ForegroundColor Red
        foreach ($file in $hasKeys) {
            Write-Host "           - $($file.Name)" -ForegroundColor Red
        }
        $notBackedUp += @{Name="SSH Keys"; Path=$sshPath; Size=0}
    }
} else {
    Write-Host "[OK] No SSH keys found" -ForegroundColor Gray
}

# Git Config
$gitConfig = "$userFolder\.gitconfig"
if (Test-Path $gitConfig) {
    if (-not (Test-InDropbox $gitConfig)) {
        Write-Host "[NOT BACKED UP] Git config: $gitConfig" -ForegroundColor Red
        $notBackedUp += @{Name="Git Config"; Path=$gitConfig; Size=0}
    } else {
        Write-Host "[BACKED UP] Git config" -ForegroundColor Green
    }
}

# VSCode Settings
$vscodePath = "$userFolder\AppData\Roaming\Code\User"
if (Test-Path $vscodePath) {
    Write-Host "[NOT BACKED UP] VSCode settings at $vscodePath" -ForegroundColor Red
    Write-Host "                Consider: Settings Sync or export settings.json" -ForegroundColor Yellow
    $notBackedUp += @{Name="VSCode Settings"; Path=$vscodePath; Size=0}
}

# Browser Bookmarks
$chromeBookmarks = "$userFolder\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
$edgeBookmarks = "$userFolder\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$firefoxProfiles = "$userFolder\AppData\Roaming\Mozilla\Firefox\Profiles"

if (Test-Path $chromeBookmarks) {
    Write-Host "[CHECK] Chrome bookmarks - verify Chrome sync is enabled" -ForegroundColor Yellow
}
if (Test-Path $edgeBookmarks) {
    Write-Host "[CHECK] Edge bookmarks - verify Edge sync is enabled" -ForegroundColor Yellow
}
if (Test-Path $firefoxProfiles) {
    Write-Host "[CHECK] Firefox profile - verify Firefox sync is enabled" -ForegroundColor Yellow
}

# .env files
Write-Host "`nSearching for .env files (API keys, secrets)..." -ForegroundColor Cyan
$envFiles = Get-ChildItem -Path $userFolder -Recurse -Force -Filter "*.env*" -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer } |
            Select-Object -First 50

if ($envFiles) {
    Write-Host "[CRITICAL] Found .env files:" -ForegroundColor Red
    foreach ($file in $envFiles) {
        $inDropbox = Test-InDropbox $file.FullName
        $status = if ($inDropbox) { "[in Dropbox]" } else { "[NOT BACKED UP]" }
        $color = if ($inDropbox) { "Green" } else { "Red" }
        Write-Host "           $status $($file.FullName)" -ForegroundColor $color
    }
}

# API Keys in common locations
$apiKeyFiles = @(
    "$userFolder\.aws\credentials",
    "$userFolder\.aws\config",
    "$userFolder\.npmrc",
    "$userFolder\.pypirc",
    "$userFolder\.netrc",
    "$userFolder\.docker\config.json"
)

foreach ($file in $apiKeyFiles) {
    if (Test-Path $file) {
        Write-Host "[CRITICAL] API/credentials file: $file" -ForegroundColor Red
        $notBackedUp += @{Name="Credentials: $(Split-Path $file -Leaf)"; Path=$file; Size=0}
    }
}

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "  4. LARGE FILES (>100MB)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "Scanning for large files (this may take a few minutes)..." -ForegroundColor Cyan

$largeFiles = Get-ChildItem -Path $userFolder -Recurse -Force -ErrorAction SilentlyContinue |
              Where-Object { -not $_.PSIsContainer -and $_.Length -gt 100MB } |
              Sort-Object Length -Descending |
              Select-Object -First 30

if ($largeFiles) {
    foreach ($file in $largeFiles) {
        $inDropbox = Test-InDropbox $file.FullName
        $sizeStr = Format-Size $file.Length

        if ($inDropbox) {
            Write-Host "[BACKED UP] $sizeStr - $($file.FullName)" -ForegroundColor Green
        } else {
            Write-Host "[NOT BACKED UP] $sizeStr - $($file.FullName)" -ForegroundColor Red
            $totalUnbackedSize += $file.Length
        }
    }
} else {
    Write-Host "No files larger than 100MB found outside system folders" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Dropbox Location: $dropboxPath" -ForegroundColor White

if ($dropboxPath -ne "NOT_FOUND") {
    $dropboxSize = Get-FolderSize $dropboxPath
    Write-Host "Dropbox Size: $(Format-Size $dropboxSize)" -ForegroundColor Green
}

Write-Host "`nItems NOT backed up:" -ForegroundColor Red
if ($notBackedUp.Count -eq 0) {
    Write-Host "  Everything appears to be backed up!" -ForegroundColor Green
} else {
    foreach ($item in $notBackedUp) {
        Write-Host "  - $($item.Name)" -ForegroundColor Red
    }
}

Write-Host "`nTotal unbacked data size: $(Format-Size $totalUnbackedSize)" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  RECOMMENDED ACTIONS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. Copy SSH keys to secure backup (USB or password manager)" -ForegroundColor White
Write-Host "2. Export browser bookmarks if not using sync" -ForegroundColor White
Write-Host "3. Back up any .env files with API keys to password manager" -ForegroundColor White
Write-Host "4. Export VSCode extensions: code --list-extensions > extensions.txt" -ForegroundColor White
Write-Host "5. Move/copy unbacked folders to Dropbox" -ForegroundColor White

Write-Host "`nScript complete! Review the items above before handing off the laptop.`n" -ForegroundColor Green

# Export results to file
$reportPath = "$userFolder\Desktop\backup-verification-report.txt"
$report = @"
BACKUP VERIFICATION REPORT
Generated: $(Get-Date)
Dropbox: $dropboxPath
User Folder: $userFolder

ITEMS NOT BACKED UP:
$($notBackedUp | ForEach-Object { "- $($_.Name): $($_.Path)" } | Out-String)

TOTAL UNBACKED SIZE: $(Format-Size $totalUnbackedSize)
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
