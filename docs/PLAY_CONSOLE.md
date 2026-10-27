# Play Console — Hazır Metinler ve Form Cevapları

Kopyala-yapıştır içindir. `<…>` işaretli yerleri doldur. Formlardaki seçenek adları Play Console arayüzü
güncellendikçe biraz değişebilir; anlamca en yakın seçeneği işaretle.

---

## Mağaza girişi

**Uygulama adı** (30 karakter): `Finans Cepte`

**Kısa açıklama** (80 karakter):
```
Gelir, gider, fatura ve hedeflerini tek yerden takip et; harcamalarını gör.
```

**Uzun açıklama** (4000 karakter):
```
Finans Cepte, kişisel bütçeni kolayca takip etmen için tasarlandı. Banka hesabına bağlanmaz,
kart bilgisi istemez: kayıtlarını sen girersin, kontrol sende kalır.

GELİR VE GİDER TAKİBİ
• Gelir ve giderlerini kategorilere ayırarak saniyeler içinde ekle
• Bu ayki toplam gelir, gider ve bakiyeni ana sayfada gör
• Kira, abonelik, maaş gibi tekrarlayan işlemleri bir kez tanımla, her dönem otomatik eklensin

FATURALAR
• Faturalarını ve son ödeme günlerini kaydet
• Yaklaşan ve geciken faturaları tek bakışta gör, ödediğinde işaretle

HEDEFLER
• Tatil, araba, acil durum fonu… birikim hedefleri oluştur
• İlerlemeni takip et, hedefe ulaştığında kutla

RAPORLAR
• Kategori bazlı harcama dağılımı ve grafikler
• Kayıtlarını PDF olarak dışa aktar

DİĞER
• Alışveriş listesi
• Karanlık ve aydınlık tema
<DÖVİZ EKRANI v1'de kalırsa: • Döviz ve kripto kurlarını takip et>

GİZLİLİK
• Verilerin satılmaz, reklam yok
• Hesabını ve tüm verilerini uygulama içinden tek dokunuşla silebilirsin
• Uygulama ile sunucu arasındaki iletişim şifrelidir

Sorun ve önerilerin için: <destek e-postası>
```

**Kategori:** Finans
**Etiketler (varsa):** Bütçe, Harcama takibi, Kişisel finans
**İletişim e-postası:** `<destek gmail>` (herkese açık görünür)
**Gizlilik politikası URL'si:** `https://api.<ALANADI>/privacy`

**Grafikler** — hazır: `docs/store-images/`
- Uygulama simgesi: `ikon_512.png` (512×512, 32-bit PNG)
- Tanıtım görseli: `tanitim_1024x500.png`
- Telefon ekran görüntüleri: `ekran_1.png` … `ekran_5.png` (1080×1920, sırasıyla yükle). Örnek "Deneme"
  hesabıyla çekildi, kişisel veri içermez.

---

## Uygulama içeriği

### Gizlilik politikası
`https://api.<ALANADI>/privacy`

### Uygulama erişimi ⚠️
Uygulama giriş gerektirdiği için Google incelemecileri bir hesap ister; verilmezse uygulama **reddedilebilir**.
- Seçim: "Uygulamanın tamamı veya bir kısmı kısıtlanmış"
- Talimat adı: `Test hesabı`
- Kullanıcı adı: `<inceleme için açtığın e-posta>`  Şifre: `<şifre>`
- Ek bilgi: `Hesap e-posta doğrulaması tamamlanmış durumda; doğrudan giriş yapılabilir.`

Bu hesabı canlı sunucuda **önceden kendin oluşturup doğrula** (kodu gelen e-postayla) ve içine birkaç örnek
işlem/fatura/hedef ekle. Şifresini değiştirme, silme.

### Reklamlar
"Hayır, uygulamamda reklam yok."

### İçerik derecelendirmesi (IARC anketi)
- Kategori: "Diğer" / yardımcı program-üretkenlik (oyun değil, sosyal değil)
- Şiddet, cinsellik, küfür, uyuşturucu, kumar: **Hayır**
- Kullanıcılar birbiriyle iletişim kurabiliyor mu / içerik paylaşabiliyor mu: **Hayır**
- Konum paylaşımı: **Hayır**
- Dijital ürün satın alma: **Hayır**
- Beklenen sonuç: 3+ / Herkes

