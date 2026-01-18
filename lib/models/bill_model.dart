// GET /bills endpoint'inden dönen tüm cevabı temsil eder
class BillsResponse {
  final List<UpcomingBill> upcoming;
  final List<UpcomingBill> overdue;

  BillsResponse({required this.upcoming, required this.overdue});

  factory BillsResponse.fromJson(Map<String, dynamic> json) {
    return BillsResponse(
      upcoming: (json['upcoming'] as List)
          .map((item) => UpcomingBill.fromJson(item))
          .toList(),
      overdue: (json['overdue'] as List)
          .map((item) => UpcomingBill.fromJson(item))
          .toList(),
    );
  }
}

// Fatura listelerinde gösterilecek modeli temsil eder (status, days_diff içerir)
class UpcomingBill {
  final String id;
  final String name;
  final double amount;
  final int dueDay;
  final String category;
  final String status;
  final int daysDiff;
  final bool isActive;
  final DateTime createdAt;
  final String recurrence;

  UpcomingBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.category,
    required this.status,
    required this.daysDiff,
    required this.isActive,
    required this.createdAt,
    required this.recurrence,
  });

  factory UpcomingBill.fromJson(Map<String, dynamic> json) {
    return UpcomingBill(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['due_day'],
      category: json['category'],
      status: json['status'],
      daysDiff: json['days_diff'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      recurrence: json['recurrence'],
    );
  }
}

// Yeni fatura oluşturmak için kullanılan model
class Bill {
  final String? id;
  final String name;
  final double amount;
  final int dueDay;
  final String category;

  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'category': category,
    };
  }
}
