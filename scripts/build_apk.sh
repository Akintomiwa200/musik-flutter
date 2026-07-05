#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-1.0.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_local_property() {
  local name="$1"
  local file="$ROOT/android/local.properties"
  [[ -f "$file" ]] || return 1
  sed -n "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*//p" "$file" | head -n 1 | sed 's/\\\\/\\/g'
}

resolve_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi

  local flutter_sdk
  flutter_sdk="$(read_local_property "flutter.sdk" || true)"
  if [[ -n "$flutter_sdk" && -x "$flutter_sdk/bin/flutter" ]]; then
    printf '%s\n' "$flutter_sdk/bin/flutter"
    return 0
  fi

  echo "Flutter was not found. Add Flutter to PATH or set flutter.sdk in android/local.properties." >&2
  return 1
}

ensure_java() {
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
    return 0
  fi

  if command -v java >/dev/null 2>&1; then
    return 0
  fi

  echo "Java was not found. Install Android Studio or JDK 17+, then set JAVA_HOME." >&2
  return 1
}

FLUTTER_CMD="$(resolve_flutter)"
ensure_java

echo "Building Musik APK v${VERSION}..."
"$FLUTTER_CMD" pub get
"$FLUTTER_CMD" build apk --release

DEST_DIR="$ROOT/releases"
mkdir -p "$DEST_DIR"
cp "$ROOT/build/app/outputs/flutter-apk/app-release.apk" "$DEST_DIR/musik-v${VERSION}.apk"

echo ""
echo "APK ready: $DEST_DIR/musik-v${VERSION}.apk"
echo "Update releases/latest.json with build_number and download_url before publishing."
