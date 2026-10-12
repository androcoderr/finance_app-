import 'dart:io' show Platform;

class BaseService {
  static const _fromBuild = String.fromEnvironment('API_BASE_URL');

  // Derlerken verin: flutter build ... --dart-define=API_BASE_URL=https://api.ornek.com
  // Verilmezse geliştirme sunucusu: Android emülatöründe 10.0.2.2, iOS simülatöründe localhost
  static String baseUrl = _fromBuild.isNotEmpty
      ? _fromBuild
      : (Platform.isIOS ? 'http://localhost:8000' : 'http://10.0.2.2:8000');
}
