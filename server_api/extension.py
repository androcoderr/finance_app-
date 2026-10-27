from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address


def _rate_limit_key():
    """Giriş yapmış kullanıcıyı hesabına göre, diğerlerini IP'ye göre sayar
    (mobil operatörlerde çok kullanıcı aynı IP'yi paylaşabilir)."""
    try:
        verify_jwt_in_request(optional=True)
        identity = get_jwt_identity()
        if identity:
            return f"user:{identity}"
    except Exception:
        pass
    return get_remote_address()


# Tüm uçlar için varsayılan sınır; giriş/şifre gibi hassas uçlar kendi daha sıkı sınırlarını koyar
limiter = Limiter(key_func=_rate_limit_key, default_limits=["300 per minute", "5000 per hour"])
