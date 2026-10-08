// Yapay zeka özellikleri (fiş okuma/Gemini, bütçe analizi, anomali bildirimi).
// Varsayılan kapalı. Açmak için derlerken:
//   flutter build apk --dart-define=AI_ENABLED=true --dart-define=GEMINI_API_KEY=...
// Backend tarafında da AI_ENABLED=1 olmalı.
const bool kAiEnabled = bool.fromEnvironment('AI_ENABLED');

// "Google ile Giriş" — backend'de Google token doğrulaması henüz yok, bu yüzden kapalı.
const bool kGoogleSignInEnabled = bool.fromEnvironment('GOOGLE_SIGN_IN');

// Bildirimle iki aşamalı doğrulama — v1'de kapalı (kilitlenme riski, tek cihaza bağlı).
// Açmak için backend'de TWO_FACTOR_ENABLED=1 ve burada --dart-define=TWO_FACTOR=true
const bool kTwoFactorEnabled = bool.fromEnvironment('TWO_FACTOR');

// Uygulama içi bildirim sayfası ve bildirim izni yalnızca bildirim üreten bir
// özellik açıkken gerekir (v1'de ikisi de kapalı; izin boşuna istenmesin)
const bool kNotificationsEnabled = kAiEnabled || kTwoFactorEnabled;
