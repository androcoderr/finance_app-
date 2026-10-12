// lib/services/firebase_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase bildirim altyapısı (v1'de yalnızca kAiEnabled açıkken kurulur)
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
}
