#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-1.0.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building Musik APK v${VERSION}..."
flutter pub get
flutter build apk --release

DEST_DIR="$ROOT/releases"
mkdir -p "$DEST_DIR"
cp "$ROOT/build/app/outputs/flutter-apk/app-release.apk" "$DEST_DIR/musik-v${VERSION}.apk"

echo ""
echo "APK ready: $DEST_DIR/musik-v${VERSION}.apk"
echo "Update releases/latest.json with build_number and download_url before publishing."
