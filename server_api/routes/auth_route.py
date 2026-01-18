from flask import Blueprint, request, jsonify
from services.user_service import UserService
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from extension import limiter
from database.db import db
from models.user_model import User
from models.two_factor_session_model import TwoFactorSession
from services.firebase_service import FirebaseService

auth_bp = Blueprint('auth_bp', __name__, url_prefix='/auth')
userService = UserService()


@auth_bp.route('/register', methods=['POST'])
@limiter.limit("10 per minute")
def register_user():
    """Yeni bir kullanıcı kaydı oluşturur."""
    try:
        data = request.get_json()
        # Check if admin registration is allowed (e.g., first user registration)
        # By default, new users get USER role unless specified otherwise
        role = data.get('role', 'USER')  # Default to USER role
        if role not in ['USER', 'ADMIN']:
            role = 'USER'  # Ensure only valid roles are assigned
        
        new_user = userService.create_user(data, role=role)

        # Kullanıcı oluşturulduktan sonra otomatik olarak login yap ve token döndür
        access_token = create_access_token(identity=new_user.id)
        refresh_token = create_refresh_token(identity=new_user.id)

        return jsonify({
            "message": "Kullanıcı başarıyla oluşturuldu",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": new_user.serialize()
        }), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Sunucu tarafında bir hata oluştu: " + str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
@limiter.limit("5 per minute")
def login_user():
    """
    Kullanıcıyı doğrular ve JWT token'ları döndürür.
    2FA aktifse push notification gönderir.
    """
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    fcm_token = data.get('fcm_token')  # Frontend'den gelen FCM token

    if not email or not password:
        return jsonify({"error": "E-posta ve şifre zorunludur"}), 400

    # Kullanıcıyı doğrula
    user = userService.authenticate_user(email, password)

    if not user:
        return jsonify({"error": "E-posta veya şifre yanlış"}), 401

    # FCM token'ı güncelle (varsa)
    if fcm_token:
        try:
            user_obj = User.query.get(user.id)
            if user_obj and user_obj.fcm_token != fcm_token:
                user_obj.fcm_token = fcm_token
                db.session.commit()
                print(f"✅ FCM token güncellendi: {user.email}")
        except Exception as e:
            print(f"⚠️ FCM token güncellenemedi: {e}")

    # 2FA AKTİF Mİ KONTROL ET
    user_obj = User.query.get(user.id)

    if user_obj and user_obj.two_factor_enabled and user_obj.fcm_token:
        print(f"🔐 2FA aktif, bildirim gönderiliyor: {user.email}")

        # 2FA session oluştur
        session = TwoFactorSession(
            user_id=user.id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent'),
            device_info=_extract_device_info(request.headers.get('User-Agent'))
        )

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
            print("⚠️ Bildirim gönderilemedi, 2FA atlanıyor")
            # Bildirim gönderilemezse normal giriş yap
            access_token = create_access_token(identity=user.id)
            refresh_token = create_refresh_token(identity=user.id)

            return jsonify({
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": user.serialize(),
                "warning": "Bildirim gönderilemedi, 2FA atlandı"
            }), 200

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
            # Token'ları oluştur
            access_token = create_access_token(identity=session.user_id)
            refresh_token = create_refresh_token(identity=session.user_id)

            user = User.query.get(session.user_id)

            # Session'ı temizle (tek kullanımlık)
            db.session.delete(session)
            db.session.commit()

            return jsonify({
                "status": "approved",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": user.serialize()
            }), 200

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
        print(f"❌ 2FA complete hatası: {e}")
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    """Geçerli bir refresh_token ile yeni bir access_token oluşturur."""
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)
    return jsonify(access_token=new_access_token), 200


@auth_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    """Mevcut şifreyi doğrulayarak kullanıcının şifresini değiştirir."""
    current_user_id = get_jwt_identity()
    data = request.get_json()

    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not old_password or not new_password:
        return jsonify({"error": "Eski ve yeni şifre alanları zorunludur"}), 400

    try:
        success = userService.change_password(current_user_id, old_password, new_password)
        if success:
            return jsonify({"message": "Şifre başarıyla güncellendi"}), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Sunucu hatası: " + str(e)}), 500


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