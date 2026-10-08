import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/finance_model.dart';

/// Piyasa verileri. Yalnızca gerçek kaynaklardan gelen veriler gösterilir;
/// bir kaynak yanıt vermezse o kalem listeden çıkar (tahmini/örnek veri yok).
/// `change` her kalemde aynı birimdedir: fiyat - önceki kapanış.
class FinanceService {
  static const String _yahooFinanceUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';
  static const String _coinGeckoUrl =
      'https://api.coingecko.com/api/v3/simple/price';
  static const Duration _timeout = Duration(seconds: 10);
  static const double _gramsPerTroyOunce = 31.1034768;

  final http.Client _client = http.Client();

  // Döviz kurları (TRY karşılığı)
  Future<List<FinanceModel>> fetchExchangeRates() async {
    final quotes = await Future.wait([
      _yahooQuote('USDTRY=X'),
      _yahooQuote('EURTRY=X'),
      _yahooQuote('GBPTRY=X'),
    ]);
    final items = <FinanceModel>[];
    void add(_Quote? q, String name, String symbol) {
      if (q != null) items.add(q.toModel(name, '₺', symbol));
    }

    add(quotes[0], 'USD/TRY', '💵');
    add(quotes[1], 'EUR/TRY', '💶');
    add(quotes[2], 'GBP/TRY', '💷');
    if (items.isEmpty) throw Exception('Döviz verileri alınamadı');
    return items;
  }

  // BIST endeksleri
  Future<List<FinanceModel>> fetchBISTData() async {
    final quotes = await Future.wait([
      _yahooQuote('XU100.IS'),
      _yahooQuote('XU030.IS'),
    ]);
    final items = <FinanceModel>[];
    if (quotes[0] != null) items.add(quotes[0]!.toModel('BIST 100', 'TL', '📊'));
    if (quotes[1] != null) items.add(quotes[1]!.toModel('BIST 30', 'TL', '📈'));
    if (items.isEmpty) throw Exception('BIST verileri alınamadı');
    return items;
  }

  // Altın ve gümüş. Gram altın (24 ayar) ons fiyatı ve USD/TRY kurundan hesaplanır;
  // kuyumcu ürünleri (çeyrek, tam vb.) işçilik farkı içerdiği için gösterilmez.
  Future<List<FinanceModel>> fetchTurkishGoldData() async {
    final quotes = await Future.wait([
      _yahooQuote('GC=F'),
      _yahooQuote('SI=F'),
      _yahooQuote('USDTRY=X'),
    ]);
    final gold = quotes[0], silver = quotes[1], usdTry = quotes[2];
    final items = <FinanceModel>[];

    if (gold != null && usdTry != null) {
      final gram = gold.price / _gramsPerTroyOunce * usdTry.price;
      final prevGram =
          gold.previousClose / _gramsPerTroyOunce * usdTry.previousClose;
      items.add(
        _Quote(gram, prevGram).toModel('Gram Altın (24 ayar)', '₺', '🥇'),
      );
    }
    if (gold != null) items.add(gold.toModel('Ons Altın', '\$', '🟡'));
    if (silver != null) items.add(silver.toModel('Ons Gümüş', '\$', '🥈'));
    if (items.isEmpty) throw Exception('Altın verileri alınamadı');
    return items;
  }

  // Kripto paralar (USD). CoinGecko 24 saatlik değişimi yüzde verir; diğer
  // kalemlerle aynı birimde olsun diye fiyat farkına çevrilir.
  Future<List<FinanceModel>> fetchCryptoData() async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_coinGeckoUrl?ids=bitcoin,ethereum,cardano,binancecoin&vs_currencies=usd&include_24hr_change=true',
            ),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      const coins = {
        'bitcoin': ('Bitcoin (BTC)', '₿'),
        'ethereum': ('Ethereum (ETH)', 'Ξ'),
        'cardano': ('Cardano (ADA)', '₳'),
        'binancecoin': ('Binance Coin (BNB)', '🔶'),
      };
      final items = <FinanceModel>[];
      coins.forEach((id, info) {
        final coin = data[id];
        final price = (coin?['usd'] as num?)?.toDouble();
        if (price == null) return;
        final pct = (coin['usd_24h_change'] as num?)?.toDouble() ?? 0.0;
        final previous = price / (1 + pct / 100);
        items.add(_Quote(price, previous).toModel(info.$1, '\$', info.$2));
      });
      if (items.isEmpty) throw Exception('Kripto verisi yok');
      return items;
    } on TimeoutException {
      throw Exception('Kripto servisi zaman aşımına uğradı');
    }
  }

  /// Yahoo Finance'tan son fiyat ve önceki kapanış. Hata olursa null döner.
  Future<_Quote?> _yahooQuote(String symbol) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_yahooFinanceUrl/${Uri.encodeComponent(symbol)}'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final meta = json.decode(response.body)['chart']['result'][0]['meta'];
      final price = (meta['regularMarketPrice'] as num?)?.toDouble();
      final previous =
          ((meta['previousClose'] ?? meta['chartPreviousClose']) as num?)
              ?.toDouble();
      if (price == null || previous == null || previous == 0) return null;
      return _Quote(price, previous);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

class _Quote {
  final double price;
  final double previousClose;
  _Quote(this.price, this.previousClose);

  FinanceModel toModel(String name, String currency, String symbol) =>
      FinanceModel(
        name: name,
        price: price,
        change: price - previousClose,
        currency: currency,
        symbol: symbol,
        lastUpdate: DateTime.now(),
      );
}
