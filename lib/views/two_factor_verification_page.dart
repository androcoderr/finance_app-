// lib/views/two_factor_verification_page.dart

import 'dart:async'; // Timer için
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../view_model/user_view_model.dart';
import '../services/BaseService.dart';

class TwoFactorVerificationPage extends StatefulWidget {
  final String sessionToken; // Login sayfasından gelen token

  const TwoFactorVerificationPage({super.key, required this.sessionToken});

  @override
  _TwoFactorVerificationPageState createState() =>
      _TwoFactorVerificationPageState();
}

class _TwoFactorVerificationPageState extends State<TwoFactorVerificationPage> {
  Timer? _pollingTimer;
  String _statusMessage = 'Onay bekleniyor...';
  bool _isLoading = true;
  final bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _startPolling(); // Sayfa açılınca backend'i dinlemeye başla
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Sayfa kapanınca zamanlayıcıyı durdur
    super.dispose();
  }

  // Backend'i düzenli aralıklarla kontrol eden fonksiyon
  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!mounted || _isApproved) {
        timer.cancel();
        return;
      }
      await _checkStatus();
    });
    // İlk kontrolü hemen yap
    _checkStatus();
  }

  // Backend'den session durumunu kontrol et
  Future<void> _checkStatus() async {
    // isLoading'i tekrar true yapmaya gerek yok, sadece arkaplanda çalışacak
    print('⏳ Durum kontrol ediliyor... Token: ${widget.sessionToken}');
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseService.baseUrl}/api/2fa/check-status/${widget.sessionToken}',
        ),
      );

      if (!mounted) return;

      print('📊 Sunucu Cevabı (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        print('ℹ️ Alınan Durum: $status');

        if (status == 'approved') {
          // 🟢 ONAYLANDI BLOĞU - YENİ VE DOĞRU MANTIK 🟢
          print('🟢🟢🟢 DURUM ONAYLANDI! Giriş tamamlanıyor... 🟢🟢🟢');
          _pollingTimer?.cancel(); // Zamanlayıcıyı hemen durdur

          // 1. Sunucudan gelen yeni access_token'ı ve kullanıcı verisini al
          final String? accessToken = data['access_token'];
          final Map<String, dynamic>? userData = data['user'];

          if (accessToken != null && userData != null) {
            // 2. UserViewModel'i çağırarak giriş işlemini tamamla ve state'i güncelle
            // Bu, tüm uygulamaya "Artık giriş yapıldı!" haberini verir.
            final userViewModel = Provider.of<UserViewModel>(
              context,
              listen: false,
            );
            final user = User.fromJson(userData);

            // ViewModel'deki yeni metodu çağırarak token'ı kaydet ve isLoggedIn'i true yap
            await userViewModel.complete2faLogin(user, accessToken, null);

            // 3. ViewModel güncellendikten sonra GÜVENLE ana sayfaya yönlendir
            print('Navigating to /home...');
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Bu bir hata durumudur. Onaylanmış ama token gelmemiş.
            print(
              '❌ HATA: Onaylandı ama sunucudan token veya kullanıcı verisi gelmedi!',
            );
            setState(() {
              _statusMessage = 'Giriş tamamlanamadı. Lütfen tekrar deneyin.';
              _isLoading = false;
            });
            await Future.delayed(Duration(seconds: 2));
            Navigator.pop(context); // Login'e geri dön
          }
        } else if (status == 'rejected' || status == 'expired') {
          // 🔴 REDDEDİLDİ VEYA SÜRE DOLDU BLOĞU 🔴
          print(
            '🔴🔴🔴 DURUM: $status! Login sayfasına geri dönülecek... 🔴🔴🔴',
          );
          setState(() {
            _statusMessage = status == 'rejected'
                ? 'Giriş reddedildi.'
                : 'Oturum süresi doldu.';
            _isLoading = false;
          });
          _pollingTimer?.cancel();
          await Future.delayed(Duration(seconds: 2));
          print('Navigating back (Pop)...');
          Navigator.pop(context); // Bu sayfayı kapatıp login'e dön
        } else {
          // 🟡 BEKLEME DEVAM EDİYOR BLOĞU 🟡
          print('🟡🟡🟡 Durum hala "pending". Beklemeye devam... 🟡🟡🟡');
          setState(() {
            _statusMessage = 'Onay bekleniyor...';
            _isLoading = false; // Sadece ilk yükleme için
          });
        }
      } else {
        // ❌ SUNUCU HATASI BLOĞU ❌
        print('❌❌❌ Sunucudan Hata (${response.statusCode}) Alındı! ❌❌❌');
        setState(() {
          _statusMessage =
              'Durum kontrol edilemedi (Hata: ${response.statusCode})';
          _isLoading = false;
        });
        _pollingTimer?.cancel();
      }
    } catch (e) {
      // ❌ BAĞLANTI HATASI BLOĞU ❌
      print('❌❌❌ Bağlantı Hatası: $e ❌❌❌');
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Bağlantı hatası!';
        _isLoading = false;
      });
      _pollingTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İki Aşamalı Doğrulama'),
        automaticallyImplyLeading: false, // Geri tuşunu gizle
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading ||
                  _isApproved) // Yükleniyorsa veya onaylandıysa animasyon göster
                CircularProgressIndicator()
              else if (_statusMessage.contains('reddedildi') ||
                  _statusMessage.contains('süresi doldu'))
                Icon(Icons.error_outline, color: Colors.red, size: 60)
              else // Onay bekliyorsa telefon ikonu
                Icon(
                  Icons.phonelink_ring,
                  color: Theme.of(context).primaryColor,
                  size: 60,
                ),
              SizedBox(height: 24),
              Text(
                'Onay Bekleniyor',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                _isApproved
                    ? _statusMessage
                    : 'Lütfen telefonunuza gönderilen bildirimi onaylayın.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              // Durum mesajını (opsiyonel) göster
              if (!_isLoading && !_isApproved)
                Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
