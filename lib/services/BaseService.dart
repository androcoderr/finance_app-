class BaseService {
  // Derlerken verin: flutter build apk --dart-define=API_BASE_URL=https://api.ornek.com
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
