from database.db import db
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
from sqlalchemy.orm import relationship
from datetime import datetime


class User(db.Model):
    """
    User Modeli - 2FA özelliği eklenmiş
    """
    __tablename__ = 'users'

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)

    # 2FA için YENİ ALANLAR
    two_factor_enabled = db.Column(db.Boolean, default=False)  # 2FA aktif mi?
    fcm_token = db.Column(db.Text, nullable=True)  # Firebase Cloud Messaging token
    role = db.Column(db.String(20), default='USER', nullable=False)  # ROLE FOR RBAC
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # İlişkiler
    transactions = relationship('UserTransaction', backref='user', lazy=True, cascade="all, delete-orphan")
    goals = relationship('Goal', backref='user', lazy=True, cascade="all, delete-orphan")
    budgets = relationship('Budget', backref='user', lazy=True, cascade="all, delete-orphan")
    recurring_transactions = relationship('RecurringTransaction', backref='user', lazy=True,
                                          cascade="all, delete-orphan")

    # 2FA session ilişkisi
    two_factor_sessions = relationship('TwoFactorSession', backref='user', lazy=True, cascade="all, delete-orphan")

    def __init__(self, name, email, password, role='USER'):
        self.name = name
        self.email = email
        self.role = role
        self.set_password(password)

    def set_password(self, password_to_hash):
        """Gelen şifreyi hash'leyip 'password' sütununa atar."""
        self.password = generate_password_hash(password_to_hash)

    def check_password(self, password_to_check):
        """Gelen şifre ile 'password' sütunundaki hash'i karşılaştırır."""
        return check_password_hash(self.password, password_to_check)

    def serialize(self):
        """Kullanıcı bilgilerini güvenli bir şekilde JSON'a çevirir."""
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'role': self.role,  # YENI
            'two_factor_enabled': self.two_factor_enabled,  # YENİ
            'created_at': self.created_at.isoformat() if self.created_at else None
        }