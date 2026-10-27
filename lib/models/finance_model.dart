/// Piyasa kalemi (sunucudaki GET /markets yanıtından)
enum MarketCategory { fx, crypto }

class FinanceModel {
  final String id; // USD, EUR, bitcoin…
  final MarketCategory category;
  final String name; // USD/TRY, Bitcoin (BTC)
  final double price;
  final double change; // fiyat − önceki değer (fiyatla aynı birim)
  final String currency; // ₺ ya da $

  const FinanceModel({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    required this.change,
    required this.currency,
  });

  factory FinanceModel.fromJson(Map<String, dynamic> json) => FinanceModel(
        id: '${json['id'] ?? ''}',
        category: json['category'] == 'crypto' ? MarketCategory.crypto : MarketCategory.fx,
        name: '${json['name'] ?? ''}',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        change: (json['change'] as num?)?.toDouble() ?? 0,
        currency: '${json['currency'] ?? ''}',
      );

  /// Önceki değere göre yüzde değişim
  double get changePercentage {
    final previous = price - change;
    return previous == 0 ? 0 : change / previous * 100;
  }
}

/// GET /markets yanıtının tamamı
class MarketsResult {
  final List<FinanceModel> items;
  final DateTime? updatedAt;
  final String? fxRateDate; // ECB kurlarının tarihi (YYYY-MM-DD)
  final bool stale; // kaynak yanıt vermedi, son alınan değerler

  const MarketsResult({
    required this.items,
    this.updatedAt,
    this.fxRateDate,
    this.stale = false,
  });

  factory MarketsResult.fromJson(Map<String, dynamic> json) => MarketsResult(
        items: [
          for (final x in (json['items'] as List? ?? const []))
            if (x is Map) FinanceModel.fromJson(Map<String, dynamic>.from(x)),
        ],
        updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}')?.toLocal(),
        fxRateDate: (json['sources'] as Map?)?['fx']?['rate_date'] as String?,
        stale: json['stale'] == true,
      );
}
