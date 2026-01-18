enum TransactionType { income, expense }

TransactionType transactionTypeFromString(String value) =>
    value == 'income' ? TransactionType.income : TransactionType.expense;

String transactionTypeToString(TransactionType type) =>
    type == TransactionType.income ? 'income' : 'expense';

class TransactionModel {
  final String? id;
  final String userId;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;
  final TransactionType type;
  final String? linkedGoalId;

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    this.description = '',
    required this.date,
    required this.type,
    this.linkedGoalId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'],
        userId: json['user_id'],
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['category_id'],
        description: json['description'] ?? '',
        // 🔥 tarih artık local’e çekiliyor
        date: DateTime.parse(json['date']).toLocal(),
        type: transactionTypeFromString(json['type']),
        linkedGoalId: json['linked_goal_id'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    'date': date.toIso8601String(),
    'type': transactionTypeToString(type),
    'linked_goal_id': linkedGoalId,
  };

  Map<String, dynamic> toApiJson() => {
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    'date': date.toIso8601String(),
    'type': transactionTypeToString(type),
  };
}
