// lib/services/firebase_service.dart
import 'dart:convert';
import 'package:test_borsa/services/token_storage.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:test_borsa/services/api_http.dart' as http;
import 'BaseService.dart';

/// 2FA isteği geldiğinde kullanıcıya onay sormak için çağrılır (main.dart'ta atanır).
typedef TwoFactorRequestHandler =
    void Function(String title, String body, String sessionToken);

class FirebaseService {
  // Singleton pattern
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  TwoFactorRequestHandler? on2faRequest;

  // FCM Token getter
  String? get fcmToken => _fcmToken;

  // FCM Token'ı al
  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      print('FCM Token alınırken hata: $e');
      return null;
    }
  }

  // Notification izinleri iste
  Future<void> requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      print('Notification izinleri: ${settings.authorizationStatus}');
    } catch (e) {
      print('Notification izinleri alınırken hata: $e');
    }
  }

  // Background message handler
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print("Background mesaj: ${message.messageId}");
  }

  // Foreground message handler
  static Future<void> foregroundMessageHandler(RemoteMessage message) async {
    print("Foreground mesaj: ${message.messageId}");
  }

  Future<void> setupInteractedMessage() async {
    // Bu fonksiyon, kullanıcı arka plandaki veya kapalı durumdaki
    // bir bildirime tıkladığında çalışır.
    FirebaseMessaging.onMessageOpenedApp.listen(_handle2faMessage);

    // Uygulama kapalıyken bildirime tıklanarak açıldıysa
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Navigator henüz hazır değil; ilk frame çizildikten sonra göster
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handle2faMessage(initialMessage),
      );
    }
  }

  void _handle2faMessage(RemoteMessage message) {
    if (message.data['type'] != '2fa_request') return;
    final sessionToken = message.data['session_token'];
    if (sessionToken == null) return;

    // Asla otomatik onaylama: kullanıcıya sor
    on2faRequest?.call(
      message.notification?.title ?? 'Giriş Onayı',
      message.notification?.body ?? 'Giriş denemesini onaylıyor musunuz?',
      sessionToken,
    );
  }

  // Sunucuya "Onaylıyorum" veya "Reddediyorum" isteğini gönderen metot
  Future<void> sendVerificationResponse(
    String sessionToken,
    bool isApproved,
  ) async {
    try {
      final token = await TokenStorage.access() ?? '';
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}/api/2fa/verify/$sessionToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'approved': isApproved}),
      );
      if (response.statusCode == 200) {
        print('✅ 2FA cevabı sunucuya başarıyla gönderildi.');
      } else {
        print('❌ 2FA cevabı gönderilirken hata oluştu: ${response.body}');
      }
    } catch (e) {
      print('❌ 2FA cevabı gönderilirken ağ hatası: $e');
    }
  }
}
