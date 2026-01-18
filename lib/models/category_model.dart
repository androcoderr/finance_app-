class Category {
  final String id;
  final String name;
  final bool isIncome;

  Category({required this.id, required this.name, required this.isIncome});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'], name: json['name'], isIncome: json['is_income']);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_income': isIncome,
  };
}
