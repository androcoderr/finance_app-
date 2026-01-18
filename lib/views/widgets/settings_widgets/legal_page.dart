// Yasal Döküman Sayfası
import 'package:flutter/material.dart';

String _getPrivacyPolicy() {
  return '''
GİZLİLİK POLİTİKASI

1. TOPLANAN VERİLER

- Kullanıcı adı ve e-posta adresi
- Finansal işlem verileri
- Uygulama kullanım istatistikleri

2. VERİLERİN KULLANIMI

- Hizmet sunumu
- Uygulama iyileştirme
- Güvenlik sağlama

3. VERİ GÜVENLİĞİ

Verileriniz şifreli olarak saklanır ve üçüncü şahıslarla paylaşılmaz.

4. ÇEREZLER

Uygulama deneyiminizi iyileştirmek için yerel depolama kullanırız.

5. HAKLARINIZ

- Verilerinize erişim
- Verilerin düzeltilmesi
- Verilerin silinmesi

6. İLETİŞİM

Sorularınız için: destek@testborsa.com

Son güncelleme: Ocak 2025
''';
}

String _getTermsOfService() {
  return '''
1. GENEL HÜKÜMLER

Test Borsa uygulamasını kullanarak bu şartları kabul etmiş sayılırsınız.

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

Son güncelleme: Ocak 2025
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
