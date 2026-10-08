// Yasal Döküman Sayfası
import 'package:flutter/material.dart';
import 'package:test_borsa/utils/app_info.dart';

String _getPrivacyPolicy() {
  return '''
GİZLİLİK POLİTİKASI

1. TOPLANAN VERİLER

- Hesap bilgileri: ad, e-posta ve şifre (şifreler geri döndürülemez şekilde özetlenerek saklanır)
- Sizin girdiğiniz gelir/gider işlemleri, hedefler, faturalar ve tekrarlayan işlemler
- Bildirim göndermek için cihaz bildirim kimliği (Firebase Cloud Messaging)

Uygulama banka hesaplarınıza bağlanmaz, kart bilgisi istemez, konum veya rehber okumaz, reklam kullanmaz.

2. VERİLERİN KULLANIMI

- Hesabınızı oluşturmak ve girişinizi doğrulamak
- Kayıtlarınızı saklayıp rapor ve grafik göstermek
- Şifre sıfırlama e-postaları ve bildirim göndermek

Verileriniz satılmaz ve reklam amacıyla kullanılmaz.

3. HİZMET SAĞLAYICILAR

- Google Firebase (bildirimler)
- Sunucu barındırma ve e-posta sağlayıcıları
- Döviz/kripto kurları herkese açık servislerden çekilir; bu isteklerde kişisel veri gönderilmez.

4. GÜVENLİK VE SAKLAMA

Uygulama ile sunucu arasındaki iletişim HTTPS ile şifrelenir. Verileriniz hesabınız açık olduğu sürece saklanır.

5. HAKLARINIZ (KVKK md. 11)

Verilerinize erişme, düzeltilmesini ve silinmesini isteme hakkınız vardır. Hesabınızı ve tüm verilerinizi Ayarlar > Hesabı Sil ile kalıcı olarak silebilirsiniz.

6. İLETİŞİM

Sorularınız için: $kSupportEmail

Son güncelleme: 8 Ekim 2026
''';
}

String _getTermsOfService() {
  return '''
1. GENEL HÜKÜMLER

Finans Cepte uygulamasını kullanarak bu şartları kabul etmiş sayılırsınız.

2. KULLANIM KOŞULLARI

- Uygulama yalnızca kişisel kullanım içindir
- Ticari amaçla kullanılamaz
- Hesap bilgilerinizi korumakla yükümlüsünüz

3. GİZLİLİK

Verileriniz gizlilik politikamıza uygun olarak işlenir.

4. SORUMLULUK

Uygulama "olduğu gibi" sunulmaktadır. Veri kaybından sorumlu değiliz.

5. DEĞİŞİKLİKLER

Bu koşulları değiştirme hakkımız saklıdır.

Son güncelleme: 8 Ekim 2026
''';
}

class LegalPage extends StatelessWidget {
  final String title;

  const LegalPage({super.key, required this.title});

  String get _content {
    switch (title) {
      case 'Kullanım Koşulları':
        return _getTermsOfService();
      case 'Gizlilik Politikası':
        return _getPrivacyPolicy();
      default:
        return 'İçerik bulunamadı.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(_content, style: TextStyle(height: 1.6, fontSize: 16)),
      ),
    );
  }
}
