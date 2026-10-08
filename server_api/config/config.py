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

    # Yapay zeka özellikleri (anomali tespiti, bütçe analizi). Açmak için:
    # AI_ENABLED=1 ve requirements-ai.txt bağımlılıkları gerekir.
    AI_ENABLED = _bool('AI_ENABLED', False)

    # Bildirimle iki aşamalı doğrulama. v1'de kapalı (kilitlenme riski, tek cihaza bağlı).
    # Kod duruyor; açmak için TWO_FACTOR_ENABLED=1 + uygulamada --dart-define=TWO_FACTOR=true
    TWO_FACTOR_ENABLED = _bool('TWO_FACTOR_ENABLED', False)

    ANOMALY_SERVICE_URL = os.getenv(
        'ANOMALY_SERVICE_URL', 'http://127.0.0.1:5002/api/anomaly/check-transaction'
    )

    @classmethod
    def validate(cls):
        """Production'da varsayılan sırlarla çalışmayı engeller."""
        if os.getenv('FLASK_ENV') == 'production' or os.getenv('APP_ENV') == 'production':
            weak = [k for k in ('SECRET_KEY', 'JWT_SECRET_KEY') if getattr(cls, k).startswith('dev-')]
            if weak:
                raise RuntimeError(f"Production ortamında şu değişkenler ayarlanmalı: {', '.join(weak)}")
