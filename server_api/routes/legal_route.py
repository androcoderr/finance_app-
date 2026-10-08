"""Play Console'un istediği herkese açık sayfalar: gizlilik politikası ve hesap silme."""
import os

from flask import Blueprint, render_template_string

legal_bp = Blueprint('legal_bp', __name__)

_PAGE = """<!doctype html>
<html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ title }} · Finans Cepte</title>
<style>
  body{font-family:system-ui,-apple-system,sans-serif;max-width:720px;margin:0 auto;padding:24px 16px;line-height:1.6;color:#1f2933;background:#fff}
  h1{color:#1565c0;font-size:1.6rem} h2{font-size:1.1rem;margin-top:1.6em}
  .muted{color:#616e7c;font-size:.9rem} li{margin:.3em 0}
</style></head><body>{{ body|safe }}
<p class="muted">Son güncelleme: {{ updated }}</p></body></html>"""

_UPDATED = '8 Ekim 2026'


def _email():
    return os.getenv('SUPPORT_EMAIL', 'destek@example.com')


@legal_bp.route('/privacy')
def privacy():
    e = _email()
    body = f"""
<h1>Gizlilik Politikası</h1>
<p>Bu politika, Finans Cepte mobil uygulamasının hangi kişisel verileri topladığını ve nasıl
kullandığını açıklar. 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında veri
sorumlusu uygulamanın geliştiricisidir.</p>

<h2>1. Toplanan veriler</h2>
<ul>
  <li><b>Hesap bilgileri:</b> ad, e-posta adresi ve şifre (şifreler geri döndürülemez şekilde özetlenerek saklanır).</li>
  <li><b>Finansal kayıtlar:</b> sizin girdiğiniz gelir/gider işlemleri, kategoriler, hedefler, faturalar ve tekrarlayan işlemler.</li>
  <li><b>Cihaz bildirim kimliği:</b> iki faktörlü doğrulama ve hatırlatma bildirimleri göndermek için Firebase Cloud Messaging token'ı.</li>
</ul>
<p>Uygulama banka hesaplarınıza bağlanmaz, kart bilgisi istemez, konumunuzu veya rehberinizi okumaz,
reklam ya da reklam kimliği kullanmaz.</p>

<h2>2. Kullanım amacı</h2>
<ul>
  <li>Hesabınızı oluşturmak ve girişinizi doğrulamak,</li>
  <li>Girdiğiniz kayıtları saklayıp size raporlar ve grafikler göstermek,</li>
  <li>Şifre sıfırlama e-postaları ve uygulama bildirimleri göndermek.</li>
</ul>
<p>Verileriniz satılmaz ve reklam amacıyla kullanılmaz.</p>

<h2>3. Hizmet sağlayıcılar</h2>
<ul>
  <li><b>Google Firebase</b> — anlık bildirimlerin iletilmesi.</li>
  <li><b>Sunucu barındırma sağlayıcısı</b> — verilerin saklandığı sunucu.</li>
  <li><b>E-posta sağlayıcısı</b> — şifre sıfırlama e-postaları.</li>
  <li>Döviz ve kripto kurları herkese açık servislerden çekilir; bu isteklerde kişisel veri gönderilmez.</li>
</ul>

<h2>4. Güvenlik ve saklama</h2>
<p>Uygulama ile sunucu arasındaki iletişim HTTPS ile şifrelenir. Verileriniz hesabınız açık olduğu
sürece saklanır; hesabınızı sildiğinizde tüm kayıtlarınız kalıcı olarak silinir.</p>

<h2>5. Haklarınız</h2>
<p>KVKK'nın 11. maddesi uyarınca verilerinize erişme, düzeltilmesini veya silinmesini isteme
haklarına sahipsiniz. Hesabınızı ve tüm verilerinizi uygulama içinden
<b>Ayarlar → Hesabı Sil</b> ile silebilirsiniz. Ayrıntılar: <a href="/delete-account">Hesap silme</a>.</p>

<h2>6. Çocuklar</h2>
<p>Uygulama 13 yaşın altındaki çocuklara yönelik değildir.</p>

<h2>7. İletişim</h2>
<p>Sorularınız için: <a href="mailto:{e}">{e}</a></p>
"""
    return render_template_string(_PAGE, title='Gizlilik Politikası', body=body, updated=_UPDATED)


@legal_bp.route('/delete-account')
def delete_account_info():
    e = _email()
    body = f"""
<h1>Finans Cepte — Hesap ve Veri Silme</h1>
<h2>Uygulama içinden (anında)</h2>
<ol>
  <li>Finans Cepte uygulamasında giriş yapın.</li>
  <li>Sol menüden <b>Ayarlar</b>'a girin.</li>
  <li><b>Hesabı Sil</b>'e dokunup onaylayın.</li>
</ol>
<h2>Uygulamaya erişiminiz yoksa</h2>
<p>Hesabınıza kayıtlı e-posta adresinden <a href="mailto:{e}?subject=Hesap%20silme%20talebi">{e}</a>
adresine "Hesap silme talebi" konulu bir e-posta gönderin. Talebiniz en geç 30 gün içinde işlenir.</p>
<h2>Silinen veriler</h2>
<p>Hesap bilgileriniz (ad, e-posta, şifre), tüm gelir/gider işlemleriniz, hedefleriniz, faturalarınız,
tekrarlayan işlemleriniz ve bildirim kimliğiniz <b>kalıcı olarak</b> silinir. Hiçbir veri saklanmaz.</p>
"""
    return render_template_string(_PAGE, title='Hesap Silme', body=body, updated=_UPDATED)
