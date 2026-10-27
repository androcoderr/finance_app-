import 'dart:io' show Platform;

// Uygulama genelinde kullanılan iletişim bilgileri.
// Derlerken verin: --dart-define=SUPPORT_EMAIL=destek@alanadiniz.com
const String kSupportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: 'destek@example.com',
);

const String kAppName = 'Finans Cepte';
const String kAppVersion = '1.0.0'; // pubspec.yaml "version" ile aynı tutulmalı
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.finanscepte.app';

// App Store bağlantısı App Store Connect'te uygulama oluşunca belli olur:
// --dart-define=APP_STORE_URL=https://apps.apple.com/tr/app/finans-cepte/id<numara>
const String kAppStoreUrl = String.fromEnvironment('APP_STORE_URL');
const String _appStoreSearchUrl =
    'itms-apps://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?media=software&term=Finans%20Cepte';

/// Sunucuya gönderilen platform adı (X-App-Platform)
String get kPlatformName => Platform.isIOS ? 'ios' : 'android';

/// Bu cihazın mağaza sayfası (değerlendir / güncelle)
String get kStoreUrl => Platform.isIOS
    ? (kAppStoreUrl.isNotEmpty ? kAppStoreUrl : _appStoreSearchUrl)
    : kPlayStoreUrl;

/// Arkadaşa önerirken paylaşılan bağlantılar
String get kShareLinks => kAppStoreUrl.isEmpty
    ? kPlayStoreUrl
    : 'Android: $kPlayStoreUrl\niPhone: $kAppStoreUrl';
