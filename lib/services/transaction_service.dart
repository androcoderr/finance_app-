// lib/services/transaction_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_borsa/services/api_http.dart' as http;
import '../models/transaction_model.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

class TransactionService {
  static String get baseUrl => BaseService.baseUrl;

  // YARDIMCI METOT: Token ile birlikte standart başlıkları oluşturur.
  Map<String, String> _getAuthHeaders(String accessToken) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $accessToken",
    };
  }

  // Context opsiyonel - eski kodlar çalışmaya devam eder
  Future<bool> addTransaction(
    TransactionModel transaction,
    String accessToken, {
    BuildContext? context,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/users/${transaction.userId}/transactions',
      );

      final response = await http.post(
        url,
        headers: _getAuthHeaders(accessToken),
        body: jsonEncode(transaction.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        if (context != null && context.mounted) {
          ErrorHandler.showErrorSnackBar(context, 'İşlem eklenemedi: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
      return false;
    }
  }

  Future<List<TransactionModel>> getTransactions(
    String userId,
    String accessToken,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/users/$userId/transactions');

      final response = await http.get(
        url,
        headers: _getAuthHeaders(accessToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      }
      throw Exception('İşlemler alınamadı (${response.statusCode})');
    } catch (e) {
      // Hata boş liste olarak dönmez: "hiç işlem yok" ile "yüklenemedi"
      // karışmasın (çevrimdışıyken ₺0 ve "Henüz işlem yok" görünmesin)
      debugPrint('Exception in getTransactions: $e');
      rethrow;
    }
  }

  Future<bool> updateTransaction(
    String userId,
    String transactionId,
    TransactionModel transaction,
    String accessToken,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/users/$userId/transactions/$transactionId',
      );

      final response = await http.put(
        url,
        headers: _getAuthHeaders(accessToken),
        body: jsonEncode(transaction.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Exception in updateTransaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(
    String userId,
    String transactionId,
    String accessToken,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/users/$userId/transactions/$transactionId',
      );

      final response = await http.delete(
        url,
        headers: _getAuthHeaders(accessToken),
      );

      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Exception in deleteTransaction: $e');
      return false;
    }
  }
}
