"""E-posta gönderimi tek yerde: şifre sıfırlama ve e-posta doğrulama bunu kullanır."""
import os

from flask import current_app
from flask_mail import Mail, Message


def _is_production():
    return os.getenv('APP_ENV') == 'production' or os.getenv('FLASK_ENV') == 'production'


def send_mail(to, subject, html, dev_log=None):
    """E-posta gönderir. Mail ayarlı değilse geliştirmede dev_log'u sunucu loguna yazar
    (emülatörde test için); production'da hata verir."""
    if not current_app.config.get('MAIL_USERNAME'):
        if _is_production():
            raise RuntimeError("MAIL_USERNAME ayarlı değil; e-posta gönderilemiyor.")
        print(f"[DEV] E-posta gönderilmedi (MAIL_USERNAME boş) → {to}: {dev_log or subject}")
        return

    msg = Message(subject, recipients=[to])
    msg.html = html
    Mail(current_app).send(msg)
