// lib/services/database_helper.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shopping_list_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('shopping.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);


      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      debugPrint('❌ Veritabanı başlatma hatası: $e');
      debugPrint('Hata detayı: ${e.toString()}');
      rethrow; // Hatayı yukarı fırlat
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE shopping_items ( 
        id $idType, 
        name $textType,
        isBought $boolType
      )
    ''');

  }

  Future<ShoppingListItem> create(ShoppingListItem item) async {
    final db = await instance.database;
    final id = await db.insert('shopping_items', item.toMap());
    return ShoppingListItem(id: id, name: item.name, isBought: item.isBought);
  }

  Future<List<ShoppingListItem>> readAllItems() async {
    try {
      final db = await instance.database;

      final orderBy = 'id DESC';
      final result = await db.query('shopping_items', orderBy: orderBy);

      return result.map((json) => ShoppingListItem.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ readAllItems hatası: $e');
      debugPrint('Hata stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<int> update(ShoppingListItem item) async {
    final db = await instance.database;
    return db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  /// Çıkışta/hesap silmede: liste cihazda tutulduğu için sonraki kullanıcı görmesin
  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('shopping_items');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
