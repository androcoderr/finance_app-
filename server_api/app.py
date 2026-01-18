from flask import Flask
from flask_jwt_extended import JWTManager, create_access_token, get_jwt_identity
from datetime import timedelta
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
from routes.finance_route import finance_bp
from routes.anomaly_route import anomaly_bp
from extension import limiter
from services.firebase_service import FirebaseService
from routes.two_factor_route import two_factor_bp
from routes.password_reset_route import password_reset_bp

load_dotenv()

app = Flask(__name__)
app.config.from_object(Config)

limiter.init_app(app)

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
            'role': user.role
        }
    return {}

# Firebase'i başlat (YENİ)
FirebaseService.initialize()

# Initialize AI Anomaly Service
from services.ai_anomaly_service import AIService
ai_service = AIService()
ai_service.start_worker(app)  # Pass app instance for DB access
print("[App] AI Anomaly Service initialized and worker started")

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

def insert_default_categories():
    """Insert default categories if the categories table is empty."""
    from models.category_model import Category
    from repositories.category_repository import CategoryRepository
    
    # Check if categories already exist
    existing_categories = Category.query.all()
    if existing_categories:
        print(f"Categories table already has {len(existing_categories)} entries. Skipping default insertion.")
        return
    
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
        {"name": "Diğer", "is_income": False},
        {"name": "Maaş", "is_income": True},
        {"name": "Prim", "is_income": True},
        {"name": "Hediye", "is_income": True},
        {"name": "Yatırım", "is_income": True},
        {"name": "Ek Gelir", "is_income": True},
        {"name": "Faiz", "is_income": True},
        {"name": "Diğer Gelir", "is_income": True},
    ]
    
    # Insert each category
    for cat_data in default_categories:
        category = Category(**cat_data)
        db.session.add(category)
    
    db.session.commit()
    print(f"Inserted {len(default_categories)} default categories into the database.")


# Add CLI command for initialization
import click
@app.cli.command()
def init_db():
    """Initialize the database with default categories."""
    with app.app_context():
        db.create_all()
        print("Tables created!")
        insert_default_categories()
    print("Database initialization completed!")


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("Tablolar oluşturuldu!")
        insert_default_categories()
    app.run(debug=True,use_reloader=False,port=8000)