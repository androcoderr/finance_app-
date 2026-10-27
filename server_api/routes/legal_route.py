"""Play Console'un istediği herkese açık sayfalar: gizlilik politikası ve hesap silme."""
import os

from flask import Blueprint, render_template_string
from markupsafe import escape

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

_UPDATED = '9 Ekim 2026'


def _email():
    return os.getenv('SUPPORT_EMAIL', 'destek@example.com')


def _controller():
    """KVKK: veri sorumlusunun adı (gerçek kişi geliştirici). DATA_CONTROLLER_NAME ile verilir."""
    return os.getenv('DATA_CONTROLLER_NAME', '').strip() or 'uygulamanın geliştiricisi'


def _hosting_location():
    """Sunucunun bulunduğu ülke/bölge, ör. 'Almanya (Frankfurt)'. HOSTING_LOCATION ile verilir."""
    return os.getenv('HOSTING_LOCATION', '').strip()


@legal_bp.route('/privacy')
def privacy():
    e = escape(_email())
    controller = escape(_controller())
    location = escape(_hosting_location())
    if location:
        storage = (f"<p>Verileriniz <b>{location}</b> konumundaki sunucularda saklanır. Bu, KVKK'nın 9. maddesi "
                   "kapsamında yurt dışına veri aktarımıdır ve hizmetin sunulabilmesi (sözleşmenin ifası) için "
                   "gereklidir.</p>")
    else:
        storage = "<p>Verileriniz barındırma sağlayıcısının sunucularında saklanır.</p>"
    body = f"""
<h1>Gizlilik Politikası ve Aydınlatma Metni</h1>
<p>Bu metin, Finans Cepte mobil uygulamasının hangi kişisel verileri hangi amaçla işlediğini 6698 sayılı
Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında açıklar. Veri sorumlusu: <b>{controller}</b>
(iletişim: <a href="mailto:{e}">{e}</a>).</p>

<h2>1. İşlenen veriler</h2>
<ul>
  <li><b>Hesap bilgileri:</b> ad, e-posta adresi ve şifre (şifreler geri döndürülemez şekilde özetlenerek saklanır).</li>
  <li><b>E-posta doğrulama:</b> kayıt sırasında e-postanıza gönderilen tek kullanımlık kod (yalnızca özeti, 15 dakika süreyle saklanır).</li>
  <li><b>Finansal kayıtlar:</b> sizin girdiğiniz gelir/gider işlemleri, kategoriler, hedefler, faturalar ve tekrarlayan işlemler.</li>
  <li><b>Teknik kayıtlar:</b> güvenlik ve kötüye kullanımı önleme (ör. çok sayıda hatalı giriş denemesini sınırlama) için
      IP adresi ve istek bilgileri sunucu kayıtlarında kısa süreli tutulabilir.</li>
  <li><b>Kilitlenme raporları:</b> uygulama çökerse hatayı düzeltebilmemiz için hata kaydı, cihaz modeli, işletim sistemi
      sürümü ve rastgele bir kurulum kimliği gönderilir. Bu raporlara adınız, e-postanız veya finansal kayıtlarınız eklenmez.</li>
</ul>
<p><b>Fatura hatırlatmaları:</b> açarsanız bildirimler yalnızca cihazınızda yerel olarak planlanır; bunun için
sunucuya ek bir veri gönderilmez. İstediğiniz zaman Ayarlar → Bildirimler'den kapatabilirsiniz.</p>
<p>Uygulama banka hesaplarınıza bağlanmaz, kart bilgisi istemez, konumunuzu, rehberinizi, kameranızı veya
mikrofonunuzu kullanmaz, reklam ya da reklam kimliği kullanmaz.</p>

<h2>2. Amaç ve hukuki sebep</h2>
<ul>
  <li>Hesabınızı oluşturmak, e-posta adresinizi doğrulamak ve girişinizi sağlamak,</li>
  <li>Girdiğiniz kayıtları saklayıp size raporlar ve grafikler göstermek,</li>
  <li>Şifre sıfırlama ve doğrulama e-postaları göndermek,</li>
  <li>Hizmetin güvenliğini sağlamak ve hataları gidermek.</li>
</ul>
<p>Bu veriler, KVKK md. 5/2-c (bir sözleşmenin kurulması veya ifası için gerekli olması) ve md. 5/2-f
(veri sorumlusunun meşru menfaati: hizmet güvenliği) hukuki sebeplerine dayanılarak işlenir.
Verileriniz satılmaz ve reklam amacıyla kullanılmaz.</p>

<h2>3. Aktarılan taraflar</h2>
<ul>
  <li><b>Sunucu barındırma sağlayıcısı</b> — verilerin saklandığı sunucu.</li>
  <li><b>E-posta sağlayıcısı</b> — doğrulama ve şifre sıfırlama e-postaları.</li>
  <li><b>Google Firebase (Crashlytics)</b> — uygulama altyapısı ve kilitlenme raporları. Bu raporlar Google'ın
      yurt dışındaki sunucularında işlenir (KVKK md. 9 kapsamında yurt dışına aktarım; hizmetin güvenli ve hatasız
      sunulması amacıyla).</li>
  <li><b>Döviz ve kripto kurları:</b> Döviz ekranı kurları herkese açık servislerden doğrudan cihazınızdan çeker.
      Bu isteklerde hesap veya finansal bilginiz gönderilmez; ancak her internet isteğinde olduğu gibi IP adresiniz
      bu servislerce görülebilir.</li>
</ul>
{storage}

<h2>4. Güvenlik ve saklama süresi</h2>
<p>Uygulama ile sunucu arasındaki iletişim HTTPS ile şifrelenir; oturum anahtarları cihazınızda şifreli depoda tutulur.
Verileriniz hesabınız açık olduğu sürece saklanır; hesabınızı sildiğinizde tüm kayıtlarınız kalıcı olarak silinir.
7 gün içinde doğrulanmayan kayıtlar otomatik olarak silinir.</p>

<h2>5. Haklarınız</h2>
<p>KVKK'nın 11. maddesi uyarınca verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, düzeltilmesini veya
silinmesini isteme, aktarıldığı tarafları öğrenme ve itiraz etme haklarına sahipsiniz. Hesabınızı ve tüm verilerinizi
uygulama içinden <b>Ayarlar → Hesabı Sil</b> ile silebilirsiniz. Ayrıntılar: <a href="/delete-account">Hesap silme</a>.
Diğer talepleriniz için <a href="mailto:{e}">{e}</a> adresine yazabilirsiniz; talepler en geç 30 gün içinde yanıtlanır.</p>

<h2>6. Çocuklar</h2>
<p>Uygulama 13 yaşın altındaki çocuklara yönelik değildir.</p>
"""
    return render_template_string(_PAGE, title='Gizlilik Politikası', body=body, updated=_UPDATED)


