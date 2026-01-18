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
        return User.query.filter_by(email=email).first()

    @staticmethod
    def delete(user_id):
        """Verilen ID'ye sahip kullanıcıyı veritabanından siler."""
        user = User.query.get(user_id)
        if user:
            db.session.delete(user)
            db.session.commit()
            return True  # Silme işlemi başarılı
        return False  # Silinecek kullanıcı bulunamadı