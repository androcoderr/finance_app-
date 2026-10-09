from flask import Blueprint, request, jsonify, current_app
from services.user_service import UserService
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from extension import limiter
from database.db import db
from models.user_model import User
from models.two_factor_session_model import TwoFactorSession
from services.firebase_service import FirebaseService
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
        # Rol istemciden ALINMAZ; adminlik yalnızca PUT /users/<id>/role ile verilir
        new_user = userService.create_user(data, role='USER')

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
    """
    Kullanıcıyı doğrular ve JWT token'ları döndürür.
    2FA aktifse push notification gönderir.
    """
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    fcm_token = data.get('fcm_token')  # Frontend'den gelen FCM token

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

    user_obj = User.query.get(user.id)
    requires_2fa = bool(
        current_app.config['TWO_FACTOR_ENABLED']
        and user_obj and user_obj.two_factor_enabled and user_obj.fcm_token
    )

    # FCM token'ı güncelle (varsa). 2FA açıkken GÜNCELLENMEZ: aksi halde onay
    # bildirimi, şifreyi bilen saldırganın kendi cihazına giderdi.
    if fcm_token and not requires_2fa and user_obj.fcm_token != fcm_token:
        try:
            user_obj.fcm_token = fcm_token
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            print(f"⚠️ FCM token güncellenemedi: {e}")

    # 2FA AKTİF Mİ KONTROL ET
    if requires_2fa:
        print(f"🔐 2FA aktif, bildirim gönderiliyor: {user.email}")

        # 2FA session oluştur
        session = TwoFactorSession(
            user_id=user.id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent'),
            device_info=_extract_device_info(request.headers.get('User-Agent'))
        )
        session.pending_fcm_token = fcm_token

        db.session.add(session)
        db.session.commit()

        # Push bildirimi gönder
        notification_sent = FirebaseService.send_2fa_notification(
            fcm_token=user_obj.fcm_token,
            session_token=session.session_token,
            user_email=user.email,
            device_info=session.device_info or 'Bilinmeyen Cihaz'
        )

        if not notification_sent:
            # Güvenlik: bildirim gidemezse 2FA ATLANMAZ
            print("⚠️ 2FA bildirimi gönderilemedi")
            db.session.delete(session)
            db.session.commit()
            return jsonify({
                "error": "Onay bildirimi kayıtlı cihazınıza gönderilemedi. Cihazınıza erişiminiz "
                         "yoksa \"Şifremi Unuttum\" ile şifrenizi sıfırlayın; bu, cihaz bağlantısını da sıfırlar."
            }), 503

        # 2FA bekleniyor durumu
        return jsonify({
            "requires_2fa": True,
            "session_token": session.session_token,
            "message": "Telefonunuza onay bildirimi gönderildi",
            "expires_at": session.expires_at.isoformat(),
            "user_id": user.id  # Frontend için
        }), 202  # 202 Accepted - İşlem devam ediyor

    else:
        # 2FA kapalı, normal giriş
        print(f"✅ Normal giriş: {user.email}")
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)

        return jsonify({
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": user.serialize()
        }), 200


def finish_approved_2fa_session(session):
    """Onaylanmış 2FA oturumunu TEK SEFERLİK token'lara çevirir ve oturumu siler."""
    user = User.query.get(session.user_id)
    # Onaylanan girişin cihazı artık güvenilir cihaz
    if session.pending_fcm_token:
        user.fcm_token = session.pending_fcm_token
    access_token = create_access_token(identity=session.user_id)
    refresh_token = create_refresh_token(identity=session.user_id)
    db.session.delete(session)
    db.session.commit()
    return {
        "status": "approved",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.serialize(),
    }


@auth_bp.route('/2fa/complete/<session_token>', methods=['GET'])
@limiter.limit("20 per minute")
def complete_2fa_login(session_token):
    """
    2FA onaylandıktan sonra token'ları al
    Frontend bu endpoint'i polling ile kontrol edecek
    """
    try:
        session = TwoFactorSession.query.filter_by(session_token=session_token).first()

        if not session:
            return jsonify({"error": "Session bulunamadı"}), 404

        # Süresi dolmuş mu?
        if session.is_expired():
            if session.status == 'pending':
                session.expire()
                db.session.commit()
            return jsonify({
                "status": "expired",
                "error": "Session süresi doldu"
            }), 400

        # Durum kontrolü
        if session.status == 'approved':
            return jsonify(finish_approved_2fa_session(session)), 200

        elif session.status == 'rejected':
            return jsonify({
                "status": "rejected",
                "error": "Giriş reddedildi"
            }), 403

        elif session.status == 'pending':
            return jsonify({
                "status": "pending",
                "message": "Onay bekleniyor",
                "expires_at": session.expires_at.isoformat()
            }), 200

        else:
            return jsonify({
                "status": session.status,
                "error": "Geçersiz durum"
            }), 400

    except Exception as e:
        return server_error(e, '2fa-complete')


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


def _extract_device_info(user_agent):
    """User-Agent'tan cihaz bilgisi çıkar"""
    if not user_agent:
        return "Bilinmeyen Cihaz"

    user_agent = user_agent.lower()

    if 'android' in user_agent:
        return "Android Cihaz"
    elif 'iphone' in user_agent or 'ipad' in user_agent:
        return "iOS Cihaz"
    elif 'windows' in user_agent:
        return "Windows PC"
    elif 'mac' in user_agent:
        return "Mac"
    elif 'linux' in user_agent:
        return "Linux PC"
    else:
        return "Bilinmeyen Cihaz"