// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shopping_list_item.dart';
import 'dart:io' show Platform;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    _initDatabaseFactory();
  }

  // Desktop için sqflite_common_ffi'yi başlat
  void _initDatabaseFactory() {
    // Desktop platformlarda sqflite_common_ffi gereklidir
    if (Platform.isWindows || Platform.isLinux) {
      try {
        // sqflite_common_ffi kullanıyorsanız bu satırları aktif edin:
        // import 'package:sqflite_common_ffi/sqflite_ffi.dart';
        // databaseFactory = databaseFactoryFfi;
        print('⚠️ Desktop platform algılandı. sqflite_common_ffi gerekebilir.');
      } catch (e) {
        print('Platform kontrolünde hata: $e');
      }
    }
  }

  Future<Database> get database async {
    if (_database != null) {
      print('✅ Mevcut veritabanı kullanılıyor');
      return _database!;
    }

    print('🔄 Yeni veritabanı oluşturuluyor...');
    _database = await _initDB('shopping.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      print('📁 Veritabanı yolu: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) async {
          print('✅ Veritabanı başarıyla açıldı');
        },
      );
    } catch (e) {
      print('❌ Veritabanı başlatma hatası: $e');
      print('Hata detayı: ${e.toString()}');
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

    print('Veritabanı tablosu oluşturuldu');
  }

  Future<ShoppingListItem> create(ShoppingListItem item) async {
    final db = await instance.database;
    final id = await db.insert('shopping_items', item.toMap());
    return ShoppingListItem(id: id, name: item.name, isBought: item.isBought);
  }

  Future<List<ShoppingListItem>> readAllItems() async {
    try {
      print('📖 Veritabanından okuma başlıyor...');
      final db = await instance.database;
      print('✅ Database instance alındı');

      final orderBy = 'id DESC';
      final result = await db.query('shopping_items', orderBy: orderBy);
      print('✅ ${result.length} ürün bulundu');

      return result.map((json) => ShoppingListItem.fromMap(json)).toList();
    } catch (e) {
      print('❌ readAllItems hatası: $e');
      print('Hata stack trace: ${StackTrace.current}');
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
