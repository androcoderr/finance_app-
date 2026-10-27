class Goal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;
  final DateTime? targetDate;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
    this.targetDate,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    name: json['name'] ?? '',
    targetAmount: (json['target_amount'] ?? 0).toDouble(),
    currentAmount: (json['current_amount'] ?? 0).toDouble(),
    createdAt: DateTime.parse(
      json['created_at'] ?? DateTime.now().toIso8601String(),
    ),
    targetDate: _targetDateFrom(json),
  );

  /// Sunucu son tarihi `goal_dates` listesinde gönderir; en son eklenen geçerlidir
  static DateTime? _targetDateFrom(Map<String, dynamic> json) {
    if (json['target_date'] != null) return DateTime.tryParse(json['target_date']);
    final dates = (json['goal_dates'] as List?)
            ?.map((d) => DateTime.tryParse('${(d as Map)['date']}'))
            .whereType<DateTime>()
            .toList() ??
        [];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'created_at': createdAt.toIso8601String(),
    'target_date': targetDate?.toIso8601String(),
  };

  // ⚠️ COPYWITH METODU EKLENDİ
  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? createdAt,
    DateTime? targetDate,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
