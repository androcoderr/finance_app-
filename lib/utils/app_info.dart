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
