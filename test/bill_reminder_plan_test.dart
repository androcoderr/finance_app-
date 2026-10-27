import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/models/bill_model.dart';
import 'package:test_borsa/services/bill_reminder_service.dart';

UpcomingBill bill(String id, int dueDay, {bool active = true, String name = 'Doğalgaz'}) =>
    UpcomingBill(
      id: id,
      name: name,
      amount: 912.4,
      dueDay: dueDay,
      category: 'Doğalgaz',
      status: 'Bekliyor',
      daysDiff: 0,
      isActive: active,
      createdAt: DateTime(2026, 1, 1),
      recurrence: 'Aylık',
    );

void main() {
  final now = DateTime(2026, 10, 12, 14, 0);

  test('son günden bir gün önce ve son gün, bu ay ve gelecek ay, saat 10', () {
    final plan = planBillReminders(unpaid: [bill('a', 20)], paidThisMonth: [], now: now);
    expect(plan.map((r) => r.at), [
      DateTime(2026, 10, 19, 10),
      DateTime(2026, 10, 20, 10),
      DateTime(2026, 11, 19, 10),
      DateTime(2026, 11, 20, 10),
    ]);
    expect(plan.first.title, 'Doğalgaz faturası yarın');
    expect(plan.first.body, contains('₺912,40'));
    expect(plan[1].title, contains('son günü bugün'));
  });

  test('geçmiş zamanlar atlanır (bu ayın son günü geçtiyse sadece gelecek ay)', () {
    final plan = planBillReminders(unpaid: [bill('a', 5)], paidThisMonth: [], now: now);
    expect(plan.map((r) => r.at), [DateTime(2026, 11, 4, 10), DateTime(2026, 11, 5, 10)]);
  });

  test('bugün son gün ve saat 10 geçtiyse bugünkü de atlanır', () {
    final plan = planBillReminders(unpaid: [bill('a', 12)], paidThisMonth: [], now: now);
    expect(plan.first.at, DateTime(2026, 11, 11, 10));
  });

  test('bu ay ödenmiş fatura: yalnızca gelecek ay', () {
    final b = bill('a', 25);
    final plan = planBillReminders(unpaid: [], paidThisMonth: [b], now: now);
    expect(plan.map((r) => r.at), [DateTime(2026, 11, 24, 10), DateTime(2026, 11, 25, 10)]);
  });

  test('31 çeken gün kısa ayda ayın son gününe kayar', () {
    final feb = DateTime(2027, 2, 1, 9);
    final plan = planBillReminders(unpaid: [bill('a', 31)], paidThisMonth: [], now: feb);
    expect(plan.take(2).map((r) => r.at), [DateTime(2027, 2, 27, 10), DateTime(2027, 2, 28, 10)]);
    expect(plan.skip(2).map((r) => r.at), [DateTime(2027, 3, 30, 10), DateTime(2027, 3, 31, 10)]);
  });

  test('ayın 1i: bir gün önceki hatırlatma önceki ayın son günü', () {
    final plan = planBillReminders(unpaid: [bill('a', 1)], paidThisMonth: [], now: now);
    expect(plan.map((r) => r.at), [DateTime(2026, 10, 31, 10), DateTime(2026, 11, 1, 10)]);
  });

  test('pasif fatura atlanır, aynı fatura iki listede olsa da bir kez', () {
    final b = bill('a', 20);
    final plan = planBillReminders(
      unpaid: [b, bill('p', 21, active: false)],
      paidThisMonth: [b],
      now: now,
    );
    // Ödendi listesinde olduğu için bu ay atlanır, gelecek ay bir kez planlanır
    expect(plan.map((r) => r.at), [DateTime(2026, 11, 19, 10), DateTime(2026, 11, 20, 10)]);
  });

  test('sonuç zamana göre sıralı', () {
    final plan = planBillReminders(
      unpaid: [bill('a', 28, name: 'Kira'), bill('b', 15, name: 'Su')],
      paidThisMonth: [],
      now: now,
    );
    final times = plan.map((r) => r.at).toList();
    expect(times, [...times]..sort());
    expect(plan.first.title, startsWith('Su'));
  });
}
