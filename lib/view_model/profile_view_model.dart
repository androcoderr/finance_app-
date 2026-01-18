import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../utils/error_handler.dart';

// Sayfanın anlık durumunu yönetmek için bir enum tanımlıyoruz.
enum ProfileState { idle, loading, success, error }

// 🟢 YAPI DEĞİŞİKLİĞİ: Sınıf artık UserViewModel'e bağımlı DEĞİL.
// Tıpkı referans verdiğiniz BillsViewModel gibi çalışacak.
class ProfileViewModel with ChangeNotifier {
  // State'leri ve hata mesajını tutacak değişkenler
  ProfileState _updateProfileState = ProfileState.idle;
  ProfileState _changePasswordState = ProfileState.idle;
  String? _errorMessage;

  // UI'ın bu değerleri okuyabilmesi için getter'lar
  ProfileState get updateProfileState => _updateProfileState;
  ProfileState get changePasswordState => _changePasswordState;
  String? get errorMessage => _errorMessage;

  // Profil bilgilerini (ad, e-posta) güncelleme fonksiyonu
  // 🟢 DÜZELTME: Metot artık token'ı bir parametre olarak alıyor.
  Future<User?> updateProfile(String token, String name, String email) async {
    _updateProfileState = ProfileState.loading;
    _errorMessage = null;
    notifyListeners(); // Arayüze "yükleniyor" durumunu bildir

    try {
      final updatedUser = await AuthService.updateUserProfile(
        token,
        name,
        email,
      );
      _updateProfileState = ProfileState.success;
      notifyListeners(); // Arayüze "başarılı" durumunu bildir
      return updatedUser; // 🟢 YENİ: Güncellenmiş kullanıcıyı döndürür
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _updateProfileState = ProfileState.error;
      notifyListeners(); // Arayüze "hata" durumunu ve mesajını bildir
      return null;
    }
  }

  // Şifre değiştirme fonksiyonu
  // 🟢 DÜZELTME: Metot artık token'ı bir parametre olarak alıyor.
  Future<bool> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    _changePasswordState = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.changePassword(token, oldPassword, newPassword);
      _changePasswordState = ProfileState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _changePasswordState = ProfileState.error;
      notifyListeners();
      return false;
    }
  }
}
