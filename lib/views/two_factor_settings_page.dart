// lib/views/two_factor_settings_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/BaseService.dart';
import '../view_model/user_view_model.dart';
import '../utils/error_handler.dart';

class TwoFactorSettingsPage extends StatefulWidget {
  const TwoFactorSettingsPage({super.key});

  @override
  State<TwoFactorSettingsPage> createState() => _TwoFactorSettingsPageState();
}

class _TwoFactorSettingsPageState extends State<TwoFactorSettingsPage> {
  bool _isEnabled = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Context hazır olduğunda yüklemeyi başlat
    Future.microtask(() => _loadStatus());
  }

  Future<void> _loadStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.authToken;

      if (token == null) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final response = await http
          .get(
            Uri.parse('${BaseService.baseUrl}/api/2fa/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isEnabled = data['two_factor_enabled'] ?? false;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token geçersiz veya süresi dolmuş
        await userViewModel.logout();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Durum yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle2FA(bool enable) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.authToken;

      if (token == null) {
        throw Exception('Oturum bulunamadı.');
      }

      String? fcmToken;
      if (enable) {
        fcmToken = FirebaseService.instance.fcmToken;
        if (fcmToken == null) {
          fcmToken = await FirebaseService.instance.getFCMToken();
          if (fcmToken == null) {
            throw Exception('Bildirim token\u0027ı alınamadı.');
          }
        }
      }

      final response = await http
          .post(
            Uri.parse(
              enable
                  ? '${BaseService.baseUrl}/api/2fa/enable'
                  : '${BaseService.baseUrl}/api/2fa/disable',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({if (enable) 'fcm_token': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isEnabled = enable;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Değişiklik kaydedildi'), backgroundColor: Colors.green),
        );
      } else if (response.statusCode == 401) {
        await userViewModel.logout();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Oturum süresi dolmuş.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Bir hata oluştu');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İki Aşamalı Doğrulama')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadStatus,
                      icon: Icon(Icons.refresh),
                      label: Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Bilgi Kartı
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'İki Aşamalı Doğrulama Nedir?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hesabınızı ekstra bir güvenlik katmanıyla korur. '
                          'Giriş yapmaya çalıştığınızda telefonunuza bir onay bildirimi gelir.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Durum Kartı
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isEnabled
                                    ? Colors.green[50]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isEnabled
                                    ? Icons.verified_user
                                    : Icons.security,
                                color: _isEnabled ? Colors.green : Colors.grey,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Durum',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _isEnabled ? 'Aktif' : 'Kapalı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isEnabled
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isEnabled,
                              onChanged: (value) {
                                _showConfirmDialog(value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Nasıl Çalışır?
                Text(
                  'NASIL ÇALIŞIR?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),

                _buildStep(
                  number: '1',
                  title: 'Giriş Yapın',
                  description: 'Email ve şifrenizi girin',
                  icon: Icons.login,
                ),
                _buildStep(
                  number: '2',
                  title: 'Bildirim Alın',
                  description: 'Telefonunuza push bildirimi gelir',
                  icon: Icons.notifications_active,
                ),
                _buildStep(
                  number: '3',
                  title: 'Onaylayın',
                  description: 'Bildirimde "Onayla" butonuna tıklayın',
                  icon: Icons.check_circle,
                ),
                _buildStep(
                  number: '4',
                  title: 'Giriş Tamamlandı',
                  description: 'Hesabınıza güvenle erişin',
                  icon: Icons.done_all,
                  isLast: true,
                ),
              ],
            ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(bool enable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          enable
              ? 'İki Aşamalı Doğrulamayı Aktifleştir'
              : 'İki Aşamalı Doğrulamayı Kapat',
        ),
        content: Text(
          enable
              ? 'Hesabınız ekstra güvenlik katmanıyla korunacak. ' 
                    'Her girişte telefonunuza onay bildirimi gelecek.'
              : 'İki aşamalı doğrulama kapatılacak. ' 
                    'Hesabınız daha az güvenli olacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggle2FA(enable);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: enable ? Colors.green : Colors.red,
            ),
            child: Text(enable ? 'Aktifleştir' : 'Kapat'),
          ),
        ],
      ),
    );
  }
}