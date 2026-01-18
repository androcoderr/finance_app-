// Bu dosya, backend'den gelen ayarlar JSON'ını Dart nesnesine çevirir.

class UserSettings {
  final String theme;
  final bool notificationsEnabled;
  final String currency;

  UserSettings({
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.currency = 'TRY',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] ?? 'system',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      currency: json['currency'] ?? 'TRY',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'currency': currency,
    };
  }

  UserSettings copyWith({
    String? theme,
    bool? notificationsEnabled,
    String? currency,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      currency: currency ?? this.currency,
    );
  }
}
