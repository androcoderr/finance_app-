/*
Aşağıda finans yönetimi uygulaman için oluşturduğumuz tüm modelleri tek tek açıklamalarıyla birlikte listeledim. Her modelin ne işe yaradığını, neden gerektiğini ve sistemdeki rolünü net şekilde anlayacaksın.

📦 1. UserModel
✅ Amaç:
Uygulamayı kullanan her bir kullanıcı için temel bilgileri ve ilişkili verileri tutar.

📌 Alanlar:
id: Her kullanıcıya özel benzersiz kimlik.

name, email: Kullanıcı bilgileri.

transactions: Kullanıcının tüm gelir/gider işlemleri.

goals: Kullanıcının hedefleri.

🧠 Neden Gerekli?
Kişiye özel finans yönetimi yapıldığından, tüm veriler bir kullanıcıya bağlı olmalı.

💸 2. TransactionModel
✅ Amaç:
Her bir gelir veya gider işlemini temsil eder.

📌 Alanlar:
id, userId: İşlem ve kullanıcı kimliği.

amount: Para miktarı.

type: Gelir mi gider mi?

categoryId: Hangi kategoride (örn. market, maaş).

description: Açıklama.

date: İşlem tarihi.

linkedGoalId: (Opsiyonel) Bu işlem bir hedefe bağlı mı?

🧠 Neden Gerekli?
Kullanıcının tüm finansal aktiviteleri bu modelle takip edilir. Grafik ve analizler için temel veri kaynağıdır.

🧾 3. CategoryModel
✅ Amaç:
Gelir ve giderleri kategorilere ayırmak.

📌 Alanlar:
id, userId: Kategori kimliği ve sahibi.

name: Kategori ismi (örn. "Market", "Kira").

type: Bu kategori gelir mi gider mi?

icon: Görsel gösterim için ikon.

🧠 Neden Gerekli?
Gelir/gider analizlerinde, filtrelemede ve grafiklerde kullanılır.

🎯 4. GoalModel
✅ Amaç:
Kullanıcının tasarruf hedeflerini temsil eder.

📌 Alanlar:
id, userId: Hedef kimliği.

title: Hedef adı (örn. "Tatile gitmek").

targetAmount: Hedeflenen tutar.

savedAmount: Şu ana kadar biriktirilen.

deadline: Hedefin son tarihi.

linkedTransactionIds: Hangi işlemler bu hedef için kullanıldı?

🧠 Neden Gerekli?
Finansal motivasyonu artırmak için hedef takibi sağlar. Uygulama içi başarı ve planlama için kritiktir.

📊 5. BudgetModel
✅ Amaç:
Kategorilere veya genel olarak bütçe sınırları koymak.

📌 Alanlar:
id, userId: Bütçe kimliği.

categoryId: Bu bütçe bir kategoriye mi ait?

limitAmount: Harcama limiti.

startDate, endDate: Bütçenin geçerli olduğu dönem.

🧠 Neden Gerekli?
Aylık harcamaları kontrol etmek, aşım durumunda uyarılar göndermek için kullanılır.

🔁 6. RecurringTransactionModel
✅ Amaç:
Tekrarlayan işlemleri (örn. kira, maaş) tanımlar.

📌 Alanlar:
id, userId: İşlem kimliği.

amount, type, categoryId, description: Normal işlemler gibi.

startDate: İlk işlem tarihi.

interval: Tekrarlama aralığı (örn. her ay, her hafta).

endDate: (Opsiyonel) Ne zaman bitecek?

🧠 Neden Gerekli?
Her ay manuel işlem girmemek için otomasyon sağlar. Gelir/gider tahmini yapılmasına olanak tanır.

🧠 7. InsightModel
✅ Amaç:
Uygulamanın kullanıcılara sunduğu öneriler ve analizler.

📌 Alanlar:
id, userId

title, description: İçerik.

type: Uyarı mı, fırsat mı?

createdAt: Ne zaman üretildi?

🧠 Neden Gerekli?
Harcamalarda anormallik varsa, fazla gider varsa kullanıcıya otomatik öneriler göstermek için kullanılır.

🔔 8. NotificationSettingModel
✅ Amaç:
Bildirim tercihlerini ve sistemin uyarı ayarlarını tutar.

📌 Alanlar:
id, userId

monthlySummary: Aylık özet almak ister mi?

budgetWarnings: Bütçe aşımı bildirimi.

goalReminders: Hedef hatırlatmaları.

🧠 Neden Gerekli?
Kullanıcının deneyimini özelleştirmek ve daha fazla etkileşim sağlamak için kullanılır.

⚙️ 9. SettingsModel (opsiyonel)
✅ Amaç:
Kullanıcının uygulama içi ayarlarını tutar.

📌 Alanlar:
currency: Para birimi.

language: Dil seçimi.

theme: Karanlık / açık tema.

🧠 Neden Gerekli?
Uygulamanın kullanıcı bazında kişiselleştirilmesini sağlar.

✏️ Ekstra Eklenebilecekler:
DebtModel: Borç/alacak takibi için.

SharedWalletModel: Aile/ortak cüzdan yapısı.

AchievementModel: Başarı rozeti sistemi.

AuditLogModel: Sistem geçmişi (güvenlik için).
*/
