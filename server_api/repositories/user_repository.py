from database.db import db
from models.user_model import User

class UserRepository:
    """
    UserRepository
    - Sadece veritabanı ile konuşur. (CRUD işlemleri)
    - Hiçbir iş mantığı içermez.
    """
    @staticmethod
    def save(user):
        """Verilen bir kullanıcı nesnesini veritabanına ekler veya günceller."""
        db.session.add(user)
        db.session.commit()
        return user

    @staticmethod
    def get_by_id(user_id):
        return User.query.get(user_id)

    @staticmethod
    def get_all():
        return User.query.all()

    @staticmethod
    def get_by_email(email):
        # Büyük/küçük harf duyarsız (Ayse@Gmail.com == ayse@gmail.com)
        if not email:
            return None
        return User.query.filter(
            db.func.lower(User.email) == email.strip().lower()
        ).first()

    @staticmethod
    def delete(user_id):
        """Verilen ID'ye sahip kullanıcıyı veritabanından siler."""
        user = User.query.get(user_id)
        if user:
            db.session.delete(user)
            db.session.commit()
            return True  # Silme işlemi başarılı
        return False  # Silinecek kullanıcı bulunamadı