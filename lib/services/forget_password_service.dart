import '../utils/error_handler.dart';
import 'dart:convert';
import 'package:test_borsa/services/api_http.dart' as http;
import 'BaseService.dart';

class PasswordResetService {
  // Android Emulator için doğru IP adresi
  static String get _baseUrl => BaseService.baseUrl;

  static Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json; charset=UTF-8'};
  }

  // Şifre sıfırlama email'i gönder
  static Future<Map<String, dynamic>> sendResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {
          'success': true,
          'message': data['message'] ?? 'Email gönderildi',
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'error': 'Çok fazla istek. Lütfen 5 dakika sonra tekrar deneyin.',
        };
      } else {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {'success': false, 'error': data['error'] ?? 'Bir hata oluştu'};
      }
    } catch (e) {
      return {'success': false, 'error': ErrorHandler.getErrorMessage(e)};
    }
  }

  // Token'ı doğrula
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    print('🔍 Token doğrulanıyor: ${token.substring(0, 20)}...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/verify-reset-token'),
        headers: _getHeaders(),
        body: jsonEncode({'token': token}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {
          'success': true,
          'valid': data['valid'],
          'email': data['email'],
        };
      } else {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {
          'success': false,
          'valid': false,
          'error': data['error'] ?? 'Token geçersiz',
        };
      }
    } catch (e) {
      return {'success': false, 'valid': false, 'error': ErrorHandler.getErrorMessage(e)};
    }
  }

  // Yeni şifre kaydet
  static Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({'token': token, 'password': newPassword}),
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {
          'success': true,
          'message': data['message'] ?? 'Şifre güncellendi',
        };
      } else {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);
        return {'success': false, 'error': data['error'] ?? 'Bir hata oluştu'};
      }
    } catch (e) {
      return {'success': false, 'error': ErrorHandler.getErrorMessage(e)};
    }
  }
}
