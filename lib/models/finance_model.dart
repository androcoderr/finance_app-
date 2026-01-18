class FinanceModel {
  final String name;
  final double price;
  final double change;
  final String currency;
  final String symbol;
  final DateTime lastUpdate;

  FinanceModel({
    required this.name,
    required this.price,
    required this.change,
    required this.currency,
    required this.symbol,
    required this.lastUpdate,
  });

  factory FinanceModel.fromJson(Map<String, dynamic> json) {
    return FinanceModel(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? '',
      symbol: json['symbol'] ?? '',
      lastUpdate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'change': change,
      'currency': currency,
      'symbol': symbol,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  // Değişim yüzdesi hesaplama
  double get changePercentage {
    if (price == 0) return 0.0;
    return (change / (price - change)) * 100;
  }

  bool get isPositive => change >= 0;

  FinanceModel copyWith({
    String? name,
    double? price,
    double? change,
    String? currency,
    String? symbol,
    DateTime? lastUpdate,
  }) {
    return FinanceModel(
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      currency: currency ?? this.currency,
      symbol: symbol ?? this.symbol,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
