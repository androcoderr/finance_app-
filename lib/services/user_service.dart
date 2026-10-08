import 'dart:convert';
import 'package:test_borsa/services/api_http.dart' as http;
import '../models/user_model.dart';
import 'BaseService.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
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
    print('🌐 [AuthService] Login request: $email');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('📡 [AuthService] Login status: ${response.statusCode}');
      print('📡 [AuthService] Login response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = json.decode(response.body);
        // Response formatı: {"access_token": "...", "refresh_token": "...", "user": {...}}
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? errorData['error'] ?? 'Giriş başarısızzzz',
        );
      }
    } catch (e) {
      print('❌ [AuthService] Login error: $e');
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
    print('🌐 [AuthService] Register request: $email');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      print('📡 [AuthService] Register status: ${response.statusCode}');

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
      print('❌ [AuthService] Register error: $e');
      rethrow;
    }
  }

  // ================================================================
  // TOKEN YENİLEME
  // ================================================================

  static Future<String> refreshToken(String refreshToken) async {
    print('🔄 [AuthService] Refreshing token...');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      print('📡 [AuthService] Refresh status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [AuthService] Token refreshed');
        return data['access_token'];
      } else {
        print('❌ [AuthService] Refresh failed');
        throw Exception('Could not refresh token');
      }
    } catch (e) {
      print('❌ [AuthService] Refresh error: $e');
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
    print('🌐 [AuthService] Updating profile...');
    print('📝 [AuthService] Name: $name');
    print('📧 [AuthService] Email: $email');

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email}),
      );

      print('📡 [AuthService] Profile update status: ${response.statusCode}');
      print('📡 [AuthService] Profile update response: ${response.body}');

      // Token expired
      if (response.statusCode == 401) {
        print('❌ [AuthService] Token expired (401)');
        throw TokenExpiredException('Token expired');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Flask genellikle direkt user objesi veya {"user": {...}} döner
        User updatedUser;

        if (responseData.containsKey('user')) {
          // Format: {"user": {...}}
          print('🔍 [AuthService] Format: Nested user object');
          updatedUser = User.fromJson(responseData['user']);
        } else if (responseData.containsKey('id')) {
          // Format: {...} (direkt user objesi)
          print('🔍 [AuthService] Format: Direct user object');
          updatedUser = User.fromJson(responseData);
        } else {
          print('❌ [AuthService] Unknown format. Keys: ${responseData.keys}');
          throw Exception('Beklenmeyen API yanıt formatı');
        }

        print('✅ [AuthService] User updated successfully');
        print(
          '✅ [AuthService] Name: ${updatedUser.name}, Email: ${updatedUser.email}',
        );

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
          print('❌ [AuthService] Error decoding response: $e');
        }
        print('❌ [AuthService] Update failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [AuthService] Exception in updateUserProfile: $e');
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
    print('🌐 [AuthService] Changing password...');

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

      print('📡 [AuthService] Change password status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('❌ [AuthService] Token expired');
        throw TokenExpiredException('Token expired');
      }

      if (response.statusCode == 200) {
        print('✅ [AuthService] Password changed successfully');
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
          print('❌ [AuthService] Error decoding response: $e');
        }
        print('❌ [AuthService] Change password failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [AuthService] Exception in changePassword: $e');
      rethrow;
    }
  }
}
