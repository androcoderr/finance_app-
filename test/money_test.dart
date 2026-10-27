import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/utils/money.dart';
import 'package:test_borsa/views/widgets/ui/ui.dart' show trUpper, initialsOf;

void main() {
  group('Money.format', () {
    test('Türkçe binlik ayırıcı ve kuruş', () {
      expect(Money.format(18420.5), '₺18.420,50');
      expect(Money.format(1250), '₺1.250');
      expect(Money.format(0), '₺0');
    });

    test('kuruş zorla gösterilir / gizlenir', () {
      expect(Money.format(1250, decimals: true), '₺1.250,00');
      expect(Money.format(1250.75, decimals: false), '₺1.251');
    });

    test('işaret', () {
      expect(Money.format(-500), '−₺500');
      expect(Money.format(500, sign: true), '+₺500');
      expect(Money.format(-500, sign: true), '−₺500');
    });

    test('split: tam kısım ve kuruş ayrı', () {
      expect(Money.split(18420.5), ('₺18.420', ',50'));
      expect(Money.split(-256.49), ('−₺256', ',49'));
    });

    test('percent', () {
      expect(Money.percent(12), '%12');
      expect(Money.percent(4.56, decimals: 1), '%4,6');
      expect(Money.percent(-3), '%3');
    });
  });

  group('Türkçe metin', () {
    test('trUpper i/ı harflerini doğru büyütür', () {
      expect(trUpper('birikim'), 'BİRİKİM');
      expect(trUpper('ılık'), 'ILIK');
    });

    test('initialsOf', () {
      expect(initialsOf('ayşe kaya'), 'AK');
      expect(initialsOf('İkinci Kişi'), 'İK');
      expect(initialsOf('  '), '?');
      expect(initialsOf(null), '?');
    });
  });
}
