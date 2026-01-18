// lib/services/recurring_transaction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import 'Exceptions/token_expired_exception.dart'; // Bu dosyanın var olduğunu varsayıyoruz.
import 'BaseService.dart';

class RecurringTransactionService {
  // ANDROID EMULATOR İÇİN
  static String get baseUrl => BaseService.baseUrl;
  static const String endpoint = '/recurring';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  static Future<List<RecurringTransaction>> getRecurringTransactions() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RecurringTransaction.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw TokenExpiredException('Token Expired');
      } else {
        throw Exception(
          'İşlemler yüklenemedi: ${response.statusCode} - ${response.body}',
        );
      }
    } on TokenExpiredException {
      // Hata durumunda login sayfasına yönlendirme
      //Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      throw TokenExpiredException('Token Expired');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<String> createRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      final token = await _getToken();
      final requestBody = {
        'amount': transaction.amount,
        'category_id': transaction.categoryId,
        'description': transaction.description,
        'type': transaction.type,
        'start_date': transaction.startDate.toIso8601String(),
        'end_date': transaction.endDate?.toIso8601String(),
        'frequency': transaction.frequency,
      };

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)['id'];
      } else {
        throw Exception(
          'İşlem oluşturulamadı: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // PUT: İşlem Güncelleme
  static Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      final token = await _getToken();
      final requestBody = {
        'amount': transaction.amount,
        'category_id': transaction.categoryId,
        'description': transaction.description,
        'type': transaction.type,
        'start_date': transaction.startDate.toIso8601String(),
        'end_date': transaction.endDate?.toIso8601String(),
        'frequency': transaction.frequency,
      };

      final url = Uri.parse('$baseUrl$endpoint/${transaction.id}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'İşlem güncellenemedi: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // DELETE: İşlem Silme
  static Future<bool> deleteRecurringTransaction(String transactionId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint/$transactionId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Silme hatası: $e');
    }
  }

  static Future<List<Category>> getCategories() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/categories');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
