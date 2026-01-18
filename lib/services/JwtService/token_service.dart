import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
    }

    return token;
  }
}
