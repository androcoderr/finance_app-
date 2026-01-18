from database.db import db
from datetime import datetime, timedelta
import secrets


class TwoFactorSession(db.Model):
    """
    2FA Oturum Modeli
    Kullanıcı her giriş yaptığında bir session oluşturulur ve 2 dakika sürer.
    """
    __tablename__ = 'two_factor_sessions'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False, index=True)

    session_token = db.Column(db.String(64), unique=True, nullable=False, index=True)

    # Giriş bilgileri
    ip_address = db.Column(db.String(45))  # IPv6 için 45 karakter
    user_agent = db.Column(db.Text)
    device_info = db.Column(db.String(255))

    # Durum: pending, approved, rejected, expired
    status = db.Column(db.String(20), default='pending', nullable=False)

    # Zaman yönetimi
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    responded_at = db.Column(db.DateTime)

    def __init__(self, user_id, ip_address=None, user_agent=None, device_info=None):
        self.user_id = user_id
        self.session_token = secrets.token_urlsafe(32)
        self.ip_address = ip_address
        self.user_agent = user_agent
        self.device_info = device_info
        self.expires_at = datetime.utcnow() + timedelta(minutes=2)  # 2 dakika

    def is_expired(self):
        """Session süresi dolmuş mu?"""
        return datetime.utcnow() > self.expires_at

    def approve(self):
        """Session'ı onayla"""
        self.status = 'approved'
        self.responded_at = datetime.utcnow()

    def reject(self):
        """Session'ı reddet"""
        self.status = 'rejected'
        self.responded_at = datetime.utcnow()

    def expire(self):
        """Session'ı süresi dolmuş olarak işaretle"""
        self.status = 'expired'

    def serialize(self):
        """JSON'a çevir"""
        return {
            'id': self.id,
            'session_token': self.session_token,
            'status': self.status,
            'device_info': self.device_info,
            'ip_address': self.ip_address,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'is_expired': self.is_expired()
        }