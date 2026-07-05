# Musik

A **Spotify-inspired** Flutter music player for Android with **USB OTG** support and **downloadable APK** updates at every release.

![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-green)

## Features

- **Spotify-style UI** — dark theme, green accents, mini player bar, now playing screen, bottom navigation
- **USB music** — browse and play audio from USB drives connected via OTG
- **Local library** — scan device Music and Download folders
- **APK updates** — check, download, and install new APK versions from a manifest URL
- **Offline playback** — no streaming account required; plays files from storage

## Screens

| Home | USB | Now Playing | Settings |
|------|-----|-------------|----------|
| Quick access, USB devices, recent tracks | Scan OTG drives, pick folders, play all | Full player with seek, shuffle, repeat | Version info, APK update checker |

## Prerequisites

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+ stable
2. Android Studio or JDK 17+ available through `JAVA_HOME`
3. Android SDK platform 36+ with Android build tools installed
4. For USB testing: Android phone with **USB OTG** adapter

## Setup

```bash
# Clone or open this folder, then:
flutter pub get
```

Update `android/local.properties` with your paths:

```properties
sdk.dir=C:\\Users\\YOUR_USER\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\path\\to\\flutter
```

## Run on device

```bash
flutter run
```

## Build APK (downloadable)

### Windows (PowerShell)

```powershell
.\scripts\build_apk.ps1
```

If PowerShell blocks local scripts on your machine, run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\build_apk.ps1
```

### Manual

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Copy to `releases/` for distribution:

```bash
cp build/app/outputs/flutter-apk/app-release.apk releases/musik-v1.0.0.apk
```

## APK update flow

1. Host `releases/latest.json` on GitHub, S3, or any HTTPS server
2. Bump `build_number` in `pubspec.yaml` and `latest.json`
3. Upload the new APK and set `download_url` in the manifest
4. In the app: **Settings → Check for updates → Download & Install**

Example manifest (`releases/latest.json`):

```json
{
  "version": "1.0.1",
  "build_number": 2,
  "download_url": "https://your-server.com/musik-v1.0.1.apk",
  "release_notes": "Bug fixes and USB scan improvements."
}
```

## USB usage

1. Connect a USB flash drive to your phone using a **USB OTG** cable/adapter
2. Open the **USB** tab in the app
3. Tap **Refresh** to scan mounted drives, or **Browse folder** to pick a directory
4. Tap any track or **Play all**

Supported formats: MP3, WAV, FLAC, M4A, AAC, OGG, WMA

## Project structure

```
lib/
  main.dart                 # App entry
  theme/app_theme.dart      # Spotify-inspired colors & theme
  models/track.dart         # Track, Playlist, USB device models
  services/
    audio_player_service.dart
    usb_music_service.dart
    apk_update_service.dart
  screens/                  # Home, Library, USB, Player, Settings
  widgets/                  # Mini player, track tiles, cards
releases/
  latest.json               # APK update manifest template
scripts/
  build_apk.ps1             # One-command release build
```

## License

MIT — use freely for personal and commercial projects.
