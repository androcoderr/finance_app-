import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/models/finance_model.dart';

void main() {
  final sample = {
    'updated_at': '2026-10-27T13:05:00Z',
    'stale': false,
    'sources': {
      'fx': {'name': 'Avrupa Merkez Bankası (ECB)', 'rate_date': '2026-10-27'},
      'crypto': {'name': 'CoinGecko', 'url': 'https://www.coingecko.com'},
    },
    'items': [
      {'id': 'USD', 'category': 'fx', 'name': 'USD/TRY', 'price': 42.0, 'change': 0.42, 'currency': '₺'},
      {'id': 'bitcoin', 'category': 'crypto', 'name': 'Bitcoin (BTC)', 'price': 66000, 'change': -1000, 'currency': '\$'},
      'bozuk kayıt',
    ],
  };

  test('GET /markets yanıtı okunur, bozuk kalem atlanır', () {
    final r = MarketsResult.fromJson(sample);
    expect(r.items.length, 2);
    expect(r.fxRateDate, '2026-10-27');
    expect(r.stale, isFalse);
    expect(r.updatedAt, isNotNull);
    expect(r.items.first.category, MarketCategory.fx);
    expect(r.items.last.category, MarketCategory.crypto);
    expect(r.items.last.price, 66000.0);
  });

  test('yüzde değişim önceki değere göre', () {
    final usd = MarketsResult.fromJson(sample).items.first;
    // önceki = 42 − 0.42 = 41.58 → %1,01
    expect(usd.changePercentage, closeTo(1.0101, 1e-4));
    final btc = MarketsResult.fromJson(sample).items.last;
    expect(btc.changePercentage, closeTo(-1.4925, 1e-4));
  });

  test('eksik alanlar ve eski veri işareti', () {
    final r = MarketsResult.fromJson({'stale': true, 'items': [{'name': 'EUR/TRY'}]});
    expect(r.stale, isTrue);
    expect(r.fxRateDate, isNull);
    expect(r.items.single.price, 0);
    expect(r.items.single.changePercentage, 0);
    expect(MarketsResult.fromJson({}).items, isEmpty);
  });
}
