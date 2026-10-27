import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart' show navigatorKey;
import '../utils/app_info.dart';
import '../views/force_update_page.dart';
import 'base_service.dart';

/// Sürüm kontrolü: sunucu eski sürümü desteklemiyorsa zorunlu güncelleme ekranı.
class AppUpdateService {
  /// pubspec "version: 1.0.0+N" içindeki N (Android versionCode)
  static int versionCode = 0;
  static String versionName = kAppVersion;

  static bool _forcedShown = false;
  static bool _optionalShown = false;

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      versionCode = int.tryParse(info.buildNumber) ?? 0;
      versionName = info.version;
    } catch (_) {}
  }

  /// Kendi sunucumuza giden her isteğe eklenir
  static Map<String, String> get header => {
        'X-App-Version-Code': '$versionCode',
        'X-App-Platform': kPlatformName,
      };

  /// Açılışta çağrılır. Ağ hatasında uygulamayı engellemez (null döner).
  static Future<AppConfig?> fetchConfig() async {
    try {
      final res = await http
          .get(
            Uri.parse('${BaseService.baseUrl}/app/config?platform=$kPlatformName&version_code=$versionCode'),
            headers: header,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      return AppConfig.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  /// Zorunlu güncelleme ekranını aç (tekrar açılmaz; geri dönüş yok)
  static void showForcedUpdate({String? message, String? storeUrl}) {
    if (_forcedShown) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    _forcedShown = true;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForceUpdatePage(
          message: message,
          storeUrl: storeUrl ?? kStoreUrl,
        ),
      ),
      (_) => false,
    );
  }

  /// İsteğe bağlı güncelleme uyarısı (oturum başına bir kez)
  static Future<void> showOptionalUpdate(AppConfig config) async {
    if (_optionalShown) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    _optionalShown = true;
    final update = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni sürüm var'),
        content: const Text('Uygulamanın yeni bir sürümü yayında. Şimdi güncellemek ister misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Sonra')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Güncelle')),
        ],
      ),
    );
    if (update == true) await startUpdate(config.storeUrl);
  }

  /// Play'den kurulduysa uygulama içinden güncelle; değilse mağaza sayfasını aç
  static Future<void> startUpdate(String storeUrl) => ForceUpdatePage.update(storeUrl);
}

class AppConfig {
  final bool updateRequired;
  final bool updateAvailable;
  final String storeUrl;
  final String? message;

  AppConfig({
    required this.updateRequired,
    required this.updateAvailable,
    required this.storeUrl,
    this.message,
  });

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        updateRequired: j['update_required'] == true,
        updateAvailable: j['update_available'] == true,
        // iOS'ta App Store bağlantısı henüz yoksa sunucu null döner
        storeUrl: (j['store_url'] as String?) ?? kStoreUrl,
        message: j['message'] as String?,
      );
}
