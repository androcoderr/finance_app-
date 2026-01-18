// lib/models/shopping_list_item.dart

class ShoppingListItem {
  final int? id; // Veritabanı için Primary Key (nullable olabilir)
  String name;
  bool isBought;

  ShoppingListItem({this.id, required this.name, this.isBought = false});

  // Nesneyi veritabanına yazmak için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // SQLite'ta boolean tipi yoktur, bu yüzden 1 (true) ve 0 (false) kullanırız.
      'isBought': isBought ? 1 : 0,
    };
  }

  // Veritabanından okunan Map'i nesneye dönüştürür.
  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      name: map['name'],
      isBought: map['isBought'] == 1,
    );
  }
}
