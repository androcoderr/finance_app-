import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/bill_model.dart';
import '../utils/money.dart';

/// Planlanacak tek bir hatırlatma
class PlannedReminder {
  final DateTime at;
  final String title;
  final String body;
  const PlannedReminder(this.at, this.title, this.body);

  @override
  String toString() => '$at $title — $body';
}

/// Faturaların son ödeme günlerinden hatırlatma zamanlarını hesaplar (saf
/// fonksiyon; testlerde kullanılır). Her fatura için bu ay ve gelecek ay:
/// son günden bir gün önce ve son gün, saat [hour]'da. Bu ay ödenmiş
/// faturaların yalnızca gelecek ayı planlanır. Geçmiş zamanlar atlanır.
List<PlannedReminder> planBillReminders({
  required List<UpcomingBill> unpaid,
  required List<UpcomingBill> paidThisMonth,
  required DateTime now,
  int hour = 10,
}) {
  final paidIds = paidThisMonth.map((b) => b.id).toSet();
  final seen = <String>{};
  final result = <PlannedReminder>[];

  for (final bill in [...unpaid, ...paidThisMonth]) {
    if (!bill.isActive || !seen.add(bill.id)) continue;
    for (var offset = 0; offset < 2; offset++) {
      if (offset == 0 && paidIds.contains(bill.id)) continue;
      final firstOfMonth = DateTime(now.year, now.month + offset);
      final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
      final day = bill.dueDay.clamp(1, lastDay);
      final due = DateTime(firstOfMonth.year, firstOfMonth.month, day, hour);
      final amount = Money.format(bill.amount);

      final dayBefore = DateTime(due.year, due.month, due.day - 1, hour);
      if (dayBefore.isAfter(now)) {
        result.add(PlannedReminder(
          dayBefore,
          '${bill.name} faturası yarın',
          'Son ödeme günü yarın · $amount',
        ));
      }
      if (due.isAfter(now)) {
        result.add(PlannedReminder(
          due,
          '${bill.name} faturasının son günü bugün',
          'Ödemeyi unutma · $amount',
        ));
      }
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

/// Fatura hatırlatmaları: telefonda yerel olarak planlanır, sunucuya bir şey
/// gönderilmez. Kullanıcı Ayarlar'dan ya da Faturalar ekranından açar.
class BillReminders {
  static const _enabledKey = 'bill_reminders_enabled';
  static const _bannerDismissedKey = 'bill_reminders_banner_dismissed';
  static const payload = 'bills';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bill_reminders',
      'Fatura hatırlatmaları',
      channelDescription: 'Son ödeme günü yaklaşan faturalar',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_bill',
      color: Color(0xFF0B5CD5),
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Uygulama açılışında bir kez. Bildirime dokunulunca [onOpen] çağrılır.
  static Future<void> init({required VoidCallback onOpen}) async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_bill'),
          // İzin açılışta değil, kullanıcı hatırlatmaları açınca istenir
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          if (r.payload == payload) onOpen();
        },
      );
      _ready = true;
    } catch (e) {
      debugPrint('Bildirim altyapısı başlatılamadı: $e');
    }
  }

  /// Uygulama kapalıyken bildirime dokunularak mı açıldı?
  static Future<bool> launchedFromReminder() async {
    if (!_ready) return false;
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == payload;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<bool> isBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bannerDismissedKey) ?? false;
  }

  static Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bannerDismissedKey, true);
  }

  /// Bildirim iznini ister (Android 13+). İzin verilmezse false döner ve
  /// hatırlatmalar kapalı kalır.
  static Future<bool> enable() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await (android?.requestNotificationsPermission() ??
            ios?.requestPermissions(alert: true, sound: true)) ??
        true;
    if (!granted) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setBool(_bannerDismissedKey, true);
    return true;
  }

  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    await cancelAll();
  }

  static Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  /// Fatura listesi her yüklendiğinde: eskileri sil, güncel listeye göre yeniden kur
  static Future<void> sync({
    required List<UpcomingBill> unpaid,
    required List<UpcomingBill> paidThisMonth,
  }) async {
    if (!_ready || !await isEnabled()) return;
    try {
      await _plugin.cancelAll();
      final plan = planBillReminders(
        unpaid: unpaid,
        paidThisMonth: paidThisMonth,
        now: DateTime.now(),
      );
      for (var i = 0; i < plan.length; i++) {
        final r = plan[i];
        await _plugin.zonedSchedule(
          id: i,
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          notificationDetails: _details,
          // Tam zamanlı alarm izni gerekmesin: birkaç dakika sapabilir
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Fatura hatırlatmaları kurulamadı: $e');
    }
  }
}