@legal_bp.route('/delete-account')
def delete_account_info():
    e = escape(_email())
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
tekrarlayan işlemleriniz <b>kalıcı olarak</b> silinir. Hiçbir veri saklanmaz.</p>
"""
    return render_template_string(_PAGE, title='Hesap Silme', body=body, updated=_UPDATED)


@legal_bp.route('/support')
def support():
    """App Store'un zorunlu "Destek URL'si" (Play'de iletişim e-postası yeterli)."""
    e = escape(_email())
    body = f"""
<h1>Finans Cepte — Destek</h1>
<p>Soru, sorun ve önerileriniz için bize e-posta gönderin: <a href="mailto:{e}">{e}</a>.
Genellikle birkaç iş günü içinde yanıtlıyoruz.</p>
<h2>Sık sorulanlar</h2>
<p><b>Doğrulama kodu gelmedi.</b> Gereksiz (spam) klasörünü kontrol edin; uygulamadaki "Kodu tekrar gönder" ile
60 saniyede bir yeni kod isteyebilirsiniz.</p>
<p><b>Şifremi unuttum.</b> Giriş ekranındaki "Şifremi unuttum" ile e-postanıza sıfırlama bağlantısı gönderilir.</p>
<p><b>Uygulama "Güncelleme gerekli" diyor.</b> Uygulamayı mağazadan güncelleyin; eski sürümler güvenlik ve
uyumluluk için kapatılabilir.</p>
<p><b>Hesabımı silmek istiyorum.</b> Ayarlar → Hesabı Sil. Ayrıntılar: <a href="/delete-account">Hesap silme</a>.</p>
<p><a href="/privacy">Gizlilik Politikası</a></p>
"""
    return render_template_string(_PAGE, title='Destek', body=body, updated=_UPDATED)
