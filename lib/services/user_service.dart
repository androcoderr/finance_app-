import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:test_borsa/services/api_http.dart' as http;
import '../models/user_model.dart';
import 'base_service.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => message;
}

/// Şifre doğru ama e-posta henüz doğrulanmamış (giriş 403)
class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;
  EmailNotVerifiedException(this.email, this.message);
  @override
  String toString() => message;
}

/// Kod çok sık istendi; [retryAfter] saniye sonra tekrar denenebilir (429)
class ResendCooldownException implements Exception {
  final int retryAfter;
  final String message;
  ResendCooldownException(this.retryAfter, this.message);
  @override
  String toString() => message;
}

class AuthService {
  static String get _baseUrl => BaseService.baseUrl; // Android emülatör

  // ================================================================
  // GİRİŞ - Flask-JWT Response Format
  // ================================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );


      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = json.decode(response.body);
        // Response formatı: {"access_token": "...", "refresh_token": "...", "user": {...}}
        return data;
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        if (data['requires_verification'] == true) {
          throw EmailNotVerifiedException(
            (data['email'] ?? email).toString(),
            (data['error'] ?? 'E-posta adresini doğrulaman gerekiyor').toString(),
          );
        }
        throw Exception(data['error'] ?? 'Giriş başarısız');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? errorData['error'] ?? 'Giriş başarısızzzz',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Login error: $e');
      rethrow;
    }
  }

  // ================================================================
  // KAYIT - Flask-JWT Response Format
  // ================================================================

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );


      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response formatı: {"access_token": "...", "refresh_token": "...", "user": {...}}
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? errorData['error'] ?? 'Kayıt başarısız',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Register error: $e');
      rethrow;
    }
  }

  // ================================================================
  // E-POSTA DOĞRULAMA
  // ================================================================

  /// Başarılıysa login cevabıyla aynı: {access_token, refresh_token, user}
  /// Şifre de gönderilir: doğrulanmamış adres başkası tarafından yeniden
  /// kaydedilmişse hesap yanlış şifreyle açılmasın (sunucu kontrol eder)
  static Future<Map<String, dynamic>> verifyEmail(
    String email,
    String code,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': password}),
    );
    final data = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data);
    throw Exception(data['error'] ?? 'Kod doğrulanamadı');
  }

  static Future<void> resendVerificationCode(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/resend-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) return;
    final data = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode == 429) {
      throw ResendCooldownException(
        (data['retry_after'] as num?)?.toInt() ?? 60,
        (data['error'] ?? 'Biraz bekleyip tekrar dene').toString(),
      );
    }
    throw Exception(data['error'] ?? 'Kod gönderilemedi');
  }

  // ================================================================
  // TOKEN YENİLEME
  // ================================================================

  static Future<String> refreshToken(String refreshToken) async {

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Could not refresh token');
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Refresh error: $e');
      rethrow;
    }
  }

  // ================================================================
  // 🟢 PROFİL GÜNCELLEME - Flask Format
  // ================================================================

  static Future<User> updateUserProfile(
    String token,
    String name,
    String email,
  ) async {

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email}),
      );


      // Token expired
      if (response.statusCode == 401) {
        throw TokenExpiredException('Token expired');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Flask genellikle direkt user objesi veya {"user": {...}} döner
        User updatedUser;

        if (responseData.containsKey('user')) {
          // Format: {"user": {...}}
          updatedUser = User.fromJson(responseData['user']);
        } else if (responseData.containsKey('id')) {
          // Format: {...} (direkt user objesi)
          updatedUser = User.fromJson(responseData);
        } else {
          throw Exception('Beklenmeyen API yanıt formatı');
        }


        return updatedUser;
      } else {
        String errorMessage = 'Profil güncellenemedi (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['msg'] ??
                errorData['error'] ??
                errorData['message'] ??
                errorMessage;
          }
        } catch (e) {
          debugPrint('❌ [AuthService] Error decoding response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Exception in updateUserProfile: $e');
      rethrow;
    }
  }

  // ================================================================
  // 🟢 ŞİFRE DEĞİŞTİRME
  // ================================================================

  static Future<void> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );


      if (response.statusCode == 401) {
        throw TokenExpiredException('Token expired');
      }

      if (response.statusCode == 200) {
        // Şifre değişince sunucu eski oturumları kapatır ve bu cihaza yeni token verir
        final data = jsonDecode(response.body);
        final access = data['access_token'] as String?;
        final refresh = data['refresh_token'] as String?;
        if (access != null && refresh != null) {
          await http.saveTokens(access, refresh);
        }
        return;
      } else {
        String errorMessage = 'Şifre değiştirilemedi (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['msg'] ??
                errorData['error'] ??
                errorMessage;
          }
        } catch (e) {
          debugPrint('❌ [AuthService] Error decoding response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Exception in changePassword: $e');
      rethrow;
    }
  }
}
