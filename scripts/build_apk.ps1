# Build a release APK for Musik and copy to releases/
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Read-LocalProperty {
    param([string]$Name)

    $LocalProperties = Join-Path $Root "android\local.properties"
    if (-not (Test-Path $LocalProperties)) {
        return $null
    }

    $Line = Get-Content $LocalProperties |
        Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } |
        Select-Object -First 1

    if (-not $Line) {
        return $null
    }

    return ($Line -replace "^\s*$([regex]::Escape($Name))\s*=\s*", "") -replace "\\\\", "\"
}

function Resolve-FlutterCommand {
    $Flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($Flutter) {
        return $Flutter.Source
    }

    $FlutterSdk = Read-LocalProperty "flutter.sdk"
    if ($FlutterSdk) {
        $FlutterBat = Join-Path $FlutterSdk "bin\flutter.bat"
        if (Test-Path $FlutterBat) {
            return $FlutterBat
        }
    }

    throw "Flutter was not found. Add Flutter to PATH or set flutter.sdk in android\local.properties."
}

function Ensure-JavaHome {
    if ($env:JAVA_HOME) {
        $JavaFromHome = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path $JavaFromHome) {
            return
        }
    }

    $JavaOnPath = Get-Command java -ErrorAction SilentlyContinue
    if ($JavaOnPath) {
        return
    }

    $AndroidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"
    $AndroidStudioJava = Join-Path $AndroidStudioJbr "bin\java.exe"
    if (Test-Path $AndroidStudioJava) {
        $env:JAVA_HOME = $AndroidStudioJbr
        $env:PATH = "$AndroidStudioJbr\bin;$env:PATH"
        return
    }

    throw "Java was not found. Install Android Studio or JDK 17+, then set JAVA_HOME."
}

$FlutterCmd = Resolve-FlutterCommand
Ensure-JavaHome

Write-Host "Building Musik APK v$Version..." -ForegroundColor Green

& $FlutterCmd pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FlutterCmd build apk --release
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
