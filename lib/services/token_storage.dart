import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturum token'ları Android Keystore ile şifrelenmiş depoda tutulur
/// (SharedPreferences düz metindir; rootlu cihazda okunabilir).
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<String?> access() => _storage.read(key: _accessKey);
  static Future<String?> refresh() => _storage.read(key: _refreshKey);

  static Future<void> saveAccess(String token) =>
      _storage.write(key: _accessKey, value: token);
  static Future<void> saveRefresh(String token) =>
      _storage.write(key: _refreshKey, value: token);

  static Future<void> clearAccess() => _storage.delete(key: _accessKey);

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Eski sürümlerden kalan, SharedPreferences'taki token'ları taşı ve sil.
  /// Böylece güncelleme sonrası kullanıcının oturumu düşmez.
  static Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_accessKey, _refreshKey]) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        await _storage.write(key: key, value: value);
      }
      await prefs.remove(key);
    }
    await prefs.remove('token'); // Çok eski bir anahtar
  }
}
