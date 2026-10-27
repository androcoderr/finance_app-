import os
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()


def _database_url():
    url = os.getenv('DATABASE_URL', 'sqlite:///finance.db')
    # Heroku/Render "postgres://" verir, SQLAlchemy "postgresql://" bekler
    if url.startswith('postgres://'):
        url = url.replace('postgres://', 'postgresql://', 1)
    return url


def _bool(name, default=False):
    return os.getenv(name, str(default)).lower() in ('1', 'true', 'yes')


class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-change-me')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-jwt-secret-change-me')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=int(os.getenv('JWT_ACCESS_MINUTES', '60')))
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=int(os.getenv('JWT_REFRESH_DAYS', '30')))

    SQLALCHEMY_DATABASE_URI = _database_url()
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {'pool_pre_ping': True}

    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', '587'))
    MAIL_USE_TLS = _bool('MAIL_USE_TLS', True)
    MAIL_USE_SSL = _bool('MAIL_USE_SSL', False)
    MAIL_USERNAME = os.getenv('MAIL_USERNAME')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD')
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', os.getenv('MAIL_USERNAME'))

    # E-postadaki bağlantılarda kullanılan, sunucunun dışarıdan erişilen adresi
    PUBLIC_BASE_URL = os.getenv('PUBLIC_BASE_URL', 'http://localhost:8000').rstrip('/')

    RATELIMIT_STORAGE_URI = os.getenv('RATELIMIT_STORAGE_URI', 'memory://')
    RATELIMIT_HEADERS_ENABLED = True

    # İstek gövdesi üst sınırı (dev JSON ile bellek/CPU tüketmeyi engeller)
    MAX_CONTENT_LENGTH = 1 * 1024 * 1024


    # Zorunlu güncelleme (Android versionCode = pubspec "version: x.y.z+KOD" içindeki KOD).
    # MIN altındaki sürümler kullanılamaz; LATEST altındakilere "yeni sürüm var" önerilir.
    MIN_APP_VERSION_CODE = int(os.getenv('MIN_APP_VERSION_CODE', '1'))
    LATEST_APP_VERSION_CODE = int(os.getenv('LATEST_APP_VERSION_CODE', os.getenv('MIN_APP_VERSION_CODE', '1')))
    PLAY_STORE_URL = os.getenv(
        'PLAY_STORE_URL', 'https://play.google.com/store/apps/details?id=com.finanscepte.app'
    )
    # iOS: build number (CFBundleVersion) Android versionCode'dan bağımsız ilerler, ayrı tutulur.
    IOS_MIN_APP_VERSION_CODE = int(os.getenv('IOS_MIN_APP_VERSION_CODE', '1'))
    IOS_LATEST_APP_VERSION_CODE = int(os.getenv('IOS_LATEST_APP_VERSION_CODE', os.getenv('IOS_MIN_APP_VERSION_CODE', '1')))
    # App Store Connect'te uygulama oluşturulunca: https://apps.apple.com/app/id<numara>
    APP_STORE_URL = os.getenv('APP_STORE_URL', '')


    @classmethod
    def validate(cls):
        """Production'da varsayılan sırlarla çalışmayı engeller."""
        if os.getenv('FLASK_ENV') == 'production' or os.getenv('APP_ENV') == 'production':
            missing = [k for k in ('SECRET_KEY', 'JWT_SECRET_KEY') if getattr(cls, k).startswith('dev-')]
            # Unutulursa sessizce yanlış çalışırlar: sıfırlama linki localhost'a gider,
            # gizlilik sayfasında örnek e-posta görünür, kimse kayıt olamaz (kod gönderilemez)
            if not cls.PUBLIC_BASE_URL.startswith('https://'):
                missing.append('PUBLIC_BASE_URL (https://...)')
            for k in ('SUPPORT_EMAIL', 'MAIL_USERNAME', 'MAIL_PASSWORD'):
                if not os.getenv(k):
                    missing.append(k)
            if missing:
                raise RuntimeError(f"Production ortamında şu değişkenler ayarlanmalı: {', '.join(missing)}")
