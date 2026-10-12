# Finans Cepte

**Finans Cepte**, kişisel finans yönetiminizi kolaylaştırmak, gelir-gider takibi yapmak, faturalarınızı yönetmek ve finansal hedeflerinize ulaşmanıza yardımcı olmak için tasarlanmış kapsamlı bir Flutter uygulamasıdır. Modern arayüzü, gelişmiş analiz araçları ve akıllı özellikleriyle finansal özgürlüğünüze giden yolda size rehberlik eder.

## 🚀 Özellikler (v1)

*   **Hesap:** E-posta doğrulamalı kayıt, giriş, şifremi unuttum, şifre değiştirme, uygulama içinden hesap silme.
*   **Gelir ve gider:** Ekleme, düzenleme, silme; arama ve filtreli tüm işlemler listesi.
*   **Tekrarlayan işlemler:** Kira, abonelik, maaş gibi kayıtlar her dönem otomatik eklenir.
*   **Faturalar:** Son ödeme günü takibi, ödendi işaretleme, cihazda yerel hatırlatma bildirimi.
*   **Hedefler:** Birikim hedefleri ve ilerleme takibi.
*   **Raporlar:** Kategori dağılımı ve aylık grafikler, PDF dışa aktarma.
*   **Diğer:** Piyasalar (döviz/kripto), alışveriş listesi, karanlık/aydınlık tema.
*   **Platformlar:** Android ve iOS (iPhone).


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
