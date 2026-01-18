import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill_model.dart';
import 'BaseService.dart';

class BillService {
  // Referans kodunuzdaki gibi Android Emulator için doğru IP adresi
  static String get _baseUrl => BaseService.baseUrl;

  static Future<Map<String, String>> _getHeaders(String token) async {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Kullanıcının faturalarını getirir
  static Future<BillsResponse> getBills(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bills'),
      headers: await _getHeaders(token),
    );

    if (response.statusCode == 200) {
      // UTF-8 decoding eklendi
      final body = utf8.decode(response.bodyBytes);
      return BillsResponse.fromJson(jsonDecode(body));
    } else {
      throw Exception('Faturalar yüklenemedi: ${response.body}');
    }
  }

  // Yeni bir fatura tanımı ekler
  static Future<void> createBill(Bill bill, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bills'),
      headers: await _getHeaders(token),
      body: jsonEncode(bill.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Fatura oluşturulamadı: ${response.body}');
    }
  }

  // Bir faturayı ödendi olarak işaretler
  static Future<void> payBill(
    String billId,
    double paidAmount,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bills/$billId/pay'),
      headers: await _getHeaders(token),
      body: jsonEncode({'paid_amount': paidAmount}),
    );

    if (response.statusCode != 201) {
      throw Exception('Fatura ödemesi başarısız: ${response.body}');
    }
  }

  // Bir fatura tanımını siler
  static Future<void> deleteBill(String billId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/bills/$billId'),
      headers: await _getHeaders(token),
    );

    if (response.statusCode != 204) {
      throw Exception('Fatura silinemedi: ${response.body}');
    }
  }
}
