// Yapay zeka özellikleri (bütçe analizi, anomali bildirimi). Fiş okuma v1'den
// kaldırıldı (git geçmişinde). Varsayılan kapalı. Açmak için derlerken:
//   flutter build apk --dart-define=AI_ENABLED=true
// Backend tarafında da AI_ENABLED=1 olmalı.
const bool kAiEnabled = bool.fromEnvironment('AI_ENABLED');

// Uygulama içi bildirim sayfası ve uzaktan bildirim (FCM) yalnızca sunucudan
// bildirim gelen bir özellik açıkken gerekir. 2FA ve Google ile giriş v1'de
// kaldırıldı (git geçmişinde). Fatura hatırlatmaları bundan bağımsızdır (yerel).
const bool kNotificationsEnabled = kAiEnabled;
