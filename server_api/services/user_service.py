from repositories.user_repository import UserRepository
from models.user_model import User


class UserService:
    """
    UserService
    - Uygulamanın "beyni"dir. Tüm iş mantığını ve kontrolleri yönetir.
    """

    def __init__(self):
        self.userRepository = UserRepository()

    def create_user(self, data, role='USER'):
        """Yeni bir kullanıcı oluşturur, e-postanın mevcut olup olmadığını kontrol eder."""
        if not data.get('email') or not data.get('password') or not data.get('name'):
            raise ValueError("İsim, e-posta ve şifre alanları zorunludur.")

        if self.userRepository.get_by_email(data['email']):
            raise ValueError("Bu e-posta adresi zaten kullanılıyor.")

        # User modeli __init__ içinde şifreyi otomatik hash'leyecektir.
        user = User(name=data['name'], email=data['email'], password=data['password'], role=role)
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

        if 'email' in data and data['email'] != user.email:
            if self.userRepository.get_by_email(data['email']):
                raise ValueError("Bu e-posta adresi zaten kullanılıyor.")
            user.email = data['email']

        if 'name' in data:
            user.name = data['name']

        return self.userRepository.save(user)

    def change_password(self, user_id, old_password, new_password):
        """Kullanıcının şifresini, eskisini doğrulayarak değiştirir."""
        user = self.get_user_by_id(user_id)
        if not user:
            raise ValueError("Kullanıcı bulunamadı.")

        if not user.check_password(old_password):
            raise ValueError("Eski şifre yanlış.")

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