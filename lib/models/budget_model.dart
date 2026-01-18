class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double limitAmount;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    userId: json['user_id'],
    categoryId: json['category_id'],
    limitAmount: (json['limit_amount'] as num).toDouble(),
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'limit_amount': limitAmount,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}
