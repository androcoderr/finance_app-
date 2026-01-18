import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/finance_model.dart';

class FinanceService {
  static const String _exchangeRateUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _yahooFinanceUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';
  static const String _coinGeckoUrl =
      'https://api.coingecko.com/api/v3/simple/price';
  static const Duration _timeout = Duration(seconds: 10);

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Döviz kurları - Geliştirilmiş
  Future<List<FinanceModel>> fetchExchangeRates() async {
    try {
      final response = await _client
          .get(Uri.parse(_exchangeRateUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        List<FinanceModel> currencies = [];

        // USD/TR
        if (rates.containsKey('TRY')) {
          currencies.add(
            FinanceModel(
              name: 'USD/TRY',
              price: rates['TRY']?.toDouble() ?? 0.0,
              change:
                  _calculateRandomChange(), // Gerçek uygulamada önceki veriden hesaplanır
              currency: '₺',
              symbol: '💵',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        // EUR/TRY
        if (rates.containsKey('EUR') && rates.containsKey('TRY')) {
          double eurToUsd = 1 / rates['EUR'];
          double eurTry = eurToUsd * rates['TRY'];
          currencies.add(
            FinanceModel(
              name: 'EUR/TRY',
              price: eurTry,
              change: _calculateRandomChange(),
              currency: '₺',
              symbol: '💶',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        // GBP/TRY
        if (rates.containsKey('GBP') && rates.containsKey('TRY')) {
          double gbpToUsd = 1 / rates['GBP'];
          double gbpTry = gbpToUsd * rates['TRY'];
          currencies.add(
            FinanceModel(
              name: 'GBP/TRY',
              price: gbpTry,
              change: _calculateRandomChange(),
              currency: '₺',
              symbol: '💷',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        return currencies;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Döviz verileri alınamadı',
        );
      }
    } on TimeoutException {
      throw Exception('Bağlantı zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Döviz servisi hatası: $e');
    }
  }

  // BIST verileri - Geliştirilmiş
  Future<List<FinanceModel>> fetchBISTData() async {
    try {
      final response = await _client
          .get(Uri.parse('$_yahooFinanceUrl/XU100.IS'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['chart'] == null ||
            data['chart']['result'] == null ||
            data['chart']['result'].isEmpty) {
          throw Exception('BIST verisi bulunamadı');
        }

        final result = data['chart']['result'][0];
        final meta = result['meta'];

        double currentPrice = meta['regularMarketPrice']?.toDouble() ?? 0.0;
        double previousClose = meta['previousClose']?.toDouble() ?? 0.0;
        double change = currentPrice - previousClose;

        List<FinanceModel> bistData = [
          FinanceModel(
            name: 'BIST 100',
            price: currentPrice,
            change: change,
            currency: 'TL',
            symbol: '📊',
            lastUpdate: DateTime.now(),
          ),
        ];

        // Diğer BIST endeksleri (örnek veriler)
        bistData.add(
          FinanceModel(
            name: 'BIST 30',
            price: currentPrice * 0.85,
            change: change * 0.9,
            currency: 'TL',
            symbol: '📈',
            lastUpdate: DateTime.now(),
          ),
        );

        return bistData;
      } else {
        throw Exception('HTTP ${response.statusCode}: BIST verileri alınamadı');
      }
    } on TimeoutException {
      throw Exception('BIST servisi zaman aşımına uğradı');
    } catch (e) {
      throw Exception('BIST servisi hatası: $e');
    }
  }

  // Kripto verileri - Geliştirilmiş
  Future<List<FinanceModel>> fetchCryptoData() async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_coinGeckoUrl?ids=bitcoin,ethereum,cardano,binancecoin&vs_currencies=usd&include_24hr_change=true',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        List<FinanceModel> cryptos = [];

        // Bitcoin
        if (data.containsKey('bitcoin')) {
          final bitcoin = data['bitcoin'];
          cryptos.add(
            FinanceModel(
              name: 'Bitcoin (BTC)',
              price: bitcoin['usd']?.toDouble() ?? 0.0,
              change: bitcoin['usd_24h_change']?.toDouble() ?? 0.0,
              currency: '\$',
              symbol: '₿',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        // Ethereum
        if (data.containsKey('ethereum')) {
          final ethereum = data['ethereum'];
          cryptos.add(
            FinanceModel(
              name: 'Ethereum (ETH)',
              price: ethereum['usd']?.toDouble() ?? 0.0,
              change: ethereum['usd_24h_change']?.toDouble() ?? 0.0,
              currency: '\$',
              symbol: 'Ξ',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        // Cardano
        if (data.containsKey('cardano')) {
          final cardano = data['cardano'];
          cryptos.add(
            FinanceModel(
              name: 'Cardano (ADA)',
              price: cardano['usd']?.toDouble() ?? 0.0,
              change: cardano['usd_24h_change']?.toDouble() ?? 0.0,
              currency: '\$',
              symbol: '₳',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        // Binance Coin
        if (data.containsKey('binancecoin')) {
          final bnb = data['binancecoin'];
          cryptos.add(
            FinanceModel(
              name: 'Binance Coin (BNB)',
              price: bnb['usd']?.toDouble() ?? 0.0,
              change: bnb['usd_24h_change']?.toDouble() ?? 0.0,
              currency: '\$',
              symbol: 'BNB',
              lastUpdate: DateTime.now(),
            ),
          );
        }

        return cryptos;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Kripto verileri alınamadı',
        );
      }
    } on TimeoutException {
      throw Exception('Kripto servisi zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Kripto servisi hatası: $e');
    }
  }

  // Türkiye altın fiyatları - Geliştirilmiş
  Future<List<FinanceModel>> fetchTurkishGoldData() async {
    try {
      // USD/TRY kurunu al
      final response = await _client
          .get(Uri.parse(_exchangeRateUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double usdTryRate = data['rates']['TRY']?.toDouble() ?? 32.0;

        // Gerçek altın fiyatı (örnek veri)
        const double goldOuncePrice = 2025.50;
        double goldPricePerGramTRY = (goldOuncePrice / 31.1035) * usdTryRate;

        return [
          FinanceModel(
            name: 'Altın (Gram TL)',
            price: goldPricePerGramTRY,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '🥇',
            lastUpdate: DateTime.now(),
          ),
          FinanceModel(
            name: 'Çeyrek Altın',
            price: goldPricePerGramTRY * 1.75,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '🪙',
            lastUpdate: DateTime.now(),
          ),
          FinanceModel(
            name: 'Yarım Altın',
            price: goldPricePerGramTRY * 3.5,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '🪙',
            lastUpdate: DateTime.now(),
          ),
          FinanceModel(
            name: 'Tam Altın',
            price: goldPricePerGramTRY * 7.0,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '🪙',
            lastUpdate: DateTime.now(),
          ),
          FinanceModel(
            name: '22 Ayar Altın',
            price: goldPricePerGramTRY * 0.916,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '💛',
            lastUpdate: DateTime.now(),
          ),
          FinanceModel(
            name: 'Gremse Altın',
            price: goldPricePerGramTRY * 0.995,
            change: _calculateRandomChange(),
            currency: '₺',
            symbol: '🟡',
            lastUpdate: DateTime.now(),
          ),
        ];
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Altın verileri alınamadı',
        );
      }
    } on TimeoutException {
      throw Exception('Altın servisi zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Türk altın servisi hatası: $e');
    }
  }

  // Uluslararası altın fiyatları
  Future<List<FinanceModel>> fetchInternationalGoldData() async {
    try {
      // Basit bir örnek - gerçek uygulamada farklı API kullanabilirsiniz
      return [
        FinanceModel(
          name: 'Gold (USD/Ounce)',
          price: 2025.50,
          change: _calculateRandomChange(),
          currency: '\$',
          symbol: '🥇',
          lastUpdate: DateTime.now(),
        ),
        FinanceModel(
          name: 'Silver (USD/Ounce)',
          price: 25.35,
          change: _calculateRandomChange(),
          currency: '\$',
          symbol: '🥈',
          lastUpdate: DateTime.now(),
        ),
      ];
    } catch (e) {
      throw Exception('Uluslararası altın servisi hatası: $e');
    }
  }

  // Helper method - rastgele değişim hesaplama (demo için)
  double _calculateRandomChange() {
    // Gerçek uygulamada bu önceki fiyat ile karşılaştırma yapılır
    return (DateTime.now().millisecondsSinceEpoch % 200 - 100) / 10.0;
  }

  // Temizlik
  void dispose() {
    _client.close();
  }
}
