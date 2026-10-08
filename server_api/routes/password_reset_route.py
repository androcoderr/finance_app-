from flask import Blueprint, request, jsonify, current_app, render_template_string
from flask_mail import Message
from itsdangerous import URLSafeTimedSerializer, SignatureExpired, BadSignature
from datetime import datetime, timedelta
import hashlib
import hmac
from models.user_model import User
from repositories.user_repository import UserRepository
from services.user_service import validate_password
from database.db import db
from extension import limiter
from routes.errors import server_error
from flask_jwt_extended import jwt_required
from services.rbac_service import require_role

password_reset_bp = Blueprint('password_reset', __name__)

# Rate limiting için
reset_attempts = {}


def get_serializer():
    """Token serializer oluştur (JWT anahtarından ayrı, uygulamanın SECRET_KEY'i ile)"""
    return URLSafeTimedSerializer(current_app.config['SECRET_KEY'], salt='password-reset-v2')


def check_rate_limit(email):
    """Aynı e-postaya 5 dakikada 1 istek"""
    now = datetime.now()
    # Süresi geçen kayıtları temizle (sözlük sınırsız büyümesin)
    for key in [k for k, t in reset_attempts.items() if now - t >= timedelta(minutes=5)]:
        del reset_attempts[key]
    if email in reset_attempts:
        return False
    reset_attempts[email] = now
    return True


def _password_fingerprint(user):
    """Şifre değişince token'ı geçersiz kılar. Hash'in kendisi değil HMAC'i token'a girer."""
    key = current_app.config['SECRET_KEY'].encode()
    return hmac.new(key, user.password.encode(), hashlib.sha256).hexdigest()[:32]


def generate_reset_token(user):
    """Şifre sıfırlama token'ı (şifre değişince geçersizleşir = tek kullanımlık).
    İçinde yalnızca kullanıcı id'si ve parmak izi var; e-posta/hash okunamaz."""
    return get_serializer().dumps([user.id, _password_fingerprint(user)])


def verify_reset_token(token, expiration=1800):
    """Token'ı doğrula (30 dakika geçerlilik); geçerliyse kullanıcıyı döndürür"""
    if not isinstance(token, str):
        return None
    try:
        user_id, fingerprint = get_serializer().loads(token, max_age=expiration)
    except (SignatureExpired, BadSignature, ValueError, TypeError):
        return None
    user = db.session.get(User, user_id) if isinstance(user_id, str) else None
    if not user or not hmac.compare_digest(str(fingerprint), _password_fingerprint(user)):
        return None
    return user


