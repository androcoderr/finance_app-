import 'package:flutter/material.dart';

import '../models/user_settings_model.dart';
import '../services/settings_service.dart';
// Artık UserViewModel'e doğrudan bir bağımlılık yok.

enum SettingsState { idle, loading, error }

class SettingsViewModel with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  SettingsViewModel() {
    // ViewModel oluşturulduğunda ayarları cihazdan yükle
    loadSettings();
  }

  UserSettings _settings = UserSettings();
  SettingsState _state = SettingsState.loading;
  String? _errorMessage;

  UserSettings get settings => _settings;
  SettingsState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> loadSettings() async {
    _state = SettingsState.loading;
    notifyListeners();
    try {
      _settings = await _settingsService.getSettings();
      _state = SettingsState.idle;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SettingsState.error;
    }
    notifyListeners();
  }

  Future<void> updateAndSaveSetting({
    String? theme,
    bool? notificationsEnabled,
  }) async {
    // Ayarları güncelle
    _settings = _settings.copyWith(
      theme: theme,
      notificationsEnabled: notificationsEnabled,
    );
    // Cihaza kaydet
    await _settingsService.saveSettings(_settings);
    // Değişikliği UI'a bildir
    notifyListeners();
  }

  // Veri silme gibi backend gerektiren işlemler artık bu ViewModel'de değil.
  // Bu tür işlemler, kendi özel ViewModel'lerinde (örneğin ProfileViewModel) yönetilmelidir.
}
