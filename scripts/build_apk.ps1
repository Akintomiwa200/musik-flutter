# Build a release APK for Musik and copy to releases/
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "Building Musik APK v$Version..." -ForegroundColor Green

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Src = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
$DestDir = Join-Path $Root "releases"
$Dest = Join-Path $DestDir "musik-v$Version.apk"

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

Copy-Item $Src $Dest -Force
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  $Dest"
Write-Host ""
Write-Host "Update releases/latest.json with build_number and download_url before publishing."
