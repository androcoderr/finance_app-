# App Store Connect — Hazır Metinler ve Form Cevapları

Play tarafı için `PLAY_CONSOLE.md`'ye bakın; buradaki veri beyanları onunla **aynı veriyi** anlatır.
`<…>` işaretli yerleri doldurun. Apple arayüzündeki seçenek adları zamanla değişebilir; anlamca en yakınını seçin.

---

## Önce bilinmesi gerekenler

- **Bireysel geliştirici hesabında satıcı adı olarak gerçek adınız** App Store'da herkese görünür.
  (Şirket hesabı D-U-N-S numarası ister; v1 için gerekmez.)
- Uygulama **yalnızca iPhone** için yayınlanacak (iPad ekran görüntüsü istenmesin diye; Xcode'da cihaz ailesi: iPhone).
- Kişisel bütçe takibi bireysel hesapla yayınlanabilir; Apple'ın kurum hesabı şartı bankacılık, kredi, kripto
  alım-satımı gibi uygulamalar içindir — bizde bunların hiçbiri yok.
- Play'deki 14 günlük test şartı Apple'da **yok**. TestFlight: dahili test (App Store Connect kullanıcıları,
  incelemesiz) veya harici test (e-posta/bağlantı ile 10.000 kişiye kadar, ilk sürüm kısa bir beta incelemesinden geçer).

---

## Uygulama bilgileri

| Alan | Değer |
|---|---|
| Ad (30) | `Finans Cepte` |
| Alt başlık (30) | `Gelir, gider ve bütçe takibi` |
| Birincil dil | Türkçe |
| Paket kimliği (Bundle ID) | `com.finanscepte.app` |
| SKU | `finanscepte-ios-1` (yalnızca size görünür) |
| Kategori | Finans (ikincil: Verimlilik) |
| Fiyat | Ücretsiz |
| Gizlilik Politikası URL'si | `https://api.<ALANADI>/privacy` |
| Destek URL'si (zorunlu) | `https://api.<ALANADI>/support` |
| Pazarlama URL'si | boş bırakılabilir |
| Telif hakkı | `2026 <Adınız Soyadınız>` |

**Tanıtım metni (170)** — inceleme gerektirmeden değiştirilebilir:
```
Gelirini, giderini, faturalarını ve hedeflerini tek yerden takip et. Banka bağlantısı yok, reklam yok.
```

**Açıklama (4000):** `PLAY_CONSOLE.md` → "Uzun açıklama" metnini aynen kullanın.

**Anahtar kelimeler (100, virgülle, boşluksuz):**
```
bütçe,harcama,gider,gelir,fatura,birikim,hedef,para,cüzdan,finans,masraf,takip,tasarruf
```

**Ekran görüntüleri:** 6.9" iPhone (1320×2868 veya 1290×2796), en az 1, önerilen 4–5. Android görselleri
oran farkı nedeniyle doğrudan kullanılamaz; iOS simülatöründen (iPhone 16/17 Pro Max) yeniden çekilmeli.
Kişisel veri içermeyen örnek hesap kullanın.

**Uygulama simgesi:** 1024×1024, **saydamlık olmadan** (Apple alfa kanalını reddeder) — Xcode asset
kataloğunda; App Store bunu oradan alır.

---

## Uygulama Gizliliği (App Privacy etiketleri) ⚠️

**Verileri izleme (tracking) için kullanıyor musunuz?** → **Hayır** (reklam yok, başka şirketlerin verisiyle
birleştirme yok → App Tracking Transparency izni gerekmez).

**Veri topluyor musunuz?** → **Evet**. Aşağıdakileri işaretleyin:

| Kategori → Tür | Amaç | Kullanıcıya bağlı mı | İzleme |
|---|---|---|---|
| İletişim Bilgileri → **Ad** | Uygulama İşlevselliği | Evet | Hayır |
| İletişim Bilgileri → **E-posta Adresi** | Uygulama İşlevselliği | Evet | Hayır |
| Finansal Bilgiler → **Diğer Finansal Bilgiler** (kullanıcının girdiği gelir/gider, fatura, hedef) | Uygulama İşlevselliği | Evet | Hayır |
| Tanılama → **Kilitlenme Verileri** (Crashlytics) | Uygulama İşlevselliği, Analiz | Hayır | Hayır |
| Tanılama → **Diğer Tanılama Verileri** (cihaz modeli, iOS sürümü) | Uygulama İşlevselliği, Analiz | Hayır | Hayır |
| Tanımlayıcılar → **Cihaz Kimliği** (Firebase kurulum kimliği; reklam kimliği DEĞİL) | Analiz | Hayır | Hayır |

Toplanmayanlar: konum, kişiler, sağlık, fotoğraf, ses, tarama/arama geçmişi, satın alımlar, kullanım verisi,
hassas bilgiler, reklam verisi.

> Kilitlenme verileri "Kullanıcıya bağlı değil" çünkü Crashlytics'e kullanıcı kimliği/e-posta gönderilmiyor
> (kodda ayarlandı). Bu ileride değişirse etiketi de güncelleyin.

---

## Yaş derecelendirmesi
Tüm sorulara "Yok/Hayır" (şiddet, cinsellik, kumar, kontrolsüz web erişimi, kullanıcılar arası iletişim yok)
→ beklenen sonuç **4+**.

## Şifreleme (Export Compliance)
Uygulama yalnızca HTTPS ve işletim sisteminin standart şifrelemesini kullanır → **muaf**.
`Info.plist`'te `ITSAppUsesNonExemptEncryption = NO` (Xcode projesinde ayarlanır), böylece her yüklemede soru sorulmaz.

## Uygulama İncelemesi bilgileri
- **Oturum açma gerekli:** Evet → Kullanıcı adı `<inceleme hesabı e-postası>`, Şifre `<şifre>`
  (Play için açılan aynı test hesabı olabilir; e-postası doğrulanmış, içinde örnek veri olmalı)
- **İletişim:** ad, telefon, e-posta (yalnızca Apple görür)
- **Notlar:**
```
Kişisel bütçe takip uygulamasıdır; banka bağlantısı, ödeme veya kripto alım-satımı yoktur. Döviz/kripto kurları
yalnızca bilgi amaçlı gösterilir. Hesap silme: Ayarlar → Hesabı Sil. Fatura hatırlatmaları cihazda yerel bildirimdir.
```

## Apple'ın sık reddettiği noktalar (kontrol edildi)
- ✅ Uygulama içi hesap silme var (Ayarlar → Hesabı Sil) — 5.1.1(v)
- ✅ Üçüncü taraf giriş (Google vb.) yok → "Apple ile Giriş" zorunlu değil — 4.8
- ✅ Gizlilik politikası ve destek sayfası uygulama dışında erişilebilir
- ✅ Zorunlu güncelleme ekranı iOS'ta App Store bağlantısını açmalı (Play'e değil) — sunucu `platform=ios` için
  `APP_STORE_URL` döner; bu değer App Store Connect'te uygulama oluşunca sunucuya girilmeli
- ☐ İnceleme sırasında sunucu açık ve test hesabı çalışır durumda olmalı
