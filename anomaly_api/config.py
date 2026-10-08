import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    # Ana API ile AYNI olmalı; token'lar orada üretilip burada doğrulanır
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-jwt-secret-change-me')
