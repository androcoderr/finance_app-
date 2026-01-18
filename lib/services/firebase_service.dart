// lib/services/firebase_service.dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'BaseService.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

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
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Kullanıcı bir bildirime tıkladı!');

      // Bildirimin içindeki gizli veriyi kontrol et
      if (message.data['type'] == '2fa_request') {
        final sessionToken = message.data['session_token'];
        if (sessionToken != null) {
          print('2FA Onay isteği yakalandı. Session Token: $sessionToken');

          // KULLANICIYA SOR: Onaylıyor musun? Reddediyor musun?
          // Şimdilik otomatik onayladığımızı varsayalım. Gerçek uygulamada
          // bir dialog ile kullanıcıya sorabilirsiniz.
          sendVerificationResponse(sessionToken, true);
        }
      }
    });
  }

  // Sunucuya "Onaylıyorum" veya "Reddediyorum" isteğini gönderen metot
  Future<void> sendVerificationResponse(
    String sessionToken,
    bool isApproved,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}/api/2fa/verify/$sessionToken'),
        headers: {'Content-Type': 'application/json'},
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
