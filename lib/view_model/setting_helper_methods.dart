import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../views/login_screen.dart';
import '../services/BaseService.dart';

String get baseUrl => BaseService.baseUrl;

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

void showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('İletişim'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.email),
            title: Text('E-posta'),
            subtitle: Text('destek@testborsa.com'),
            onTap: () => _launchURL('mailto:destek@testborsa.com'),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Telefon'),
            subtitle: Text('+90 (555) 123 45 67'),
            onTap: () => _launchURL('tel:+905551234567'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Web Sitesi'),
            subtitle: Text('www.testborsa.com'),
            onTap: () => _launchURL('https://www.testborsa.com'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Kapat'),
        ),
      ],
    ),
  );
}

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

                          Navigator.pop(ctx);

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hesabınız başarıyla silindi.'),
                                backgroundColor: Colors.green,
                              ),
                            );

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
                          if (Navigator.canPop(ctx)) {
                            Navigator.pop(ctx);
                          }

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

void showFeedbackDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Geri Bildirim'),
      content: TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Düşüncelerinizi bizimle paylaşın...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Geri bildiriminiz için teşekkürler!')),
            );
          },
          child: Text('Gönder'),
        ),
      ],
    ),
  );
}
