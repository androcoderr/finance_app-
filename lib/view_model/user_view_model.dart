import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

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
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.name;
  String? get authToken => _authToken;
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
  Future<Map<String, dynamic>> login(String email, String password) async {
    // bool yerine Map döndürsün
    _isLoading = true;
    notifyListeners();
    try {
      // 1. AuthService'ten sonucu al
      final result = await AuthService.login(email, password);

      // 2. Cevabı kontrol et: 2FA gerekli mi?
      if (result.containsKey('requires_2fa') &&
          result['requires_2fa'] == true) {
        print('🔔 2FA Gerekli! Onay sayfasına yönlendirilecek.');
        _isLoading = false;
        notifyListeners();
        // Login sayfasına 2FA'nın gerekli olduğunu ve session_token'ı geri döndür
        return {'requires_2fa': true, 'session_token': result['session_token']};
      }
      // 3. 2FA gerekli değilse, normal giriş yap ve token'ı kaydet
      else if (result.containsKey('access_token')) {
        final user = User.fromJson(result['user']);
        final accessToken = result['access_token'];
        _currentUser = user;
        _isLoggedIn = true;
        _authToken = accessToken;
        _refreshToken = result['refresh_token'];
        await _saveUserToStorage(user, accessToken); // Kaydetme işlemi
        _isLoading = false;
        notifyListeners();
        // Login sayfasına normal girişin başarılı olduğunu döndür
        return {'requires_2fa': false};
      }
      // 4. Beklenmedik bir cevap gelirse
      else {
        throw Exception("Sunucudan beklenmedik cevap formatı.");
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> complete2faLogin(
    User user,
    String accessToken,
    String? refreshToken,
  ) async {
    print(' completing 2FA login...');
    _currentUser = user;
    _isLoggedIn = true;
    _authToken = accessToken;
    _refreshToken =
        refreshToken; // Refresh token'ı da güncelleyebilirsiniz (opsiyonel)

    // En önemli adım: Yeni token'ı ve kullanıcı durumunu kaydet
    await _saveUserToStorage(user, accessToken);

    // Tüm uygulamaya "Artık giriş yapıldı!" haberini ver
    notifyListeners();
    print('✅ 2FA Login tamamlandı. isLoggedIn: $_isLoggedIn');
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

  Future<void> loadUserFromStorage() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final token = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

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

  Future<void> updateToken(String token) async {
    _authToken = token;
    if (_currentUser != null) {
      await _saveUserToStorage(_currentUser!, token);
    }
    notifyListeners();
  }

  // 🟢 DÜZELTME: Bu metotlar artık doğrudan 'copyWith' kullanarak daha verimli çalışıyor.
  void updateUserTransactions(List<TransactionModel> transactions) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(transactions: transactions);
      _saveUserToStorage(_currentUser!, _authToken);
      notifyListeners();
    }
  }

  void updateUserGoals(List<Goal> goals) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(goals: goals);
      _saveUserToStorage(_currentUser!, _authToken);
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
    if (token != null) {
      await prefs.setString('access_token', token);
      print('✅ KAYDEDİLEN TOKEN: $token');
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  Future<void> _clearUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
