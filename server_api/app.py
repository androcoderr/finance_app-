from flask import Flask, jsonify, request
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
from flask_mail import Mail  # YENİ
import os
from config.config import Config
from database.db import db
from routes.category_route import category_bp
from routes.goal_route import goal_bp
from routes.transaction_route import transaction_bp
from routes.user_route import user_bp
from routes.auth_route import auth_bp
from routes.recurring_transaction_routes import recurring_bp
from routes.bill_route import bill_bp
from extension import limiter
from services.firebase_service import FirebaseService
from routes.two_factor_route import two_factor_bp
from routes.password_reset_route import password_reset_bp
from routes.legal_route import legal_bp

load_dotenv()

Config.validate()

app = Flask(__name__)
app.config.from_object(Config)

# Render/Nginx gibi bir proxy arkasında gerçek istemci IP'sini al (rate limit kişi başı çalışsın).
# TRUSTED_PROXIES = önümüzdeki proxy sayısı; doğrudan internete açıksa 0 olmalı.
_proxies = int(os.getenv('TRUSTED_PROXIES', '0'))
if _proxies:
    from werkzeug.middleware.proxy_fix import ProxyFix
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=_proxies, x_proto=_proxies, x_host=_proxies)

limiter.init_app(app)


@app.errorhandler(429)
def too_many_requests(e):
    return jsonify(error="Çok fazla istek gönderildi. Lütfen biraz sonra tekrar deneyin."), 429


@app.errorhandler(413)
def payload_too_large(e):
    return jsonify(error="İstek çok büyük."), 413


@app.errorhandler(500)
def internal_error(e):
    return jsonify(error="Sunucu tarafında bir hata oluştu"), 500


# Tarayıcıda açılan sayfalar (şifre sıfırlama, gizlilik) ve API yanıtları için güvenlik başlıkları
_CSP = ("default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; "
        "connect-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'")


