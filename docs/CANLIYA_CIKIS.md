# Canlıya Çıkış Rehberi — Finans Cepte v1 (Android + iOS)

Sırayla ilerleyin. ☐ = yapılacak. "Kim" sütunu: **Sen** = Ayşenur, **Claude** = kod/ayar işleri.

---

## 0. Takvim: 14 günlük kapalı test zorunlu

Yeni kişisel Play geliştirici hesaplarında **üretime (herkese açık) çıkmadan önce en az 12 test
kullanıcısıyla 14 gün kesintisiz kapalı test** gerekir. Kapalı test, canlı sunucuya bağlı bir
sürümle yapılır → **sunucu (1–3. adımlar) kapalı testten önce hazır olmalı.**

Şimdiden: ☐ 12+ test kullanıcısı bul (Gmail hesabı olan, Android telefon kullanan; arkadaş/aile).
14 gün boyunca uygulamayı **kurulu tutmaları** ve ara sıra açmaları yeterli.

---

## 1. Kararlar (Sen)

| ☐ | Karar | Not |
|---|---|---|
| ☐ | **Döviz ekranı** | Yahoo verisi lisans gereği yayında kullanılamaz. Seçenekler: (a) ECB + CoinGecko'ya geçir, (b) v1'de ekranı gizle, sonra aç. En hızlısı (b). |
| ☐ | **Hosting** | Öneri: Render (Frankfurt). Web servisi + **ücretli** Postgres (ücretsiz veritabanı 30 günde silinir; ücretli plan günlük yedek alır). |
| ☐ | **Alan adı** | ör. `finanscepte.com` → API: `api.finanscepte.com` |
| ☐ | **Veri sorumlusu adı** | Gizlilik metninde görünür (KVKK gereği). Kendi adın. |

## 2. Hesaplar ve sırlar (Sen)

