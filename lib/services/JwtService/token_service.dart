import 'package:test_borsa/services/token_storage.dart';

class TokenService {
  static Future<String> getToken() async {

    final token = await TokenStorage.access() ?? '';

    if (token.isEmpty) {
      throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
    }

    return token;
  }
}
