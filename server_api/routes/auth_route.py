from flask import Blueprint, request, jsonify
from services.user_service import UserService
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from extension import limiter
from database.db import db
from routes.errors import server_error
from repositories.user_repository import UserRepository
from services import email_verification_service as email_verification

auth_bp = Blueprint('auth_bp', __name__, url_prefix='/auth')
userService = UserService()


@auth_bp.route('/register', methods=['POST'])
@limiter.limit("10 per minute")
def register_user():
    """Yeni bir kullanıcı kaydı oluşturur."""
    try:
        data = request.get_json(silent=True)
        if not isinstance(data, dict):
            return jsonify({"error": "Veri sağlanmadı"}), 400
        # Eski doğrulanmamış kayıtları temizle (ayrı zamanlayıcı gerektirmesin diye burada)
        try:
            email_verification.purge_unverified()
        except Exception as e:
            db.session.rollback()
            print(f"[register] doğrulanmamış hesap temizliği başarısız: {e}")

        new_user = userService.create_user(data)

        # Token e-posta doğrulandıktan sonra verilir (POST /auth/verify-email)
        email_verification.send_code_if_allowed(new_user)
        return jsonify({
            "message": "Doğrulama kodu e-posta adresinize gönderildi",
            "requires_verification": True,
            "email": new_user.email,
        }), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return server_error(e, 'register')


@auth_bp.route('/login', methods=['POST'])
@limiter.limit("5 per minute")
def login_user():
    """Kullanıcıyı doğrular ve JWT token'ları döndürür."""
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')

    if not isinstance(email, str) or not isinstance(password, str) or not email or not password:
        return jsonify({"error": "E-posta ve şifre zorunludur"}), 400
    if len(password) > 128:
        return jsonify({"error": "E-posta veya şifre yanlış"}), 401

    # Kullanıcıyı doğrula
    user = userService.authenticate_user(email, password)

    if not user:
        return jsonify({"error": "E-posta veya şifre yanlış"}), 401

    if not user.email_verified:
        try:
            email_verification.send_code_if_allowed(user)
        except Exception as e:
            print(f"[login] doğrulama kodu gönderilemedi: {e}")
        return jsonify({
            "error": "E-posta adresiniz doğrulanmamış. Adresinize gönderilen kodu girin.",
            "requires_verification": True,
            "email": user.email,
        }), 403

    access_token = create_access_token(identity=user.id)
    refresh_token = create_refresh_token(identity=user.id)
    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.serialize()
    }), 200


@auth_bp.route('/verify-email', methods=['POST'])
@limiter.limit("10 per minute")
def verify_email():
    """Kayıttaki 6 haneli kodu doğrular; başarılıysa giriş token'larını döndürür.
    Şifre de istenir: doğrulanmamış bir adresi başkası tekrar kaydedip şifresini
    değiştirdiyse, eski şifreyle yapılan doğrulama hesabı yabancı şifreyle açmasın."""
    data = request.get_json(silent=True) or {}
    email, code, password = data.get('email'), data.get('code'), data.get('password')
    if not all(isinstance(v, str) and v for v in (email, code, password)):
        return jsonify({"error": "E-posta, kod ve şifre gerekli"}), 400

    user = UserRepository.get_by_email(email)
    if not user or not user.check_password(password):
        return jsonify({"error": "E-posta veya şifre yanlış"}), 400
    if user.email_verified:
        return jsonify({"error": "E-posta adresi zaten doğrulanmış. Giriş yapabilirsiniz."}), 400
    try:
        email_verification.check_code(user, code)
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

    return jsonify({
        "access_token": create_access_token(identity=user.id),
        "refresh_token": create_refresh_token(identity=user.id),
        "user": user.serialize(),
    }), 200


@auth_bp.route('/resend-code', methods=['POST'])
@limiter.limit("5 per minute")
def resend_code():
    """Yeni doğrulama kodu gönderir. Hesabın varlığını sızdırmamak için hep aynı cevabı verir."""
    data = request.get_json(silent=True) or {}
    email = data.get('email')
    message = {"message": "Adres kayıtlı ve doğrulanmamışsa yeni kod gönderildi"}
    if not isinstance(email, str) or not email.strip():
        return jsonify({"error": "E-posta gerekli"}), 400

    user = UserRepository.get_by_email(email)
    if user and not user.email_verified:
        wait = email_verification.cooldown_remaining(user)
        if wait > 0:
            return jsonify({"error": f"Yeni kod için {wait} saniye bekleyin.", "retry_after": wait}), 429
        try:
            email_verification.send_code(user)
        except Exception as e:
            return server_error(e, 'resend-code')
    return jsonify(message), 200


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    """Geçerli bir refresh_token ile yeni bir access_token oluşturur."""
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)
    return jsonify(access_token=new_access_token), 200


@auth_bp.route('/change-password', methods=['PUT'])
@jwt_required()
@limiter.limit("10 per hour")
def change_password():
    """Mevcut şifreyi doğrulayarak kullanıcının şifresini değiştirir."""
    current_user_id = get_jwt_identity()
    data = request.get_json() or {}

    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not old_password or not new_password:
        return jsonify({"error": "Eski ve yeni şifre alanları zorunludur"}), 400

    try:
        success = userService.change_password(current_user_id, old_password, new_password)
        if success:
            # Diğer cihazlardaki oturumlar kapandı; bu cihaz yeni token'larla devam eder
            return jsonify({
                "message": "Şifre başarıyla güncellendi",
                "access_token": create_access_token(identity=current_user_id),
                "refresh_token": create_refresh_token(identity=current_user_id),
            }), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return server_error(e, 'change-password')
