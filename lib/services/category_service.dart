// lib/services/category_service.dart

import 'package:test_borsa/services/api_http.dart' as http;
import 'package:test_borsa/services/JwtService/jwt_service.dart';
import 'dart:convert';
import '../models/category_model.dart'; // Category modelini kullanıyoruz.
import 'JwtService/token_service.dart';
import 'base_service.dart';

class CategoryService {
  static String get baseUrl => BaseService.baseUrl;
  static const String endpoint = '/categories';

  // Kategorileri çekme servisi (Uygulama içinde Dropdown vb. için kullanılır)
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