def send_reset_email(email, token):
    """Şifre sıfırlama email'i gönder"""
    from flask_mail import Mail
    mail = Mail(current_app)

    # Backend'deki web formu (GET /reset-password) — uygulama kurulu olmasa da çalışır
    reset_url = f"{current_app.config['PUBLIC_BASE_URL']}/reset-password?token={token}"

    msg = Message(
        'Şifre Sıfırlama Talebi',
        recipients=[email]
    )
    msg.html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                line-height: 1.6; 
                color: #333;
                margin: 0;
                padding: 0;
            }}
            .container {{ 
                max-width: 600px; 
                margin: 0 auto; 
                padding: 40px 20px;
            }}
            .header {{
                text-align: center;
                margin-bottom: 40px;
            }}
            .logo {{
                font-size: 32px;
                font-weight: bold;
                color: #007bff;
            }}
            .content {{
                background: #ffffff;
                border-radius: 12px;
                padding: 32px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }}
            h2 {{
                color: #007bff;
                margin-top: 0;
            }}
            .button {{ 
                display: inline-block;
                padding: 14px 32px;
                background-color: #007bff;
                color: white !important;
                text-decoration: none;
                border-radius: 8px;
                margin: 24px 0;
                font-weight: 600;
                font-size: 16px;
            }}
            .button:hover {{
                background-color: #0056b3;
            }}
            .token-box {{
                background-color: #f8f9fa;
                padding: 16px;
                border-radius: 8px;
                border-left: 4px solid #007bff;
                margin: 20px 0;
                font-family: 'Courier New', monospace;
                word-break: break-all;
                font-size: 14px;
            }}
            .warning {{
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 12px 16px;
                border-radius: 4px;
                margin: 20px 0;
            }}
            .footer {{
                text-align: center;
                margin-top: 32px;
                padding-top: 24px;
                border-top: 1px solid #eee;
                color: #666;
                font-size: 14px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">Finans Cepte</div>
            </div>

            <div class="content">
                <h2>Şifre Sıfırlama</h2>
                <p>Merhaba,</p>
                <p>Hesabınız için şifre sıfırlama talebinde bulundunuz. Şifrenizi sıfırlamak için aşağıdaki butona tıklayın:</p>

                <center>
                    <a href="{reset_url}" class="button">Şifremi Sıfırla</a>
                </center>

                <p>Eğer buton çalışmazsa, uygulamada aşağıdaki kodu kullanabilirsiniz:</p>
                <div class="token-box">
                    <strong>Sıfırlama Kodu:</strong><br>
                    {token}
                </div>

                <div class="warning">
                    <strong>⏰ Önemli:</strong> Bu bağlantı 30 dakika geçerlidir.
                </div>

                <p style="color: #6c757d; font-size: 14px; margin-top: 24px;">
                    Eğer bu isteği siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz. 
                    Şifreniz değiştirilmeyecektir.
                </p>
            </div>

            <div class="footer">
                <p>Bu otomatik bir e-postadır, lütfen yanıtlamayın.</p>
                <p style="color: #999; font-size: 12px;">© {datetime.now().year} Finans Cepte</p>
            </div>
        </div>
    </body>
    </html>
    """

    mail.send(msg)


@password_reset_bp.route('/api/forgot-password', methods=['POST'])
@limiter.limit("10 per hour")
def forgot_password():
    """Şifre sıfırlama email'i gönder"""
    try:
        data = request.get_json() or {}
        email = data.get('email')
        email = email.strip().lower() if isinstance(email, str) else ''


        if not email:
            return jsonify({'error': 'Email gerekli'}), 400

        # Rate limit kontrolü
        if not check_rate_limit(email):
            return jsonify({
                'error': 'Çok fazla istek. Lütfen 5 dakika sonra tekrar deneyin.'
            }), 429

        # Kullanıcıyı kontrol et
        user = UserRepository.get_by_email(email)

        if user:
            # Token oluştur ve email gönder
            token = generate_reset_token(user)
            send_reset_email(user.email, token)
            print(f"✅ Şifre sıfırlama email'i gönderildi: {user.id}")

        # Güvenlik için her zaman aynı mesajı döndür
        return jsonify({
            'success': True,
            'message': 'Eğer bu email kayıtlıysa, şifre sıfırlama bağlantısı gönderildi'
        }), 200

    except Exception as e:
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Bir hata oluştu'}), 500


@password_reset_bp.route('/api/verify-reset-token', methods=['POST'])
@limiter.limit("30 per hour")
def verify_token_endpoint():
    """Token'ın geçerli olup olmadığını kontrol et"""
    try:
        data = request.get_json() or {}
        token = data.get('token')

        if not token:
            return jsonify({'error': 'Token gerekli'}), 400

        user = verify_reset_token(token)
        if user:
            return jsonify({
                'valid': True,
                'email': user.email
            }), 200

        return jsonify({
            'valid': False,
            'error': 'Geçersiz veya süresi dolmuş token'
        }), 400

    except Exception as e:
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Token doğrulanamadı'}), 500


@password_reset_bp.route('/api/reset-password', methods=['POST'])
@limiter.limit("10 per hour")
def reset_password():
    """Yeni şifre kaydet"""
    try:
        data = request.get_json() or {}
        token = data.get('token')
        new_password = data.get('password')

        if not token or not new_password:
            return jsonify({'error': 'Token ve şifre gerekli'}), 400

        # Şifre güvenlik kontrolü
        try:
            validate_password(new_password)
        except ValueError as e:
            return jsonify({'error': str(e)}), 400

        # Token'ı doğrula
        user = verify_reset_token(token)
        if not user:
            return jsonify({'error': 'Geçersiz veya süresi dolmuş token'}), 400

        # Şifreyi hashle ve güncelle
        user.set_password(new_password)  # token_version'ı da artırır: açık oturumlar kapanır
        # E-posta sahipliği kanıtlandı: kayıp cihaz kurtarması için 2FA cihaz bağlantısını sıfırla
        user.fcm_token = None
        db.session.commit()

        print(f"✅ Şifre güncellendi: {user.id}")

        return jsonify({
            'success': True,
            'message': 'Şifreniz başarıyla güncellendi'
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Şifre güncellenemedi'}), 500


@password_reset_bp.route('/api/test-email', methods=['GET'])
@jwt_required()
@require_role('ADMIN')
def test_email():
    """Email sistemini test et"""
    try:
        from flask_mail import Mail
        mail = Mail(current_app)

        msg = Message(
            'Test Email - Finans Cepte',
            recipients=[current_app.config['MAIL_USERNAME']]
        )
        msg.html = '''
        <h2>✅ Flask-Mail Çalışıyor!</h2>
        <p>Email sistemi başarıyla yapılandırıldı.</p>
        '''
        mail.send(msg)

        return jsonify({
            'success': True,
            'message': 'Test email gönderildi!'
        }), 200

    except Exception as e:
        return server_error(e, 'test-email')


_RESET_PAGE = """<!doctype html>
<html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Şifre Sıfırla · Finans Cepte</title>
<style>
  body{font-family:system-ui,-apple-system,sans-serif;max-width:420px;margin:0 auto;padding:32px 16px;color:#1f2933;background:#fff}
  h1{color:#1565c0;font-size:1.5rem}
  label{display:block;margin:16px 0 6px;font-weight:600}
  input{width:100%;box-sizing:border-box;padding:12px;border:1px solid #cbd2d9;border-radius:8px;font-size:1rem}
  button{width:100%;margin-top:20px;padding:14px;border:0;border-radius:8px;background:#1565c0;color:#fff;font-size:1rem;font-weight:600;cursor:pointer}
  button:disabled{opacity:.6}
  .msg{margin-top:16px;padding:12px;border-radius:8px;display:none}
  .ok{background:#e3f9e5;color:#0e5a1f;display:block} .err{background:#ffe3e3;color:#8a1c1c;display:block}
</style></head><body>
<h1>Yeni şifre belirle</h1>
{% if not token %}<p class="msg err">Bağlantı eksik. Lütfen e-postadaki bağlantıyı tekrar açın.</p>{% else %}
<form id="f">
  <label for="p1">Yeni şifre</label><input id="p1" type="password" minlength="8" required autocomplete="new-password">
  <label for="p2">Yeni şifre (tekrar)</label><input id="p2" type="password" minlength="8" required autocomplete="new-password">
  <button id="b" type="submit">Şifremi güncelle</button>
</form>
<p id="m" class="msg"></p>
<script>
const token = {{ token|tojson }};
document.getElementById('f').addEventListener('submit', async (e) => {
  e.preventDefault();
  const m = document.getElementById('m'), b = document.getElementById('b');
  const p1 = document.getElementById('p1').value, p2 = document.getElementById('p2').value;
  if (p1 !== p2) { m.className = 'msg err'; m.textContent = 'Şifreler eşleşmiyor.'; return; }
  b.disabled = true;
  try {
    const r = await fetch('/api/reset-password', {method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({token, password: p1})});
    const d = await r.json();
    if (r.ok) { m.className = 'msg ok'; m.textContent = 'Şifreniz güncellendi. Uygulamaya dönüp yeni şifrenizle giriş yapabilirsiniz.';
      document.getElementById('f').remove(); }
    else { m.className = 'msg err'; m.textContent = d.error || 'Bir hata oluştu.'; b.disabled = false; }
  } catch (_) { m.className = 'msg err'; m.textContent = 'Sunucuya ulaşılamadı.'; b.disabled = false; }
});
</script>{% endif %}
</body></html>"""


@password_reset_bp.route('/reset-password', methods=['GET'])
def reset_password_page():
    """E-postadaki bağlantının açtığı şifre sıfırlama formu"""
    return render_template_string(_RESET_PAGE, token=request.args.get('token', ''))
