import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:test_borsa/services/api_http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/login_screen.dart';
import '../services/BaseService.dart';
import 'user_view_model.dart';

String get baseUrl => BaseService.baseUrl;

//-------------------------------------------------
Future<String> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null || token.isEmpty) {
    throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
  }
  return token;
}

void showDeleteAccountDialog(BuildContext context) {
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Hesabı Sil'),
            content: const Text(
              'Bu işlem geri alınamaz! Tüm verileriniz kalıcı olarak silinecektir. '
              'Devam etmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.shade200,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final String authToken = await _getToken();
                          final String apiUrl = '$baseUrl/users/profile';

                          final response = await http
                              .delete(
                                Uri.parse(apiUrl),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $authToken',
                                },
                              )
                              .timeout(const Duration(seconds: 15));

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (response.statusCode == 200) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hesabınız başarıyla silindi.'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Kayıtlı token'ları temizle; yoksa sonraki açılışta silinen hesapla giriş denenir
                            if (!context.mounted) return;
                            await Provider.of<UserViewModel>(
                              context,
                              listen: false,
                            ).logout();

                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            final responseBody = json.decode(response.body);
                            final String errorMessage =
                                responseBody['error'] ??
                                'Bilinmeyen bir sunucu hatası.';
                            throw Exception(errorMessage);
                          }
                        } catch (e) {
                          if (!ctx.mounted) return;
                          if (Navigator.canPop(ctx)) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                          }

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bir hata oluştu: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        if (context.mounted && isLoading) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Hesabı Sil'),
              ),
            ],
          );
        },
      );
    },
  );
}
//---------------------------

