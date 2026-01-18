// lib/services/transaction_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/transaction_model.dart';
import '../view_model/notification_provider.dart';
import '../utils/error_handler.dart';
import 'BaseService.dart';

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

  // Sadece token GEREKTİRMEYEN (varsa) endpoint'ler için
  Map<String, String> _getHeaders() {
    return {"Content-Type": "application/json", "Accept": "application/json"};
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
      print("---- ADD TRANSACTION REQUEST ----");
      print("URL: $url");
      print("BODY: ${jsonEncode(transaction.toJson())}");
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
      print("---------------------------------");

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        /// ---- BURASI: anomaly varsa bildirim ekle (context olsa da olmasa da) ----
        if (responseData.containsKey('anomaly_check')) {
          final anomalyCheck = responseData['anomaly_check'];
          final bool isAnomaly = anomalyCheck['is_anomaly'] ?? false;
          final String message = anomalyCheck['message'] ?? '';
          final transactionId = responseData['id'];

          try {
            // context yoksa bile provider alabil
            final notifProvider = Provider.of<NotificationProvider>(
              context ?? navigatorKey.currentContext!,
              listen: false,
            );

            print("---- ADD NOTIFICATION TEST ----");
            await notifProvider.addNotification(
              message: message,
              isAnomaly: isAnomaly,
              transactionId: transactionId,
            );
            print("---- ADD NOTIFICATION TEST son ----");

            // Snackbar sadece context varsa
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        isAnomaly ? Icons.warning_amber : Icons.check_circle,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(message)),
                    ],
                  ),
                  backgroundColor: isAnomaly ? Colors.orange : Colors.green,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Görüntüle',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            print("Bildirim eklenirken hata: $e");
          }
        }

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
      } else {
        print('Error fetching transactions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in getTransactions: $e');
      return [];
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
      print('Exception in updateTransaction: $e');
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
      print('Exception in deleteTransaction: $e');
      return false;
    }
  }
}
