# deploy.ps1 - Build and deploy with auto-version increment
# Usage: .\deploy.ps1

$ErrorActionPreference = "Stop"

# Read current version
$versionFile = "web\version.json"
$version = Get-Content $versionFile | ConvertFrom-Json

# Increment build number
$version.build = $version.build + 1

# Generate new version string with timestamp
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$version.timestamp = $timestamp
$version.version = "1.0.$($version.build)"

# Write updated version
$version | ConvertTo-Json | Set-Content $versionFile
Write-Host "Version updated to: $($version.version) (build $($version.build))" -ForegroundColor Green

# Also update the version in home_screen.dart
$homeScreen = Get-Content "lib\screens\home_screen.dart" -Raw
$homeScreen = $homeScreen -replace "'v\d+\.\d+\.\d+'", "'v$($version.version)'"
Set-Content "lib\screens\home_screen.dart" $homeScreen
Write-Host "Updated version in home_screen.dart" -ForegroundColor Green

# Build Flutter web
Write-Host "Building Flutter web..." -ForegroundColor Cyan
flutter build web --release

# Copy version.json to build directory (it's in web/ but needs to be in build/web/)
Copy-Item $versionFile "build\web\version.json"
Write-Host "Copied version.json to build" -ForegroundColor Green

# Deploy to Firebase
Write-Host "Deploying to Firebase..." -ForegroundColor Cyan
firebase deploy --only hosting

Write-Host ""
Write-Host "Deploy complete! Version $($version.version)" -ForegroundColor Green
Write-Host "Users will auto-update on next app launch." -ForegroundColor Yellow
