// Goal Service
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:test_borsa/services/api_http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/FinancialAnalysisResult.dart';
import '../models/goal_model.dart';
import 'Exceptions/token_expired_exception.dart';
import 'BaseService.dart';

class GoalService {
  // ANDROID EMULATOR İÇİN:
  static String get baseUrl => BaseService.baseUrl;

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token') ?? '';

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
      print('🔗 GET Goals URL: $baseUrl/goals');
      print('🔑 Token: ${token.isNotEmpty ? "✓ Var" : "✗ Yok"}');

      final response = await http.get(
        Uri.parse('$baseUrl/goals'), // ⚠️ DEĞİŞTİ: /goals/$userId -> /goals
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
      );

      print('📥 GET Response: ${response.statusCode}');
      print('📥 GET Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Goal.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
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
      print('❌ GET Goals Error: $e');
      throw Exception('Bağlantı hatası: $e');
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

      print('🔗 POST Goals URL: $baseUrl/goals');
      print('📤 POST Body: $requestBody');
      print('🔑 Token: ${token.isNotEmpty ? "✓ Var" : "✗ Yok"}');

      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📥 POST Response: ${response.statusCode}');
      print('📥 POST Body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        // ⚠️ DÜZELTME: Backend 'goal_id' dönüyor, 'id' değil!
        final String goalId = data['goal_id']?.toString() ?? '';

        if (goalId.isEmpty) {
          print('❌ goal_id is empty or null in response');
          throw Exception('Hedef ID alınamadı');
        }

        print('✅ Goal created with ID: $goalId');
        return goalId;
      } else {
        throw Exception(
          'Hedef oluşturulamadı: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ CREATE Goal Error: $e');
      throw Exception('Bağlantı hatası: $e');
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
      };

      print('🔗 PUT Goal URL: $baseUrl/goals/${goal.id}');
      print('📤 PUT Body: $requestBody');

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

      print('📥 PUT Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Hedef güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ UPDATE Goal Error: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<bool> deleteGoal(String goalId) async {
    try {
      final token = await _getToken();

      print('🔗 DELETE Goal URL: $baseUrl/goals/$goalId');

      final response = await http.delete(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
      );

      print('📥 DELETE Response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ DELETE Goal Error: $e');
      throw Exception('Silme hatası: $e');
    }
  }

  static Future<void> updateProgress(String goalId, double newAmount) async {
    try {
      final token = await _getToken();

      print('🔗 UPDATE Progress URL: $baseUrl/goals/$goalId');
      print('📤 UPDATE Progress Body: {"current_amount": $newAmount}');

      final response = await http.put(
        // ⚠️ DEĞİŞTİ: PATCH -> PUT
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ⚠️ EKLENDİ: JWT token
        },
        body: json.encode({'current_amount': newAmount}),
      );

      print('📥 UPDATE Progress Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('İlerleme güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ UPDATE Progress Error: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<FinancialAnalysisResult> getFinanceAnalysis(
    String goalId,
    BuildContext context,
  ) async {
    try {
      final token = await _getToken();

      // STEP 1: POST request - Budget analysis isteği gönder
      final postUrl = Uri.parse('$baseUrl/finance/budget_analysis');

      print('🔗 POST Budget Analysis URL: $postUrl');
      print('🔑 Token: ${token.isNotEmpty ? "✓ Var" : "✗ Yok"}');

      final postResponse = await http.post(
        postUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'goal_id': goalId}),
      );

      print('📥 POST Response: ${postResponse.statusCode}');
      print('📥 POST Body: ${postResponse.body}');

      // Token hatası kontrolü
      if (postResponse.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        throw TokenExpiredException('Token Expired');
      }

      // İstek kabul edilmedi
      if (postResponse.statusCode != 202) {
        final error =
            json.decode(postResponse.body)['error'] ?? postResponse.body;
        throw Exception('Analiz başlatılamadı: $error');
      }

      print('✅ Budget analysis queued successfully');

      // STEP 2: Polling - Sonuç hazır olana kadar bekle
      final getUrl = Uri.parse(
        '$baseUrl/finance/budget_analysis/$goalId/result',
      );

      const maxAttempts = 10; // Maksimum 10 deneme
      const pollInterval = Duration(seconds: 2); // 2 saniyede bir kontrol

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        print('🔄 Attempt $attempt/$maxAttempts - Checking result...');

        // Kısa bekleme
        if (attempt > 1) {
          await Future.delayed(pollInterval);
        }

        final getResponse = await http.get(
          getUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('📥 GET Response: ${getResponse.statusCode}');

        // Token hatası
        if (getResponse.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          throw TokenExpiredException('Token Expired');
        }

        // Sonuç hazır!
        if (getResponse.statusCode == 200) {
          print('✅ Result ready!');
          final data = json.decode(getResponse.body);
          return FinancialAnalysisResult.fromJson(data);
        }

        // Henüz hazır değil (404)
        if (getResponse.statusCode == 404) {
          final errorData = json.decode(getResponse.body);
          print('⏳ Not ready yet: ${errorData['message']}');

          // Son denemede hata fırlat
          if (attempt == maxAttempts) {
            throw Exception(
              'Analiz tamamlanamadı. Lütfen birkaç saniye sonra tekrar deneyin.',
            );
          }
          // Devam et, bir sonraki denemede kontrol et
          continue;
        }

        // Beklenmeyen hata
        final error =
            json.decode(getResponse.body)['error'] ?? getResponse.body;
        throw Exception('Analiz hatası: $error');
      }

      // Maksimum deneme aşıldı
      throw Exception(
        'Analiz zaman aşımına uğradı. Lütfen daha sonra tekrar deneyin.',
      );
    } on TokenExpiredException {
      // Token hatası - Login ekranına yönlendir
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      rethrow;
    } catch (e) {
      print('❌ Analysis Error: $e');
      rethrow;
    }
  }
}
