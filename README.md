# Finans Cepte

**Finans Cepte**, kişisel finans yönetiminizi kolaylaştırmak, gelir-gider takibi yapmak, faturalarınızı yönetmek ve finansal hedeflerinize ulaşmanıza yardımcı olmak için tasarlanmış kapsamlı bir Flutter uygulamasıdır. Modern arayüzü, gelişmiş analiz araçları ve akıllı özellikleriyle finansal özgürlüğünüze giden yolda size rehberlik eder.

## 🚀 Özellikler

*   **Güvenli Giriş & Kimlik Doğrulama:**
    *   Kullanıcı Kayıt ve Giriş işlemleri.
    *   Şifre Sıfırlama ve Unuttum seçenekleri.
    *   **İki Faktörlü Doğrulama (2FA):** Hesabınız için ekstra güvenlik katmanı.
*   **Finansal Takip:**
    *   Gelir ve Gider ekleme, düzenleme ve silme.
    *   Tekrarlayan İşlemler (Otomatik abonelik, kira vb. takibi).
    *   Detaylı işlem geçmişi ve filtreleme.
*   **Analiz ve Raporlama:**
    *   Görsel grafikler (`fl_chart`) ile harcama analizi.
    *   Kategori bazlı harcama dağılımları.
    *   Verileri PDF olarak dışa aktarma (Export).
*   **Fatura Yönetimi:**
    *   Fatura takibi ve ödeme hatırlatmaları.
    *   **OCR (Metin Tanıma):** Fatura veya fişlerinizi kamera ile tarayarak otomatik veri girişi.
*   **Hedefler:**
    *   Finansal hedefler oluşturma ve ilerleme takibi.
    *   Başarı kutlamaları (Konfeti efekti).
*   **Akıllı Araçlar:**
    *   **Sesli Komut (Speech to Text):** Sesli not veya işlem ekleme desteği.
    *   Alışveriş Listesi yönetimi.
*   **Kişiselleştirme:**
    *   **Tema Desteği:** Modern Karanlık (Dark) ve Aydınlık (Light) mod seçenekleri.
    *   Profil düzenleme ve bildirim ayarları.
*   **Çoklu Platform:** Android, iOS, Windows, Linux ve macOS desteği.

## 🛠️ Teknolojiler ve Mimari

Bu proje **Flutter** kullanılarak geliştirilmiştir ve temiz, ölçeklenebilir bir kod yapısına sahiptir.

*   **Mimari:** MVVM (Model-View-ViewModel)
*   **State Management (Durum Yönetimi):** `provider`
*   **Veritabanı:**
    *   Yerel: `sqflite` (Mobil), `sqflite_common_ffi` (Masaüstü)
    *   Uzak Sunucu/API: REST API entegrasyonu (`http`)
*   **Backend Servisleri:** Firebase (Authentication, Cloud Messaging, Core)
*   **UI/UX:** Material Design 3, `fl_chart`, `flutter_staggered_animations`
*   **Diğer Kütüphaneler:** `google_mlkit_text_recognition` (OCR), `share_plus`, `path_provider`, `intl`, `speech_to_text`.

## 📂 Proje Yapısı

```
lib/
├── models/          # Veri modelleri (JSON serileştirme vb.)
├── services/        # API, Firebase ve Veritabanı servisleri
├── view_model/      # İş mantığı ve State Management (Provider)
├── views/           # Kullanıcı arayüzü (Ekranlar)
│   └── widgets/     # Yeniden kullanılabilir UI bileşenleri
├── utils/           # Yardımcı fonksiyonlar ve sabitler
├── main.dart        # Uygulama giriş noktası
└── firebase_options.dart # Firebase yapılandırması
```

## 🏁 Kurulum ve Çalıştırma

Projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin:

### Ön Gereksinimler

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (Sürüm 3.8.1 ve üzeri)
*   Dart SDK
*   Bir IDE (VS Code veya Android Studio)

### Adımlar

1.  **Projeyi Klonlayın:**
    ```bash
    git clone <proje-adresi>
    cd test_borsa
    ```

2.  **Bağımlılıkları Yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Masaüstü Desteği (Opsiyonel):**
    Masaüstü platformlarda çalıştıracaksanız SQLite FFI başlatması otomatik olarak yapılmaktadır.

4.  **Uygulamayı Çalıştırın:**
    ```bash
    flutter run
    ```

## 📝 Lisans

Bu proje kişisel kullanım ve geliştirme amacıyla hazırlanmıştır.