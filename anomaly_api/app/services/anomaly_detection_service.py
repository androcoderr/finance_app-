# app/services/anomaly_detection_service.py

import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import silhouette_score
import warnings
import datetime 

# Uyarıları bastır
warnings.filterwarnings('ignore')

# --------------------------------------------------------------------
# 1. 'UserAnomalyModel' SINIFI
# Bu, sizin test script'inizden alınan, modelin tüm mantığını 
# içeren sınıftır.
# --------------------------------------------------------------------
class UserAnomalyModel:
    def __init__(self, contamination=0.05, min_transactions_to_train=20):
        # NOT: contamination=0.05, işlemlerin %5'inin anormal olduğunu varsayar.
        # Bu değeri projenize göre ayarlayabilirsiniz (örn: 0.02)
        self.contamination = contamination
        self.min_transactions = min_transactions_to_train
        self.model = IsolationForest(contamination=self.contamination, random_state=42, n_estimators=100)
        self.category_encoder = LabelEncoder()
        # Modelin kullanacağı özellikler
        self.features = ['amount', 'day_of_week', 'category_encoded']
        self.is_fitted = False
        self.user_history = None 

    def _prepare_data(self, df):
        """
        Gelen DataFrame'i işler: tarihi datetime'a çevirir,
        haftanın gününü hesaplar ve eksik verileri atar.
        """
        df_copy = df.copy()
        df_copy['date'] = pd.to_datetime(df_copy['date'], errors='coerce')
        df_copy['day_of_week'] = df_copy['date'].dt.dayofweek
        df_copy.dropna(subset=['date', 'day_of_week', 'amount', 'category'], inplace=True)
        return df_copy

    def fit(self, user_history_df):
        """
        Modeli, verilen kullanıcının işlem geçmişine göre eğitir (fit eder).
        """
        # Sadece 'expense' (gider) işlemlerini al
        expense_history = user_history_df[user_history_df['type'].str.lower() == 'expense'].copy()
        
        user_history_df_prepared = self._prepare_data(expense_history)
        
        # Eğer kullanıcının geçmişi, belirlediğimiz minimum işlem sayısından azsa,
        # modeli "eğitilmedi" olarak işaretle ve çık.
        if len(user_history_df_prepared) < self.min_transactions:
            self.is_fitted = False
            print(f"Uyarı: Yetersiz veri ({len(user_history_df_prepared)}). Model eğitilemedi.")
            return

        # 1. Kategori kodlayıcıyı (LabelEncoder) eğit
        self.category_encoder.fit(user_history_df_prepared['category'])
        
        # 2. Kategorileri sayısallaştır
        user_history_df_prepared['category_encoded'] = self.category_encoder.transform(user_history_df_prepared['category'])
        
        # 3. Anomali modelini (IsolationForest) eğit
        self.model.fit(user_history_df_prepared[self.features])
        
        # 4. İstatistiksel kurallar için işlenmiş veriyi sakla
        self.user_history = user_history_df_prepared 
        self.is_fitted = True
        print(f"Model, {len(self.user_history)} gider işlemi ile eğitildi.")

    def predict(self, new_transaction_df):
        """
        Eğitilmiş modeli kullanarak yeni bir işlemin anomali olup olmadığını tahmin eder.
        """
        
        # Gelen yeni işlemi de aynı _prepare_data'dan geçir
        new_transaction_df = self._prepare_data(new_transaction_df)
        
        # Gelen işlemde veri hatası varsa (örn: tarih okunamadı)
        if new_transaction_df.empty:
            return (False, "Yeni işlem verisi işlenemedi (örn: tarih formatı bozuk).")
        
        # Yeni işlem bir GİDER değilse, kontrol etme
        if new_transaction_df['type'].iloc[0].lower() != 'expense':
            return (False, "✅ Bu bir gelir işlemi, anomali kontrolü yapılmadı.")

        # Model eğitilemediyse (yetersiz veri), her işlemi normal kabul et
        if not self.is_fitted:
            return (False, "Yeterli geçmiş veri olmadığı için harcama normal kabul edildi.")
            
        category_name = new_transaction_df['category'].iloc[0]
        amount = new_transaction_df['amount'].iloc[0]

        # Kural 1: Yeni Kategori Kontrolü
        try:
            # Bu kategoriyi daha önce gördük mü? Encoder'a sor.
            encoded_val = self.category_encoder.transform([category_name])
            new_transaction_df['category_encoded'] = encoded_val
        except ValueError:
            # Hata alırsak, bu yeni bir kategoridir. Bu bir anomalidir.
            return (True, f"🚨 ANOMALİ TESPİT EDİLDİ! '{category_name}' kategorisinde daha önce hiç harcama yapmamıştınız.")

        # Kural 2: Model Tahmini (Isolation Forest)
        # model.predict() -> -1 anormal, 1 normal demektir.
        is_anomaly_by_model = (self.model.predict(new_transaction_df[self.features])[0] == -1)

        # Kural 3: İstatistiksel Kural (Aşırı Yüksek Harcama)
        is_anomaly_by_rule = False
        mean_amount = 0.0
        
        # Bu kategorideki geçmiş harcamaları bul
        category_history = self.user_history[self.user_history['category'] == category_name]
        
        # Yeterli geçmiş varsa (örn: 5'ten fazla) istatistiksel olarak bak
        if len(category_history) > 5:
            mean_amount = category_history['amount'].mean()
            std_amount = category_history['amount'].std()
            
            if pd.notna(std_amount) and std_amount > 0:
                # 3-sigma kuralı (Ortalamanın 3 standart sapma üzeri)
                outlier_threshold = mean_amount + (3 * std_amount)
                if amount > outlier_threshold:
                    is_anomaly_by_rule = True
        
        # Sonuç
        if is_anomaly_by_model or is_anomaly_by_rule:
            if is_anomaly_by_rule:
                 return (True, f"🚨 ANORMAL BİR HARCAMA TESPİT EDİLDİ! '{category_name}' kategorisindeki {amount:.2f} TL harcamanız, bu kategorideki ortalama harcamanızın ({mean_amount:.2f} TL) çok üzerinde.")
            else:
                 return (True, f"🚨 ANORMAL BİR HARCAMA TESPİT EDİLDİ! '{category_name}' kategorisindeki {amount:.2f} TL tutarındaki harcama, genel harcama alışkanlıklarınızın dışında görünüyor.")
        else:
            return (False, "✅ Bu harcama normal görünüyor.")