| ☐ | İş | Nasıl |
|---|---|---|
| ☐ | Destek Gmail'i | Yeni Gmail aç. Play'de herkese açık görünür. |
| ☐ | Gmail **uygulama şifresi** | Google Hesabı → Güvenlik → 2 Adımlı Doğrulama'yı aç → "Uygulama şifreleri" → 16 haneli şifre. **Bu olmadan kimse kayıt olamaz** (doğrulama kodu e-postayla gider). |
| ☐ | Play Console hesabı | play.google.com/console — kişisel hesap, 25 $ tek seferlik, kimlik doğrulaması birkaç gün sürebilir. |
| ☐ | Sentry (isteğe bağlı, önerilir) | sentry.io → ücretsiz hesap → Flask projesi → DSN'i kopyala. Sunucu hatalarını e-postayla bildirir. |
| ☐ | UptimeRobot (önerilir) | uptimerobot.com → ücretsiz → HTTP monitor: `https://api.ALANADI/health` (5 dk). Sunucu veya veritabanı düşerse e-posta gelir. |
| ✅ | Firebase'e Android uygulaması (`com.finanscepte.app`) | Eklendi; kimlik derleme scriptine işlendi. |
| ☐ | Eski Firebase uygulamasını sil | Firebase Console → Proje ayarları → `com.example.test_borsa` (eski paket) → Uygulamayı kaldır. |
| ☐ | **Crashlytics'i etkinleştir** | Firebase Console → sol menü → Crashlytics → **Etkinleştir** (yapılmadıysa). |
| ☐ | firebase CLI | `npm install -g firebase-tools` → `firebase login` (release'te Crashlytics sembollerini yüklemek için) |
| ☐ | Firebase anahtarını kısıtla (isteğe bağlı) | Google Cloud Console → API'ler → Kimlik bilgileri → Firebase Android anahtarı → Android uygulamaları: `com.finanscepte.app` + imza SHA-1. |

## 3. Sunucu (Claude hazırlar, sen hesapta tıklarsın)

Production ortam değişkenleri (`server_api/.env.example` hepsini açıklar):

```
APP_ENV=production
SECRET_KEY=<YENİ üret>            # python3 -c "import secrets; print(secrets.token_urlsafe(48))"
JWT_SECRET_KEY=<YENİ üret, farklı>
DATABASE_URL=<hosting verir>
PUBLIC_BASE_URL=https://api.ALANADI
TRUSTED_PROXIES=1
MAIL_USERNAME=<destek gmail>
MAIL_PASSWORD=<uygulama şifresi>
MAIL_DEFAULT_SENDER=<destek gmail>
SUPPORT_EMAIL=<destek gmail>
DATA_CONTROLLER_NAME=<adın soyadın>
HOSTING_LOCATION=Almanya (Frankfurt)   # sunucu nerdeyse
SENTRY_DSN=<varsa>
MIN_APP_VERSION_CODE=1
LATEST_APP_VERSION_CODE=1
IOS_MIN_APP_VERSION_CODE=1
IOS_LATEST_APP_VERSION_CODE=1
APP_STORE_URL=                     # App Store Connect'te uygulama oluşunca: https://apps.apple.com/app/id<numara>
```

⚠️ Yerel `.env`'deki anahtarları **kullanma**, canlı için yenilerini üret. `APP_ENV=production` iken
`PUBLIC_BASE_URL` (https), `SUPPORT_EMAIL`, `MAIL_USERNAME`, `MAIL_PASSWORD` eksikse sunucu **açılmaz** ve
hangisinin eksik olduğunu loga yazar (bilerek).

Kurulumdan önce testler: `server_api/tests/run_all.sh` → "0 hata" görmelisin.

Kurulumdan sonra kontrol:
☐ `https://api.ALANADI/health` → `{"status":"ok"}`
☐ `https://api.ALANADI/privacy` → adın ve sunucu konumu doğru görünüyor
☐ `https://api.ALANADI/support` → destek e-postası doğru (App Store'un zorunlu Destek URL'si)
☐ Gerçek bir e-postayla kayıt → doğrulama kodu geliyor (spam klasörüne de bak)

## 4. Uygulama sürümü (Claude derler, sen saklarsın)

```
API_BASE_URL=https://api.ALANADI SUPPORT_EMAIL=<destek gmail> scripts/build_release.sh        # Android (AAB)
API_BASE_URL=https://api.ALANADI SUPPORT_EMAIL=<destek gmail> \
APP_STORE_URL=https://apps.apple.com/app/id<numara> scripts/build_ios_release.sh           # iOS (IPA)
```

☐ Çıktı: `build/app/outputs/bundle/release/app-release.aab`
☐ **Yedekle (flash bellek + şifre yöneticisi):** `release-symbols/` klasörü + `~/keystores/finanscepte-upload.jks` + `android/key.properties`
   içeriği (şifreler) → şifre yöneticisi / ayrı disk. Keystore kaybolursa uygulama güncellenemez.
☐ **Gerçek bir Android telefonda** baştan sona dene: kayıt → kod → giriş → işlem/hedef/fatura ekle →
   şifre değiştir → çıkış → şifremi unuttum → hesabı sil.

## 5. Play Console (Sen — metinler `docs/PLAY_CONSOLE.md`'de hazır)

☐ Uygulama oluştur (ad: Finans Cepte, varsayılan dil: Türkçe, uygulama, ücretsiz)
☐ **Play App Signing** açık kalsın (varsayılan) → yükleme anahtarı kaybolursa kurtarılabilir
☐ Uygulama içeriği: gizlilik politikası, uygulama erişimi (test hesabı!), reklamlar, içerik derecelendirmesi,
   hedef kitle, veri güvenliği, finansal özellikler, hesap silme — cevaplar `PLAY_CONSOLE.md`'de
☐ Mağaza girişi: açıklamalar (`PLAY_CONSOLE.md`) + görseller ✅ hazır: `docs/store-images/` (ikon, tanıtım görseli, 5 ekran görüntüsü)
☐ **Kapalı test** kanalı → AAB yükle → test kullanıcılarının Gmail'lerini ekle → katılım bağlantısını gönder
☐ 14 gün sonra: "Üretime erişim başvurusu" (test sürecine dair birkaç soru sorulur) → onaylanınca üretime yayınla

## 5b. App Store (Sen + tasarım oturumu — metinler `docs/APP_STORE.md`'de hazır)

Android'in 14 günlük kapalı testi sürerken paralel hazırlanır; Android'i bekletmez. Sunucu ve alan adı ortak.

☐ **Apple Developer Program** (bireysel, 99 $/yıl; Türkiye'de TL fiyatı kayıt ekranında görünür) — kimlik
   doğrulaması birkaç gün sürebilir, **hemen başvur**. Satıcı adı olarak gerçek adın görünür.
✅ Firebase'e iOS uygulaması eklendi (`com.finanscepte.app`); kimlik iOS derleme scriptine işlendi, dSYM'ler Xcode'da otomatik yüklenir
☐ App Store Connect → Yeni uygulama (bundle ID `com.finanscepte.app`) → oluşan **Apple ID numarasıyla**
   sunucuda `APP_STORE_URL=https://apps.apple.com/app/id<numara>` ayarla (zorunlu güncelleme ekranı bunu açar)
☐ iOS ekran görüntüleri (6.9" iPhone) — Android görselleri oran farkından kullanılamaz
☐ Gizlilik etiketleri, yaş derecelendirmesi, inceleme notu ve test hesabı → `APP_STORE.md`
☐ TestFlight ile gerçek iPhone'da test (kayıt → kod → giriş → işlem → fatura hatırlatması → hesabı sil)
☐ Derle: `scripts/build_ios_release.sh` (yukarıdaki 4. adım) → IPA'yı **Transporter** uygulamasıyla yükle
☐ İncelemeye gönder (genelde 1–2 gün)

iOS sürüm numaraları: Xcode'da sürüm (`1.0.0`) ve build number (her yüklemede artar). Sunucuda iOS'un
MIN/LATEST değerleri Android'den **ayrı** tutulur (`IOS_MIN_APP_VERSION_CODE`, `IOS_LATEST_APP_VERSION_CODE`).

## 6. Yayından sonra

- **E-posta sınırı:** Gmail SMTP günde ~500 e-posta gönderebilir (doğrulama kodu + şifre sıfırlama). Günlük
  kayıtlar bu sınıra yaklaşınca işlem e-postası servisine (ör. Brevo, Resend — ücretsiz planları var) geçilmeli;
  yalnızca `MAIL_*` ortam değişkenleri değişir.
- **İleride (iOS):** Firebase'in iOS'taki CocoaPods dağıtımı Ekim 2026'da donduruluyor; Swift Package Manager'a
  geçiş tasarım/istemci tarafında yapılacak (uygulamanın çalışmasını hemen etkilemez).

- Yeni sürüm: `pubspec.yaml` → `version: 1.0.1+2` (sondaki sayı **her seferinde artar**), `lib/utils/app_info.dart`
  → `kAppVersion` aynı sürüm. Yayınlayınca sunucuda `LATEST_APP_VERSION_CODE=2` → eski sürümdekilere "yeni sürüm var".
- Sunucuda **eski uygulamayı bozan** değişiklik yapılırsa: `MIN_APP_VERSION_CODE` = yeni sürümün kodu → eski sürüm
  "Güncelleme gerekli" ekranı görür.
- Hesap silme e-postayla istenirse: 30 gün içinde yanıtla (gizlilik metninde söz verildi).

## 7. Hukuki not (KVKK)

Sunucu Türkiye dışındaysa (Render: Almanya) bu **yurt dışına veri aktarımıdır**. Gizlilik metni bunu söylüyor;
ayrıca KVKK'nın 2024 değişikliğiyle hizmet sağlayıcıyla **standart sözleşme** imzalanıp 5 iş günü içinde Kurum'a
bildirilmesi gerekebilir. Küçük ölçekli geliştiriciler genelde VERBİS kaydından muaftır. **Kesin durum için kısa bir
hukuki görüş al** — bu rehber hukuki tavsiye değildir.
