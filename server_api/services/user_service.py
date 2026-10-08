import re

from repositories.user_repository import UserRepository
from models.user_model import User

# Şifre kuralı tek yerde: kayıt, şifre değiştirme ve sıfırlama bunu kullanır
MIN_PASSWORD_LENGTH = 8
_EMAIL_RE = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')


def normalize_email(email):
    return (email or '').strip().lower()


def validate_password(password):
    if not isinstance(password, str) or len(password) < MIN_PASSWORD_LENGTH:
        raise ValueError(f"Şifre en az {MIN_PASSWORD_LENGTH} karakter olmalı.")
    # Çok uzun şifreler hash'lenirken CPU'yu boşuna yorar
    if len(password) > 128:
        raise ValueError("Şifre en fazla 128 karakter olabilir.")


def validate_email(email):
    if len(email) > 100 or not _EMAIL_RE.match(email):
        raise ValueError("Geçerli bir e-posta adresi girin.")


def validate_name(name):
    if not isinstance(name, str) or not name.strip() or len(name.strip()) > 100:
        raise ValueError("İsim 1-100 karakter olmalı.")


class UserService:
    """
    UserService
    - Uygulamanın "beyni"dir. Tüm iş mantığını ve kontrolleri yönetir.
    """

    def __init__(self):
        self.userRepository = UserRepository()

    def create_user(self, data, role='USER'):
        """Yeni bir kullanıcı oluşturur, e-postanın mevcut olup olmadığını kontrol eder."""
        name = data.get('name') if isinstance(data.get('name'), str) else ''
        name = name.strip()
        email = normalize_email(data.get('email') if isinstance(data.get('email'), str) else '')
        if not email or not data.get('password') or not name:
            raise ValueError("İsim, e-posta ve şifre alanları zorunludur.")
        validate_name(name)
        validate_email(email)
        validate_password(data['password'])

        if self.userRepository.get_by_email(email):
            raise ValueError("Bu e-posta adresi zaten kullanılıyor.")

        # User modeli __init__ içinde şifreyi otomatik hash'leyecektir.
        user = User(name=name, email=email, password=data['password'], role=role)
        return self.userRepository.save(user)

    def authenticate_user(self, email, password):
        """Kullanıcıyı doğrular ve başarılı ise kullanıcı nesnesini döndürür."""
        user = self.userRepository.get_by_email(email)
        # Modeldeki check_password metodu ile güvenli kontrol yapılır.
        if user and user.check_password(password):
            return user
        return None

    def get_user_by_id(self, user_id):
        return self.userRepository.get_by_id(user_id)

    def get_all_users(self):
        return self.userRepository.get_all()

    def update_user_profile(self, user_id, data):
        """Kullanıcının adını ve e-postasını günceller."""
        user = self.get_user_by_id(user_id)
        if not user:
            raise ValueError("Kullanıcı bulunamadı.")

        if 'email' in data and not isinstance(data['email'], str):
            raise ValueError("Geçerli bir e-posta adresi girin.")
        if 'email' in data and normalize_email(data['email']) != normalize_email(user.email):
            new_email = normalize_email(data['email'])
            validate_email(new_email)
            if self.userRepository.get_by_email(new_email):
                raise ValueError("Bu e-posta adresi zaten kullanılıyor.")
            user.email = new_email

        if 'name' in data:
            validate_name(data['name'])
            user.name = data['name'].strip()

        return self.userRepository.save(user)

    def change_password(self, user_id, old_password, new_password):
        """Kullanıcının şifresini, eskisini doğrulayarak değiştirir."""
        user = self.get_user_by_id(user_id)
        if not user:
            raise ValueError("Kullanıcı bulunamadı.")

        if not user.check_password(old_password):
            raise ValueError("Eski şifre yanlış.")
        validate_password(new_password)

        user.set_password(new_password)
        self.userRepository.save(user)
        return True

    def delete_user(self, user_id):
        """
        Kullanıcıyı ID'sine göre siler.
        İleride buraya kullanıcıya ait diğer verileri (fotoğraflar, yorumlar vb.)
        temizleme mantığı da eklenebilir.
        """
        was_deleted = self.userRepository.delete(user_id)
        if not was_deleted:
            # Bu hata, JWT token'ı geçerli ama bir şekilde veritabanında olmayan
            # bir kullanıcı senaryosunda ortaya çıkabilir.
            raise ValueError("Silinecek kullanıcı bulunamadı.")

        return True

    def update_user_role(self, user_id, new_role):
        """Updates a user's role by user ID."""
        user = self.get_user_by_id(user_id)
        if not user:
            return None

        user.role = new_role
        return self.userRepository.save(user)