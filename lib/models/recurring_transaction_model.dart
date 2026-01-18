import 'transaction_model.dart';

class RecurringTransaction {
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

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    print('🔄 [RecurringTransaction.fromJson] Parsing...');
    print('   Data: $json');

    try {
      final rec = RecurringTransaction(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        amount: (json['amount'] is int)
            ? (json['amount'] as int).toDouble()
            : (json['amount'] as num?)?.toDouble() ?? 0.0,
        categoryId: json['category_id']?.toString() ?? '',
        description: json['description']?.toString(),
        type: json['type']?.toString() ?? 'expense',
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'])
            : DateTime.now(),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'])
            : null,
        frequency: json['frequency']?.toString() ?? 'monthly',
      );

      print('   ✅ Parsed: ${rec.description} - ${rec.amount} TL (${rec.type})');
      return rec;
    } catch (e, stackTrace) {
      print('   ❌ Error: $e');
      print('   Stack: $stackTrace');
      rethrow;
    }
  }

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

  /// RecurringTransaction'ı TransactionModel'e dönüştürür
  /// [date] parametresi verilmezse bugünün tarihi kullanılır
  TransactionModel toTransaction({DateTime? date}) {
    print('🔄 Converting recurring to transaction: $description');

    return TransactionModel(
      id: id,
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      description: description ?? 'Tekrarlanan İşlem',
      type: transactionTypeFromString(type),
      date: date ?? DateTime.now(),
      linkedGoalId: null,
    );
  }

  /// Bu recurring transaction'ın bu ay için geçerli olup olmadığını kontrol eder
  bool isActiveThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Start date bu aydan sonra mı?
    if (startDate.isAfter(endOfMonth)) {
      return false;
    }

    // End date varsa ve bu aydan önce mi?
    if (endDate != null && endDate!.isBefore(startOfMonth)) {
      return false;
    }

    return true;
  }

  RecurringTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? categoryId,
    String? description,
    String? type,
    DateTime? startDate,
    String? frequency,
    DateTime? endDate,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      endDate: endDate ?? this.endDate,
    );
  }
}
