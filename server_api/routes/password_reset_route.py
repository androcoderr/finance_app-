from flask import Blueprint, request, jsonify, current_app
from flask_mail import Message
from itsdangerous import URLSafeTimedSerializer, SignatureExpired, BadSignature
from werkzeug.security import generate_password_hash
from datetime import datetime, timedelta
from models.user_model import User
from database.db import db
from extension import limiter

password_reset_bp = Blueprint('password_reset', __name__)

# Rate limiting için
reset_attempts = {}


def get_serializer():
    """Token serializer oluştur"""
    return URLSafeTimedSerializer(current_app.config['JWT_SECRET_KEY'])


def check_rate_limit(email):
    """5 dakikada 1 istek limiti"""
    now = datetime.now()
    if email in reset_attempts:
        last_attempt = reset_attempts[email]
        if now - last_attempt < timedelta(minutes=5):
            return False
    reset_attempts[email] = now
    return True


def generate_reset_token(email):
    """Şifre sıfırlama token'ı oluştur"""
    serializer = get_serializer()
    return serializer.dumps(email, salt='password-reset-salt')


def verify_reset_token(token, expiration=1800):
    """Token'ı doğrula (30 dakika geçerlilik)"""
    serializer = get_serializer()
    try:
        email = serializer.loads(
            token,
            salt='password-reset-salt',
            max_age=expiration
        )
        return email
    except (SignatureExpired, BadSignature):
        return None


def send_reset_email(email, token):
    """Şifre sıfırlama email'i gönder"""
    from flask_mail import Mail
    mail = Mail(current_app)

    # Flutter deep link veya web URL
    reset_url = f"yourapp://reset-password?token={token}"

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
                <div class="logo">🔐 FinApp</div>
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
                    {token}...
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
                <p style="color: #999; font-size: 12px;">© 2024 FinApp. Tüm hakları saklıdır.</p>
            </div>
        </div>
    </body>
    </html>
    """

    mail.send(msg)


@password_reset_bp.route('/api/forgot-password', methods=['POST'])
#@limiter.limit("3 per hour")
def forgot_password():
    """Şifre sıfırlama email'i gönder"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email gerekli'}), 400

        # Rate limit kontrolü
        if not check_rate_limit(email):
            return jsonify({
                'error': 'Çok fazla istek. Lütfen 5 dakika sonra tekrar deneyin.'
            }), 429

        # Kullanıcıyı kontrol et
        user = User.query.filter_by(email=email).first()

        if user:
            # Token oluştur ve email gönder
            token = generate_reset_token(email)
            send_reset_email(email, token)
            print(f"✅ Şifre sıfırlama email'i gönderildi: {email}")

        # Güvenlik için her zaman aynı mesajı döndür
        return jsonify({
            'success': True,
            'message': 'Eğer bu email kayıtlıysa, şifre sıfırlama bağlantısı gönderildi'
        }), 200

    except Exception as e:
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Bir hata oluştu'}), 500


@password_reset_bp.route('/api/verify-reset-token', methods=['POST'])
def verify_token_endpoint():
    """Token'ın geçerli olup olmadığını kontrol et"""
    try:
        data = request.get_json()
        token = data.get('token')

        if not token:
            return jsonify({'error': 'Token gerekli'}), 400

        email = verify_reset_token(token)

        if email:
            # Kullanıcının varlığını kontrol et
            user = User.query.filter_by(email=email).first()
            if user:
                return jsonify({
                    'valid': True,
                    'email': email
                }), 200

        return jsonify({
            'valid': False,
            'error': 'Geçersiz veya süresi dolmuş token'
        }), 400

    except Exception as e:
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Token doğrulanamadı'}), 500


@password_reset_bp.route('/api/reset-password', methods=['POST'])
def reset_password():
    """Yeni şifre kaydet"""
    try:
        data = request.get_json()
        token = data.get('token')
        new_password = data.get('password')

        if not token or not new_password:
            return jsonify({'error': 'Token ve şifre gerekli'}), 400

        # Şifre güvenlik kontrolü
        if len(new_password) < 8:
            return jsonify({'error': 'Şifre en az 8 karakter olmalı'}), 400

        # Token'ı doğrula
        email = verify_reset_token(token)
        if not email:
            return jsonify({'error': 'Geçersiz veya süresi dolmuş token'}), 400

        # Kullanıcıyı bul
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        # Şifreyi hashle ve güncelle
        user.password = generate_password_hash(new_password, method='pbkdf2:sha256')
        db.session.commit()

        print(f"✅ Şifre güncellendi: {email}")

        return jsonify({
            'success': True,
            'message': 'Şifreniz başarıyla güncellendi'
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"❌ Hata: {e}")
        return jsonify({'error': 'Şifre güncellenemedi'}), 500


@password_reset_bp.route('/api/test-email', methods=['GET'])
def test_email():
    """Email sistemini test et"""
    try:
        from flask_mail import Mail
        mail = Mail(current_app)

        msg = Message(
            'Test Email - FinApp',
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
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500