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

    def create_user(self, data):
        """Yeni bir kullanıcı oluşturur, e-postanın mevcut olup olmadığını kontrol eder."""
        name = data.get('name') if isinstance(data.get('name'), str) else ''
        name = name.strip()
        email = normalize_email(data.get('email') if isinstance(data.get('email'), str) else '')
        if not email or not data.get('password') or not name:
            raise ValueError("İsim, e-posta ve şifre alanları zorunludur.")
        validate_name(name)
        validate_email(email)
        validate_password(data['password'])

        existing = self.userRepository.get_by_email(email)
        if existing:
            if existing.email_verified:
                raise ValueError("Bu e-posta adresi zaten kullanılıyor.")
            # Doğrulanmamış kayıt: adresin gerçek sahibi tekrar kayıt olabilsin (adres kilitlenmesin)
            existing.name = name
            existing.set_password(data['password'])
            return self.userRepository.save(existing)

        # User modeli __init__ içinde şifreyi otomatik hash'leyecektir.
        user = User(name=name, email=email, password=data['password'])
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

    def update_user_profile(self, user_id, data):
        """Kullanıcının adını günceller. E-posta buradan değiştirilemez."""
        user = self.get_user_by_id(user_id)
        if not user:
            raise ValueError("Kullanıcı bulunamadı.")

        # Yeni adres doğrulanmadan değiştirilirse hesap sahibi olunmayan bir adrese bağlanır
        # (doğrulama atlatılır, şifre sıfırlama yanlış adrese gider). Aynı adres gönderilirse sorun yok.
        if 'email' in data and (not isinstance(data['email'], str)
                                or normalize_email(data['email']) != normalize_email(user.email)):
            raise ValueError("E-posta adresi şu an uygulamadan değiştirilemiyor. Destek ile iletişime geçin.")

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
