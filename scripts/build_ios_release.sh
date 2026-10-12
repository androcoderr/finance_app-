#!/usr/bin/env bash
# App Store için iOS release derler (kod gizleme açık).
#
# Kullanım:
#   API_BASE_URL=https://api.alanadiniz.com SUPPORT_EMAIL=destek@alanadiniz.com \
#   APP_STORE_URL=https://apps.apple.com/app/id<numara> scripts/build_ios_release.sh
#
# Çıktı: build/ios/ipa/*.ipa  → Transporter uygulamasıyla ya da Xcode → Window → Organizer
#        (build/ios/archive/Runner.xcarchive) → Distribute App ile App Store Connect'e yükleyin.
# Semboller: release-symbols/ios-<sürüm>/ → SAKLAYIN (gizlenmiş Dart çökme kayıtları için).
#
# Apple hesabı/imza olmadan yalnızca derlenebiliyor mu diye bakmak için: NO_CODESIGN=1
set -euo pipefail
cd "$(dirname "$0")/.."

: "${API_BASE_URL:?API_BASE_URL gerekli (ör. https://api.alanadiniz.com)}"
: "${SUPPORT_EMAIL:?SUPPORT_EMAIL gerekli}"

case "$API_BASE_URL" in
  https://*) ;;
  *) echo "HATA: API_BASE_URL https:// ile başlamalı (iOS ATS şifresiz HTTP'yi engeller)" >&2; exit 1 ;;
esac

VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')   # ör. 1.0.0+1 → iOS: sürüm 1.0.0, build 1
VERSION_NAME=${VERSION%%+*}
BUILD_NUMBER=${VERSION##*+}

APP_VERSION=$(grep -oE "kAppVersion = '[^']+'" lib/utils/app_info.dart | cut -d"'" -f2)
if [ "$APP_VERSION" != "$VERSION_NAME" ]; then
  echo "HATA: lib/utils/app_info.dart kAppVersion ($APP_VERSION) ≠ pubspec sürümü ($VERSION_NAME)" >&2
  exit 1
fi

if [ -z "${APP_STORE_URL:-}" ] && [ "${NO_CODESIGN:-0}" != "1" ]; then
  echo "⚠️  APP_STORE_URL verilmedi: uygulamadaki paylaş/değerlendir bağlantıları App Store aramasına düşer."
fi

echo "Uygulama testleri çalışıyor (flutter test)…"
if ! flutter test >/tmp/finanscepte_flutter_test.log 2>&1; then
  tail -30 /tmp/finanscepte_flutter_test.log >&2
  echo "HATA: flutter test başarısız — derleme durduruldu" >&2
  exit 1
fi

echo "iOS sürüm $VERSION_NAME (build $BUILD_NUMBER)."
echo "  Not: App Store Connect'e her yüklemede build numarası bir öncekinden BÜYÜK olmalı (pubspec: version: x.y.z+BUILD)."
SYMBOLS="release-symbols/ios-$VERSION"
mkdir -p "$SYMBOLS"

DEFINES=(--dart-define=API_BASE_URL="$API_BASE_URL"
         --dart-define=SUPPORT_EMAIL="$SUPPORT_EMAIL"
         --dart-define=APP_STORE_URL="${APP_STORE_URL:-}")

if [ "${NO_CODESIGN:-0}" = "1" ]; then
  flutter build ios --release --no-codesign --obfuscate --split-debug-info="$SYMBOLS" "${DEFINES[@]}"
  echo "✅ İmzasız derleme başarılı (yüklenemez; yalnızca derleme kontrolü)."
  exit 0
fi

flutter build ipa --release --obfuscate --split-debug-info="$SYMBOLS" "${DEFINES[@]}"

# Crashlytics: Dart sembolleri (dSYM'ler Xcode derleme adımında ayrıca yüklenir).
# Firebase Console → com.finanscepte.app (iOS) "Uygulama kimliği" — gizli değildir. SKIP_SYMBOL_UPLOAD=1 ile atlanır.
FIREBASE_IOS_APP_ID=${FIREBASE_IOS_APP_ID:-1:800544380029:ios:187d8944b919ed29964d14}
if [ "${SKIP_SYMBOL_UPLOAD:-0}" != "1" ]; then
  if ! command -v firebase >/dev/null; then
    echo "HATA: firebase CLI yok (npm install -g firebase-tools && firebase login). Semboller yüklenmedi." >&2
    exit 1
  fi
  firebase crashlytics:symbols:upload --app="$FIREBASE_IOS_APP_ID" "$SYMBOLS"
  echo "✅ Crashlytics sembolleri yüklendi"
else
  echo "⚠️  SKIP_SYMBOL_UPLOAD=1: Dart sembolleri yüklenmedi. Sonradan:"
  echo "    firebase crashlytics:symbols:upload --app=$FIREBASE_IOS_APP_ID $SYMBOLS"
fi

echo
echo "✅ IPA: $(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)"
echo "🔑 Semboller: $SYMBOLS (yedekleyin)"
