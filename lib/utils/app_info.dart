// Uygulama genelinde kullanılan iletişim bilgileri.
// Derlerken verin: --dart-define=SUPPORT_EMAIL=destek@alanadiniz.com
const String kSupportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: 'destek@example.com',
);
