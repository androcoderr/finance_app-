import firebase_admin
from firebase_admin import credentials, messaging
import os


class FirebaseService:
    """Firebase Cloud Messaging servisi"""

    _initialized = False

    @classmethod
    def initialize(cls):
        """Firebase Admin SDK'yı başlat"""
        if cls._initialized:
            return

        try:
            # Firebase credentials dosyasını yükle
            cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')

            if not os.path.exists(cred_path):
                print(f"⚠️ Firebase credentials dosyası bulunamadı: {cred_path}")
                print("📝 Firebase Console'dan 'Service Account Key' indirip projeye ekleyin")
                return

            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            cls._initialized = True
            print("✅ Firebase Admin SDK başlatıldı")
        except Exception as e:
            print(f"❌ Firebase başlatma hatası: {e}")

    @classmethod
    def send_2fa_notification(cls, fcm_token, session_token, user_email, device_info):
        """
        Kullanıcıya 2FA onay bildirimi gönder

        Args:
            fcm_token: Kullanıcının Firebase token'ı
            session_token: 2FA session token'ı
            user_email: Kullanıcı email'i
            device_info: Cihaz bilgisi

        Returns:
            bool: Başarılı mı?
        """
        if not cls._initialized:
            cls.initialize()

        if not cls._initialized:
            print("❌ Firebase başlatılmamış, bildirim gönderilemedi")
            return False

        try:
            # Bildirim mesajı
            message = messaging.Message(
                notification=messaging.Notification(
                    title='🔐 Giriş Onayı Gerekli',
                    body=f'Hesabınıza giriş yapılmaya çalışılıyor. Cihaz: {device_info}',
                ),
                data={
                    'type': '2fa_request',
                    'session_token': session_token,
                    'email': user_email,
                    'device_info': device_info,
                    'timestamp': str(int(datetime.utcnow().timestamp())),
                },
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        click_action='FLUTTER_NOTIFICATION_CLICK',
                        sound='default',
                        channel_id='2fa_channel',
                    ),
                ),
                apns=messaging.APNSConfig(
                    headers={'apns-priority': '10'},
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
                token=fcm_token,
            )

            # Bildirimi gönder
            response = messaging.send(message)
            print(f"✅ 2FA bildirimi gönderildi: {response}")
            return True

        except Exception as e:
            print(f"❌ Bildirim gönderme hatası: {e}")
            return False

    @classmethod
    def send_2fa_approved_notification(cls, fcm_token, user_email):
        """Giriş onaylandı bildirimi"""
        if not cls._initialized:
            cls.initialize()

        if not cls._initialized:
            return False

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title='✅ Giriş Başarılı',
                    body='Hesabınıza giriş yapıldı.',
                ),
                data={
                    'type': '2fa_approved',
                    'email': user_email,
                },
                token=fcm_token,
            )

            messaging.send(message)
            return True
        except Exception as e:
            print(f"❌ Bildirim hatası: {e}")
            return False

    @classmethod
    def send_2fa_rejected_notification(cls, fcm_token, user_email):
        """Giriş reddedildi bildirimi"""
        if not cls._initialized:
            cls.initialize()

        if not cls._initialized:
            return False

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title='❌ Giriş Reddedildi',
                    body='Güvenlik nedeniyle giriş engellendi.',
                ),
                data={
                    'type': '2fa_rejected',
                    'email': user_email,
                },
                token=fcm_token,
            )

            messaging.send(message)
            return True
        except Exception as e:
            print(f"❌ Bildirim hatası: {e}")
            return False


# Datetime import'u
from datetime import datetime