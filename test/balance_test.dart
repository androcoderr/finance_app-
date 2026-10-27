import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/models/transaction_model.dart';
import 'package:test_borsa/utils/balance.dart';

TransactionModel tx(double amount, TransactionType type, DateTime date) =>
    TransactionModel(userId: 'u', amount: amount, categoryId: 'c', date: date, type: type);

void main() {
  final income = TransactionType.income;
  final expense = TransactionType.expense;
  final oct = DateTime(2026, 10, 15);

  final list = [
    tx(15000, income, DateTime(2026, 10, 1)), // ayın ilk günü: dahil
    tx(6500, income, DateTime(2026, 10, 9, 10, 30)),
    tx(12500, expense, DateTime(2026, 10, 8)),
    tx(300.75, expense, DateTime(2026, 10, 31, 23, 59)), // ayın son dakikası: dahil
    tx(1000, expense, DateTime(2026, 9, 30, 23, 59)), // geçen ay: hariç
    tx(2000, income, DateTime(2026, 11, 1)), // gelecek ay: hariç
  ];

  test('ay toplamları ayın sınırlarına göre', () {
    expect(Balance.monthTotal(list, income, month: oct), 21500);
    expect(Balance.monthTotal(list, expense, month: oct), 12800.75);
  });

  test('başka ay', () {
    expect(Balance.monthTotal(list, expense, month: DateTime(2026, 9)), 1000);
    expect(Balance.monthTotal(list, income, month: DateTime(2026, 11)), 2000);
  });

  test('net bakiye tüm zamanlar', () {
    expect(Balance.net(list), closeTo(15000 + 6500 + 2000 - 12500 - 300.75 - 1000, 1e-9));
    expect(Balance.net([]), 0);
  });

  test('aralık → ocak yıl geçişi', () {
    final dec = [tx(100, expense, DateTime(2026, 12, 31)), tx(50, expense, DateTime(2027, 1, 1))];
    expect(Balance.monthTotal(dec, expense, month: DateTime(2026, 12)), 100);
    expect(Balance.monthTotal(dec, expense, month: DateTime(2027, 1)), 50);
  });
}
