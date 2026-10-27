import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/models/transaction_model.dart';
import 'package:test_borsa/views/all_transactions_page.dart';

TransactionModel tx(String cat, double amount, TransactionType type, DateTime date,
        [String desc = '']) =>
    TransactionModel(
        userId: 'u', amount: amount, categoryId: cat, date: date, type: type, description: desc);

void main() {
  const names = {'m': 'Market', 'k': 'Konut', 's': 'Maaş'};
  String? nameOf(String id) => names[id];
  final list = [
    tx('m', 500, TransactionType.expense, DateTime(2026, 10, 12), 'Haftalık alışveriş'),
    tx('k', 12500, TransactionType.expense, DateTime(2026, 10, 8), 'Kira (Tekrarlayan)'),
    tx('s', 15000, TransactionType.income, DateTime(2026, 10, 1)),
    tx('m', 250, TransactionType.expense, DateTime(2026, 9, 20), 'Ekmek süt'),
    tx('f', 900, TransactionType.expense, DateTime(2026, 9, 2), 'Isıtma'),
  ];

  test('filtre yoksa hepsi', () {
    expect(filterTransactions(list, nameOf: nameOf).length, 5);
  });

  test('tür', () {
    expect(filterTransactions(list, type: TransactionType.income).length, 1);
    expect(filterTransactions(list, type: TransactionType.expense).length, 4);
  });

  test('ay', () {
    expect(filterTransactions(list, month: DateTime(2026, 9)).length, 2);
    expect(filterTransactions(list, month: DateTime(2026, 10)).length, 3);
  });

  test('kategori', () {
    expect(filterTransactions(list, categoryId: 'm').length, 2);
  });

  test('arama açıklamada ve kategori adında, büyük/küçük harf duyarsız', () {
    expect(filterTransactions(list, query: 'KİRA', nameOf: nameOf).length, 1);
    expect(filterTransactions(list, query: 'MAAŞ', nameOf: nameOf).length, 1);
    expect(filterTransactions(list, query: 'kira', nameOf: nameOf).length, 1);
    expect(filterTransactions(list, query: 'market', nameOf: nameOf).length, 2);
    expect(filterTransactions(list, query: '  maaş ', nameOf: nameOf).length, 1);
    expect(filterTransactions(list, query: 'ISITMA', nameOf: nameOf).length, 1);
    expect(filterTransactions(list, query: 'yok', nameOf: nameOf), isEmpty);
  });

  test('filtreler birlikte', () {
    final r = filterTransactions(list,
        query: 'market', month: DateTime(2026, 10), type: TransactionType.expense, nameOf: nameOf);
    expect(r.single.description, 'Haftalık alışveriş');
  });

  test('Türkçe alfabetik sıralama', () {
    final names = ['Ulaşım', 'Çocuk', 'Şans', 'Market', 'İçecekler', 'Isıtma', 'Eğlence', 'Ek Gelir'];
    names.sort(trCompare);
    expect(names, ['Çocuk', 'Eğlence', 'Ek Gelir', 'Isıtma', 'İçecekler', 'Market', 'Şans', 'Ulaşım']);
  });
}
