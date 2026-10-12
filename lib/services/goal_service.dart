// Goal Service
import '../utils/error_handler.dart';
import 'dart:convert';
import 'package:test_borsa/services/token_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:test_borsa/services/api_http.dart' as http;
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import 'Exceptions/token_expired_exception.dart';
import 'base_service.dart';

class GoalService {
  // ANDROID EMULATOR İÇİN:
  static String get baseUrl => BaseService.baseUrl;

  static Future<String> _getToken() async {

    final token = await TokenStorage.access() ?? '';

    if (token.isEmpty) {
      throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
    }

    return token;
  }

  static Future<List<Goal>> getGoals(
    String userId,
    BuildContext context,
  ) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/goals'), // ⚠️ DEĞİŞTİ: /goals/$userId -> /goals
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
      );


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Goal.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await TokenStorage.clearAccess();
        throw TokenExpiredException('Token Expired');
      } else {
        throw Exception(
          'Hedefler yüklenemedi: ${response.statusCode} - ${response.body}',
        );
      }
    } on TokenExpiredException {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      throw TokenExpiredException('Token Expired');
    } catch (e) {
      debugPrint('❌ GET Goals Error: $e');
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<String> createGoal(Goal goal, DateTime? goalDate) async {
    try {
      final token = await _getToken();

      final Map<String, dynamic> requestBody = {
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        // Hedef tarihi isteğe bağlı
        if (goalDate != null)
          'goal_date': DateFormat('dd-MM-yyyy').format(goalDate),
      };


      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );


      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        // ⚠️ DÜZELTME: Backend 'goal_id' dönüyor, 'id' değil!
        final String goalId = data['goal_id']?.toString() ?? '';

        if (goalId.isEmpty) {
          throw Exception('Hedef ID alınamadı');
        }

        return goalId;
      } else {
        throw Exception(
          'Hedef oluşturulamadı: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ CREATE Goal Error: $e');
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<void> updateGoal(Goal goal) async {
    try {
      final token = await _getToken();

      // ⚠️ BACKEND FORMATINA UYGUN BODY
      final Map<String, dynamic> requestBody = {
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        // Son tarih değiştiyse sunucu goal_dates kaydını günceller
        if (goal.targetDate != null)
          'goal_date': DateFormat('dd-MM-yyyy').format(goal.targetDate!),
      };


      final response = await http.put(
        Uri.parse('$baseUrl/goals/${goal.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
        body: json.encode(
          requestBody,
        ), // ⚠️ DEĞİŞTİ: goal.toJson() -> requestBody
      );


      if (response.statusCode != 200) {
        throw Exception('Hedef güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ UPDATE Goal Error: $e');
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  static Future<bool> deleteGoal(String goalId) async {
    try {
      final token = await _getToken();


      final response = await http.delete(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
      );


      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ DELETE Goal Error: $e');
      throw Exception('Silme hatası: $e');
    }
  }

  static Future<void> updateProgress(String goalId, double newAmount) async {
    try {
      final token = await _getToken();


      final response = await http.put(
        // ⚠️ DEĞİŞTİ: PATCH -> PUT
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
        body: json.encode({'current_amount': newAmount}),
      );


      if (response.statusCode != 200) {
        throw Exception('İlerleme güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ UPDATE Progress Error: $e');
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

}
