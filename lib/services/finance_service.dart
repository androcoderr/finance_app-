import 'dart:convert';

import '../models/finance_model.dart';
import '../utils/error_handler.dart';
import 'api_http.dart' as http;
import 'base_service.dart';
import 'token_storage.dart';

/// Piyasa verileri yalnızca kendi sunucumuzdan gelir. Sunucu döviz kurlarını
/// ECB'den, kriptoyu CoinGecko'dan önbellekli çeker; telefon üçüncü taraf
/// servislere bağlanmaz (lisans ve gizlilik).
class FinanceService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<MarketsResult> fetchMarkets() async {
    try {
      final token = await TokenStorage.access() ?? '';
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/markets'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Piyasa verileri alınamadı (${response.statusCode})');
      }
      final result = MarketsResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (result.items.isEmpty) throw Exception('Piyasa verisi yok');
      return result;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
