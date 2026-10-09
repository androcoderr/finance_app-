// Yasal Döküman Sayfası
import 'package:flutter/material.dart';
import 'package:test_borsa/utils/app_info.dart';
import '../ui/ui.dart';

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
    final c = context.colors;
    // Düz metni okunaklı bloklara çevir: "1. BAŞLIK" → başlık, "- madde" → madde
    final blocks = <Widget>[];
    for (final raw in _content.trim().split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 8));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line) || line == line.toUpperCase()) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.text),
          ),
        ));
      } else if (line.startsWith('- ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: c.textMuted, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(line.substring(2), style: TextStyle(height: 1.5, color: c.text)),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('Son güncelleme')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(line, style: TextStyle(color: c.textFaint, fontSize: 13)),
        ));
      } else {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: TextStyle(height: 1.55, color: c.text)),
        ));
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
        children: blocks,
      ),
    );
  }
}
