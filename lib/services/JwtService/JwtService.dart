class JwtService {
  static Future<Map<String, String>> getHeaders(String token) async {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }
}