@app.after_request
def security_headers(response):
    h = response.headers
    h.setdefault('X-Content-Type-Options', 'nosniff')
    h.setdefault('X-Frame-Options', 'DENY')
    # Sıfırlama sayfasının adresindeki token başka sitelere Referer ile gitmesin
    h.setdefault('Referrer-Policy', 'no-referrer')
    h.setdefault('Content-Security-Policy', _CSP)
    # Finansal veri ve token içeren yanıtlar ara bellekte (proxy/cihaz) saklanmasın
    h.setdefault('Cache-Control', 'no-store')
    if request.is_secure:
        h.setdefault('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
    return response

db.init_app(app)
jwt = JWTManager(app)
mail = Mail(app)

# JWT claims loader to include user role in tokens
@jwt.additional_claims_loader
def add_claims_to_access_token(identity):
    from models.user_model import User
    user = User.query.get(identity)
    if user:
        return {
            'role': user.role,
            'tv': user.token_version,
        }
    return {}


@jwt.token_in_blocklist_loader
def is_token_revoked(jwt_header, jwt_payload):
    """Kullanıcı silindiyse veya şifresi değiştiyse (token_version arttıysa) token geçersizdir."""
    from models.user_model import User
    user = db.session.get(User, jwt_payload.get('sub'))
    return user is None or jwt_payload.get('tv') != user.token_version


@jwt.revoked_token_loader
def revoked_token_response(jwt_header, jwt_payload):
    return jsonify(error="Oturumunuzun süresi doldu, lütfen tekrar giriş yapın."), 401

# Firebase'i başlat (YENİ)
FirebaseService.initialize()

# Yapay zeka servisleri yalnızca AI_ENABLED=1 iken yüklenir (torch vb. kurulu olmalı)
if Config.AI_ENABLED:
    from services.ai_anomaly_service import AIService
    from routes.finance_route import finance_bp
    from routes.anomaly_route import anomaly_bp
    ai_service = AIService()
    ai_service.start_worker(app)  # Pass app instance for DB access
    print("[App] AI Anomaly Service initialized and worker started")
else:
    print("[App] AI özellikleri devre dışı (AI_ENABLED=0)")

# Blueprints
app.register_blueprint(user_bp)
app.register_blueprint(auth_bp)
app.register_blueprint(goal_bp)
app.register_blueprint(transaction_bp)
app.register_blueprint(category_bp)
app.register_blueprint(recurring_bp)
app.register_blueprint(bill_bp)
app.register_blueprint(two_factor_bp)
app.register_blueprint(password_reset_bp)
app.register_blueprint(legal_bp)
if Config.AI_ENABLED:
    app.register_blueprint(finance_bp)
    app.register_blueprint(anomaly_bp)

from models.user_model import User
from models.budget_model import Budget
from models.category_model import Category
from models.goal_model import Goal
from models.transaction_model import UserTransaction
from models.insight_model import Insight
from models.recurring_transaction_model import RecurringTransaction
from models.two_factor_session_model import TwoFactorSession
from models.bill_model import Bill
from models.goal_date import GoalDate


@app.route('/health')
@limiter.exempt
def health():
    return jsonify(status='ok', ai_enabled=Config.AI_ENABLED)

def insert_default_categories():
    """Varsayılan kategorilerden eksik olanları ekler (mevcut veritabanlarında da çalışır)."""
    from models.category_model import Category

    existing_names = {c.name for c in Category.query.all()}

    # Define default categories
    default_categories = [
        {"name": "Market", "is_income": False},
        {"name": "Alışveriş", "is_income": False},
        {"name": "Yiyecek", "is_income": False},
        {"name": "Telefon", "is_income": False},
        {"name": "Eğlence", "is_income": False},
        {"name": "Eğitim", "is_income": False},
        {"name": "Güzellik", "is_income": False},
        {"name": "Spor", "is_income": False},
        {"name": "Sosyal", "is_income": False},
        {"name": "Ulaşım", "is_income": False},
        {"name": "Giyim", "is_income": False},
        {"name": "Araba", "is_income": False},
        {"name": "İçecekler", "is_income": False},
        {"name": "Sigara", "is_income": False},
        {"name": "Elektronik", "is_income": False},
        {"name": "Seyahat", "is_income": False},
        {"name": "Sağlık", "is_income": False},
        {"name": "Pet", "is_income": False},
        {"name": "Onarım", "is_income": False},
        {"name": "Konut", "is_income": False},
        {"name": "Mobilya", "is_income": False},
        {"name": "Hediyeler", "is_income": False},
        {"name": "Bağış", "is_income": False},
        {"name": "Oyun", "is_income": False},
        {"name": "Atıştırmalık", "is_income": False},
        {"name": "Çocuk", "is_income": False},
        {"name": "Faturalar", "is_income": False},
        {"name": "Diğer", "is_income": False},
        {"name": "Maaş", "is_income": True},
        {"name": "Prim", "is_income": True},
        {"name": "Hediye", "is_income": True},
        {"name": "Yatırım", "is_income": True},
        {"name": "Ek Gelir", "is_income": True},
        {"name": "Faiz", "is_income": True},
        {"name": "Diğer Gelir", "is_income": True},
    ]
    
    missing = [c for c in default_categories if c["name"] not in existing_names]
    for cat_data in missing:
        db.session.add(Category(**cat_data))
    db.session.commit()
    if missing:
        print(f"{len(missing)} varsayılan kategori eklendi.")


# Add CLI command for initialization
@app.cli.command()
def init_db():
    """Initialize the database with default categories."""
    with app.app_context():
        db.create_all()
        print("Tables created!")
        insert_default_categories()
    print("Database initialization completed!")


def ensure_columns():
    """create_all mevcut tablolara sütun eklemez; sonradan eklenen sütunları ekler."""
    from sqlalchemy import inspect, text
    added = [
        ('recurring_transactions', 'last_generated', 'DATE'),
        ('two_factor_sessions', 'pending_fcm_token', 'VARCHAR(512)'),
        ('users', 'token_version', 'INTEGER NOT NULL DEFAULT 0'),
        # Mevcut kullanıcılar doğrulanmış sayılır; yeni kayıtlarda model False verir
        ('users', 'email_verified', 'BOOLEAN NOT NULL DEFAULT TRUE'),
        ('users', 'verification_code_hash', 'VARCHAR(64)'),
        ('users', 'verification_expires_at', 'TIMESTAMP'),
        ('users', 'verification_sent_at', 'TIMESTAMP'),
        ('users', 'verification_attempts', 'INTEGER NOT NULL DEFAULT 0'),
    ]
    for table, column, sql_type in added:
        columns = {c['name'] for c in inspect(db.engine).get_columns(table)}
        if column not in columns:
            db.session.execute(text(f'ALTER TABLE {table} ADD COLUMN {column} {sql_type}'))
            db.session.commit()


# Tablolar yoksa oluştur ve varsayılan kategorileri ekle (gunicorn ile de çalışır)
with app.app_context():
    db.create_all()
    ensure_columns()
    insert_default_categories()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', '8000')),
            debug=os.getenv('FLASK_DEBUG') == '1', use_reloader=False)