# --------------------------------------------------------------------
# 2. 'AnomalyDetectionService' SINIFI
# Bu sınıf, route katmanıyla konuşan ve her istekte 
# yeni bir UserAnomalyModel oluşturan sarmalayıcıdır.
# --------------------------------------------------------------------
class AnomalyDetectionService:
    def __init__(self):
        """
        Bu servisin __init__'i boştur. Model, eğitilmiş dosyaları
        (model.joblib ve encoder.joblib) KULLANMAZ.
        Her kullanıcı için anlık olarak YENİDEN EĞİTİLİR (fit edilir).
        """
        print("AnomalyDetectionService (Anlık Eğitim) başlatıldı.")
        
    def check_transaction(self, user_history_list, new_transaction_dict):
        """
        Ana API fonksiyonu.
        1. Ham JSON verilerini alır.
        2. DataFrame'e dönüştürür.
        3. Kullanıcıya özel modeli eğitir.
        4. Yeni işlemi tahmin eder.
        """
        
        # 1. Gelen JSON listelerini Pandas DataFrame'e dönüştür
        try:
            history_df = pd.DataFrame.from_records(user_history_list)
            new_transaction_df = pd.DataFrame.from_records([new_transaction_dict])
        except Exception as e:
            print(f"DataFrame dönüştürme hatası: {e}")
            raise ValueError("Gelen 'user_history' veya 'new_transaction' verisi bozuk.")

        # 2. Her istek için yeni bir model nesnesi oluştur
        anomaly_model = UserAnomalyModel()

        # 3. Modeli kullanıcının geçmişiyle eğit
        # (fit metodu kendi içinde 'expense' filtresi yapıyor)
        anomaly_model.fit(history_df)

        # 4. Yeni işlemi tahmin et ve sonucu (tuple olarak) döndür
        return anomaly_model.predict(new_transaction_df)

# ====================================================================
# BU EN ÖNEMLİ KISIM:
# Bu dosya import edildiği anda (yani app/__init__.py'de),
# bu global nesne oluşturulur ve sunucu_başlarken_hazır hale gelir.
# ====================================================================
anomaly_service = AnomalyDetectionService()