### Hedef kitle
- Yaş grubu: **18 ve üzeri** (finans uygulaması; çocuklara yönelik değil — "Aileler" politikalarına girmez)
- Çocukların ilgisini çekebilir mi: Hayır

### Haber uygulaması: Hayır  ·  COVID-19 uygulaması: Hayır  ·  Devlet uygulaması: Hayır

### Finansal özellikler ⚠️ (finans uygulamaları için zorunlu beyan)
Uygulama: kişisel bütçe/harcama takibi; kullanıcı verilerini kendisi girer.
- Banka hesabı, ödeme, para transferi, kredi, borç verme, yatırım/aracı kurum, kripto alım-satım,
  sigorta: **hiçbiri yok**
- Listede "kişisel bütçe / finans yönetimi" benzeri bir seçenek varsa onu, yoksa "Uygulamam bu finansal
  özelliklerden hiçbirini sunmuyor" seçeneğini işaretle.
- <Döviz ekranı kalırsa:> kurlar yalnızca **bilgi amaçlı** gösterilir; alım-satım yapılmaz.

### Hesap silme ⚠️
- Uygulama içinden hesap oluşturulabiliyor mu: **Evet**
- Hesap silme URL'si: `https://api.<ALANADI>/delete-account`
- Uygulama içinden silme: Ayarlar → Hesabı Sil (tüm veriler kalıcı silinir)

### Veri güvenliği ⚠️

**Genel sorular**
- Uygulama kullanıcı verisi topluyor veya paylaşıyor mu: **Evet**
- Toplanan tüm veriler aktarım sırasında şifreleniyor mu: **Evet** (HTTPS)
- Kullanıcılar verilerinin silinmesini isteyebilir mi: **Evet** (uygulama içi + URL)

**Toplanan veri türleri** (hepsi: *Toplanır = Evet*, *Paylaşılır = Hayır*, *Geçici işlenir = Hayır*,
*Zorunlu* — kullanıcı seçemez)

| Kategori → Tür | Amaç |
|---|---|
| Kişisel bilgiler → **Ad** | Uygulama işlevselliği, Hesap yönetimi |
| Kişisel bilgiler → **E-posta adresi** | Uygulama işlevselliği, Hesap yönetimi |
| Finansal bilgiler → **Diğer finansal bilgiler** (kullanıcının girdiği gelir/gider, fatura, hedef kayıtları) | Uygulama işlevselliği |
| Cihaz veya diğer kimlikler → **Cihaz veya diğer kimlikler** (Firebase/Crashlytics kurulum kimliği) | Uygulama işlevselliği, Analiz |
| Uygulama bilgileri ve performansı → **Kilitlenme günlükleri** (Crashlytics) | Analiz |
| Uygulama bilgileri ve performansı → **Tanılama** (cihaz modeli, OS sürümü, hata bağlamı) | Analiz |

Toplanmayanlar: konum, kişiler, fotoğraf/video, ses, dosyalar, takvim, SMS, web geçmişi, sağlık,
uygulama etkinliği, reklam kimliği, ödeme/kart bilgisi, kredi puanı.

Kilitlenme raporlarına kullanıcı kimliği, ad, e-posta veya finansal veri eklenmez (kodda ayarlandı).

"Paylaşılır = Hayır" çünkü veriler yalnızca bizim adımıza çalışan hizmet sağlayıcılara (sunucu, e-posta,
Firebase) gidiyor; Google bunu "paylaşım" saymaz.

> Sentry (sunucu tarafı) açıksa: sunucu hata kayıtlarına kişisel veri gönderilmiyor (ayarlandı), ek beyan gerekmez.

---

## Sürüm notları (ilk sürüm)
```
<tr-TR>
Finans Cepte'nin ilk sürümü: gelir-gider, faturalar, hedefler, tekrarlayan işlemler ve raporlar.
</tr-TR>
```
