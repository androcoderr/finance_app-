"""E-posta doğrulama kodu: üretme, gönderme, kontrol."""
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta

from flask import current_app

from database.db import db
from services.mail_service import send_mail

CODE_TTL = timedelta(minutes=15)
RESEND_COOLDOWN = timedelta(seconds=60)
MAX_ATTEMPTS = 5


def _hash(code):
    key = current_app.config['SECRET_KEY'].encode()
    return hmac.new(key, code.encode(), hashlib.sha256).hexdigest()


def cooldown_remaining(user):
    """Yeni kod gönderebilmek için kalan saniye (0 = gönderilebilir)."""
    if not user.verification_sent_at:
        return 0
    left = (user.verification_sent_at + RESEND_COOLDOWN - datetime.utcnow()).total_seconds()
    return max(0, int(left + 0.999))


def send_code(user):
    """Yeni kod üretir, HMAC'ini kaydeder ve e-postayla gönderir. Eski kod geçersiz olur."""
    code = f"{secrets.randbelow(1_000_000):06d}"
    now = datetime.utcnow()
    user.verification_code_hash = _hash(code)
    user.verification_expires_at = now + CODE_TTL
    user.verification_sent_at = now
    user.verification_attempts = 0
    db.session.commit()

    html = f"""<!DOCTYPE html><html><body style="font-family:-apple-system,Segoe UI,Arial,sans-serif;color:#1f2933">
<div style="max-width:480px;margin:0 auto;padding:32px 16px">
<h2 style="color:#1565c0">Finans Cepte — E-posta doğrulama</h2>
<p>Hesabınızı doğrulamak için uygulamaya aşağıdaki kodu girin:</p>
<p style="font-size:32px;font-weight:700;letter-spacing:8px;background:#f1f5f9;padding:16px;text-align:center;border-radius:8px">{code}</p>
<p>Kod 15 dakika geçerlidir. Bu isteği siz yapmadıysanız e-postayı görmezden gelebilirsiniz.</p>
</div></body></html>"""
    send_mail(user.email, 'Finans Cepte doğrulama kodu', html, dev_log=f"doğrulama kodu {user.email}: {code}")


def send_code_if_allowed(user):
    """Cooldown izin veriyorsa kod gönderir; gönderdiyse True."""
    if cooldown_remaining(user) > 0:
        return False
    send_code(user)
    return True


def check_code(user, code):
    """Kodu doğrular. Başarılıysa kullanıcıyı doğrulanmış yapar; değilse ValueError (kullanıcıya gösterilebilir)."""
    if not user.verification_code_hash or user.verification_attempts >= MAX_ATTEMPTS:
        raise ValueError("Kod geçersiz. Lütfen yeni kod isteyin.")
    if not user.verification_expires_at or datetime.utcnow() > user.verification_expires_at:
        raise ValueError("Kodun süresi doldu. Lütfen yeni kod isteyin.")
    if not isinstance(code, str) or not hmac.compare_digest(_hash(code.strip()), user.verification_code_hash):
        user.verification_attempts += 1
        db.session.commit()
        left = MAX_ATTEMPTS - user.verification_attempts
        if left <= 0:
            raise ValueError("Çok fazla yanlış deneme. Lütfen yeni kod isteyin.")
        raise ValueError(f"Kod yanlış. {left} deneme hakkınız kaldı.")

    mark_verified(user)


def mark_verified(user):
    user.email_verified = True
    user.verification_code_hash = None
    user.verification_expires_at = None
    user.verification_attempts = 0
    db.session.commit()
