// lib/services/category_service.dart

import 'package:http/http.dart' as http;
import 'package:test_borsa/services/JwtService/JwtService.dart';
import 'dart:convert';
import '../models/category_model.dart'; // Category modelini kullanıyoruz.
import 'JwtService/token_service.dart';
import 'BaseService.dart';

class Kategori {
  final String name;
  final bool isIncome;
  Kategori(this.name, this.isIncome);
}

// Uygulamanızın başlangıçta yüklemek istediği statik kategori listesi
final List<Kategori> staticKategoriler = [
  Kategori("Market", false),
  Kategori("Alışveriş", false),
  Kategori("Yiyecek", false),
  Kategori("Telefon", false),
  Kategori("Eğlence", false),
  Kategori("Eğitim", false),
  Kategori("Güzellik", false),
  Kategori("Spor", false),
  Kategori("Sosyal", false),
  Kategori("Ulaşım", false), Kategori("Giyim", false), Kategori("Araba", false),
  Kategori("İçecekler", false),
  Kategori("Sigara", false),
  Kategori("Elektronik", false),
  Kategori("Seyahat", false), Kategori("Sağlık", false), Kategori("Pet", false),
  Kategori("Onarım", false),
  Kategori("Konut", false),
  Kategori("Mobilya", false),
  Kategori("Hediyeler", false),
  Kategori("Bağış", false),
  Kategori("Oyun", false),
  Kategori("Atıştırmalık", false),
  Kategori("Çocuk", false),
  Kategori("Diğer", false),
  Kategori("Maaş", true), Kategori("Prim", true), Kategori("Hediye", true),
  Kategori("Yatırım", true), Kategori("Ek Gelir", true), Kategori("Faiz", true),
  Kategori(
    "Diğer Gelir",
    true,
  ), // İsim çakışmasını önlemek için 'Diğer Gelir' yapıldı
];

class CategoryService {
  static String get baseUrl => BaseService.baseUrl;
  static const String endpoint = '/categories';

  // 1. Kategorileri Toplu Ekleme Servisi (Yalnızca ilk kurulum için kullanılır)
  static Future<void> bulkAddCategories() async {
    print('Kategoriler toplu ekleme işlemi başlıyor...');

    for (var k in staticKategoriler) {
      final url = Uri.parse('$baseUrl$endpoint');

      // ⚠️ Backend'inizde JWT token kontrolü varsa, buraya token eklemeniz gerekir.
      // Basitlik için şu an token olmadan post ediyoruz.

      final response = await http.post(
        url,
        body: jsonEncode({'name': k.name, 'is_income': k.isIncome}),
      );

      if (response.statusCode == 201) {
        print('✅ ${k.name} başarıyla eklendi.');
      } else if (response.statusCode == 409) {
        // 409 Conflict, kategori zaten varsa. Bu normaldir.
        print('ℹ️ ${k.name} zaten mevcut.');
      } else {
        print(
          '❌ Kategori eklenirken hata: ${k.name} -> ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  // 2. Kategorileri Çekme Servisi (Uygulama içinde Dropdown vb. için kullanılır)
  // ⚠️ Token/Authentication mekanizması varsayılarak yazılmıştır.
  static Future<List<Category>> getCategories() async {
    // ⚠️ Bu kısım UserViewModel'inizden token almalıdır.
    // Şimdilik token almayı atlayıp, backend'inizin public endpoint sunduğunu varsayıyoruz.

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(
        url,
        headers: await JwtService.getHeaders(await TokenService.getToken()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategori bağlantı hatası: $e');
    }
  }
}
