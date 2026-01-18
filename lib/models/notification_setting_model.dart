/*class RecurringTransaction {
  final String id;
  final String userId;
  final double amount;
  final String categoryId;
  final String? description;
  final String type; // 'income' or 'expense'
  final DateTime startDate;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final DateTime? endDate;

  RecurringTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.frequency,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) => RecurringTransaction(
    id: json['id'],
    userId: json['user_id'],
    amount: (json['amount'] as num).toDouble(),
    categoryId: json['category_id'],
    description: json['description'],
    type: json['type'],
    startDate: DateTime.parse(json['start_date']),
    endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    frequency: json['frequency'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    'type': type,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'frequency': frequency,
  };
}
*/
