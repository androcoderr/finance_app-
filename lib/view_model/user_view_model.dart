import 'package:flutter/material.dart';
import 'package:test_borsa/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bill_reminder_service.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/api_http.dart' as api_http;
import '../services/database_helper.dart';

class UserViewModel with ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  String? _authToken;
  String? _refreshToken; // Bu satırın kodunuzda olduğundan emin olun
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _currentUser?.id;
  String? get authToken => _authToken;

  UserViewModel() {
    // Oturum otomatik yenilendiğinde bellekteki token da güncellensin
    api_http.onAccessTokenRefreshed = (token) => _authToken = token;
    api_http.onRefreshTokenChanged = (token) => _refreshToken = token;
  }
  bool get isLoading => _isLoading;

  // --- Authentication Metotları (Mevcut kodunuz) ---
  // ... login, register, logout, loadUserFromStorage ...

  // 🟢 YENİ & ZORUNLU: Profil güncelleme sonrası ana kullanıcı state'ini günceller.
  // Bu metot, 'copyWith' kullanarak veri kaybını önler.
  Future<void> updateUser(User updatedUser) async {
    print('🔄 Updating user profile data...');
    print('📝 New name: ${updatedUser.name}, New email: ${updatedUser.email}');

    if (_currentUser != null) {
      // Sadece name ve email'i güncelle, diğer verileri koru
      _currentUser = _currentUser!.copyWith(
        name: updatedUser.name,
        email: updatedUser.email,
        // password ve diğer alanları KORUYORUZ
      );

      // Token'ı da kaydet
      await _saveUserToStorage(_currentUser!, _authToken);
      notifyListeners();

      print('✅ UserViewModel updated successfully');
      print('✅ Current user name: ${_currentUser!.name}');
      print('✅ Current user email: ${_currentUser!.email}');
    } else {
      print('❌ Current user is null!');
    }
  }

  // --- MEVCUT KODUNUZUN GERİ KALANI (GEREKLİ DÜZELTMELERLE) ---

  /*Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.login(email, password);

      final user = User.fromJson(result['user']);
      final accessToken = result['access_token'];
      _currentUser = user;
      _isLoggedIn = true;
      _authToken = accessToken;
      _refreshToken = result['refresh_token'];
      await _saveUserToStorage(user, accessToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }*/
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.login(email, password);
      if (!result.containsKey('access_token')) {
        throw Exception("Sunucudan beklenmedik cevap formatı.");
      }
      await _openSession(
        User.fromJson(result['user']),
        result['access_token'],
        result['refresh_token'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// E-posta doğrulandıktan sonra gelen token'larla oturumu aç
  Future<void> completeEmailVerification(Map<String, dynamic> result) async {
    await _openSession(
      User.fromJson(result['user']),
      result['access_token'],
      result['refresh_token'],
    );
  }

  Future<void> _openSession(
    User user,
    String accessToken,
    String? refreshToken,
  ) async {
    _currentUser = user;
    _isLoggedIn = true;
    _authToken = accessToken;
    _refreshToken = refreshToken;
    await _saveUserToStorage(user, accessToken);
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.register(name, email, password);
      final user = User.fromJson(result['user']);
      final accessToken = result['access_token'];
      _currentUser = user;
      _isLoggedIn = true;
      _authToken = accessToken;
      _refreshToken = result['refresh_token'];
      await _saveUserToStorage(user, accessToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    _authToken = null;
    _refreshToken = null;
    await _clearUserFromStorage();
    notifyListeners();
  }

  static const _installedKey = 'app_installed';

  Future<void> loadUserFromStorage() async {
    _isLoading = true;
    try {
      // Eski sürümün düz metin token'larını şifreli depoya taşı
      await TokenStorage.migrateFromPrefs();
      final prefs = await SharedPreferences.getInstance();
      // iOS'ta Keychain uygulama silinince temizlenmez: yeni kurulumda (cihazda
      // hiç uygulama verisi yoksa) eski oturum geri gelmesin. Güncellemede
      // user_data durduğu için mevcut kullanıcılar çıkış yapmaz.
      if (!prefs.containsKey(_installedKey) && !prefs.containsKey('user_data')) {
        await TokenStorage.clear();
      }
      await prefs.setBool(_installedKey, true);
      final userData = prefs.getString('user_data');
      final token = await TokenStorage.access();
      final refreshToken = await TokenStorage.refresh();

      if (userData != null && token != null) {
        final userJson = json.decode(userData);
        _currentUser = User.fromJson(userJson);
        _authToken = token;
        _refreshToken = refreshToken;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
    if (token != null) {
      await TokenStorage.saveAccess(token);
      print('✅ KAYDEDİLEN TOKEN: $token');
    }
    if (_refreshToken != null) {
      await TokenStorage.saveRefresh(_refreshToken!);
    }
  }

  Future<void> _clearUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await TokenStorage.clear();
    // Cihazda tutulan kullanıcıya ait veriler (sonraki kullanıcı görmesin)
    await prefs.remove('notifications');
    // Önceki kullanıcının fatura hatırlatmaları çalmasın
    await BillReminders.cancelAll();
    try {
      await DatabaseHelper.instance.deleteAll();
    } catch (_) {}
  }
}
