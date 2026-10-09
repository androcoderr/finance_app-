#!/usr/bin/env bash
# Play Store için release AAB derler (kod gizleme açık).
#
# Kullanım:
#   API_BASE_URL=https://api.alanadiniz.com SUPPORT_EMAIL=destek@alanadiniz.com scripts/build_release.sh
#
# Çıktı:  build/app/outputs/bundle/release/app-release.aab
# Semboller: release-symbols/<sürüm>/  → SAKLAYIN. Gizlenmiş kodun çökme kayıtlarını
#   okumak için gerekir (flutter symbolize). Git'e girmez.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${API_BASE_URL:?API_BASE_URL gerekli (ör. https://api.alanadiniz.com)}"
: "${SUPPORT_EMAIL:?SUPPORT_EMAIL gerekli}"

case "$API_BASE_URL" in
  https://*) ;;
  *) echo "HATA: API_BASE_URL https:// ile başlamalı (Android şifresiz HTTP'yi engeller)" >&2; exit 1 ;;
esac

VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
SYMBOLS="release-symbols/$VERSION"
mkdir -p "$SYMBOLS"

# Not: GEMINI_API_KEY gibi anahtarlar BURAYA EKLENMEMELİ — --dart-define değerleri
# APK'nın içine düz metin olarak gömülür ve herkes okuyabilir.
flutter build appbundle --release \
  --obfuscate --split-debug-info="$SYMBOLS" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=SUPPORT_EMAIL="$SUPPORT_EMAIL"

echo
echo "✅ AAB: build/app/outputs/bundle/release/app-release.aab"
echo "🔑 Semboller: $SYMBOLS (yedekleyin)"
