import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  ThemeProvider() {
    _initTheme();
  }

  bool get isDarkMode => _isDarkMode;

  // Tema ayarını başlat (arka planda)
  Future<void> _initTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      print('Tema yükleme hatası: $e');
    }
  }

  // Tema değiştir (hızlı, beklemeye gerek yok)
  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;

    // Arka planda kaydet (async)
    _saveThemeAsync(isOn);

    // Hemen UI güncelle
    notifyListeners();
  }

  // Arka planda kaydetme (UI bloke etmez)
  void _saveThemeAsync(bool isOn) {
    _prefs?.setBool('isDarkMode', isOn).catchError((e) {
      print('Tema kaydetme hatası: $e');
    });
  }
}
