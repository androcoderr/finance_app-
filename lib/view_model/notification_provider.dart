import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((notif) {
    // Null-safe kontrol
    return !notif.isRead;
  }).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        _notifications = decoded
            .map((item) => NotificationModel.fromJson(item))
            .toList();

        // Eski bildirimleri temizle (7 günden eski)
        _notifications = _notifications.where((notif) {
          return DateTime.now().difference(notif.timestamp).inDays < 7;
        }).toList();

        notifyListeners();
      }
    } catch (e) {
      print('Bildirimler yüklenirken hata: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((notif) => notif.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      print('Bildirimler kaydedilirken hata: $e');
    }
  }

  Future<void> addNotification({
    required String message,
    required bool isAnomaly,
    String? transactionId,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isAnomaly: isAnomaly,
      timestamp: DateTime.now(),
      transactionId: transactionId,
      isRead: false,
    );

    _notifications.insert(0, notification);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((notif) => notif.id == id);
    if (index != -1) {
      _notifications[index].markAsRead();
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.markAsRead();
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((notif) => notif.id == id);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }

  // Eski verileri temizlemek için
  Future<void> clearAndResetNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    _notifications.clear();
    notifyListeners();
    print('Tüm bildirimler temizlendi');
  }
}
