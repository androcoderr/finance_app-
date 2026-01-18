// lib/views/shopping_list_page.dart

import 'package:flutter/material.dart';
import '../models/shopping_list_item.dart';
import '../services/database_helper.dart'; // DatabaseHelper'ı import et

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingListItem> _items = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Sayfa açıldığında veritabanından ürünleri yükle
  }

  // Veritabanından listeyi çekip arayüzü güncelleyen metot
  // _refreshItems metodunun YENİ ve GÜVENLİ hali
  Future<void> _refreshItems() async {
    setState(() => _isLoading = true);
    try {
      // Veritabanından veriyi okumayı dene
      final data = await DatabaseHelper.instance.readAllItems();
      setState(() {
        _items = data;
      });
    } catch (e) {
      // Bir hata olursa, kullanıcıya bilgi ver ve hatayı konsola yazdır
      print(
        'Hata oluştu: $e',
      ); // Hatanın ne olduğunu görmek için bu çok önemli!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veriler yüklenirken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // İşlem başarılı da olsa, hata da olsa BU BLOK HER ZAMAN ÇALIŞIR.
      // Bu sayede yükleme animasyonunda takılı kalmazsın.
      if (mounted) {
        // Widget'ın hala ekranda olduğundan emin ol
        setState(() => _isLoading = false);
      }
    }
  }

  // --- CRUD Fonksiyonları ---

  Future<void> _addItem(String name) async {
    if (name.isNotEmpty) {
      await DatabaseHelper.instance.create(ShoppingListItem(name: name));
      _controller.clear();
      Navigator.of(context).pop(); // Dialog'u kapat
      _refreshItems(); // Listeyi yenile
    }
  }

  Future<void> _toggleItemStatus(ShoppingListItem item) async {
    item.isBought = !item.isBought;
    await DatabaseHelper.instance.update(item);
    _refreshItems(); // Listeyi yenile
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.delete(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ürün silindi!')));
    _refreshItems(); // Listeyi yenile
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ürün Ekle'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'örn: Ekmek'),
          onSubmitted: (value) => _addItem(value),
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              _controller.clear();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Ekle'),
            onPressed: () => _addItem(_controller.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alışveriş Listesi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text(
                'Listeniz boş.\nEklemek için + butonuna dokunun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.isBought,
                    onChanged: (value) => _toggleItemStatus(item),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isBought
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isBought ? Colors.grey : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade300,
                    ),
                    onPressed: () => _deleteItem(item.id!),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Yeni Ürün Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
