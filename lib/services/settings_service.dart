import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings_model.dart';

// Bu servis, ayarları backend yerine doğrudan cihazın hafızasına kaydeder ve okur.
class SettingsService {
  static const _themeKey = 'app_theme';
  static const _notificationsKey = 'app_notifications';

  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey) ?? 'system';
    final notifications = prefs.getBool(_notificationsKey) ?? true;

    return UserSettings(theme: theme, notificationsEnabled: notifications);
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, settings.theme);
    await prefs.setBool(_notificationsKey, settings.notificationsEnabled);
  }
}
