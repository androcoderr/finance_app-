"""İstemciden gelen verinin ortak kontrolleri. Hatalar kullanıcıya gösterilebilir ValueError olarak döner."""
import math
from datetime import datetime

# Tek işlem/hedef/fatura için üst sınır (1 trilyon ₺) — taşma ve anlamsız veriyi engeller
MAX_AMOUNT = 1_000_000_000_000


def parse_amount(value, field='Tutar', allow_zero=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f"{field} geçerli bir sayı olmalı.")
    if value < 0 or (value == 0 and not allow_zero):
        raise ValueError(f"{field} sıfırdan büyük olmalı.")
    if value > MAX_AMOUNT:
        raise ValueError(f"{field} çok büyük.")
    return float(value)


def parse_text(value, field, max_length, required=False):
    if value is None or value == '':
        if required:
            raise ValueError(f"{field} gerekli.")
        return value
    if not isinstance(value, str):
        raise ValueError(f"{field} metin olmalı.")
    value = value.strip()
    if required and not value:
        raise ValueError(f"{field} gerekli.")
    if len(value) > max_length:
        raise ValueError(f"{field} en fazla {max_length} karakter olabilir.")
    return value


def parse_datetime(value, field='Tarih'):
    """ISO 8601 tarihi (Dart toIso8601String, 'Z' sonekli olabilir) saat dilimsiz datetime'a çevirir."""
    if not isinstance(value, str):
        raise ValueError(f"{field} geçerli bir tarih olmalı.")
    try:
        parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        raise ValueError(f"{field} geçerli bir tarih olmalı.")
    return parsed.replace(tzinfo=None)


def parse_choice(value, field, choices):
    if value not in choices:
        raise ValueError(f"{field} geçersiz.")
    return value


def require_category(category_id):
    from models.category_model import Category
    from database.db import db
    if not isinstance(category_id, str) or not db.session.get(Category, category_id):
        raise ValueError("Kategori bulunamadı.")
    return category_id
