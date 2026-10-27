from flask import jsonify


def server_error(e, where):
    """Beklenmeyen hatayı loglar; istemciye iç ayrıntı (SQL, dosya yolu vb.) sızdırmaz."""
    print(f"[{where}] {type(e).__name__}: {e}")
    try:  # yakalanan hatalar da hata takibine düşsün (SENTRY_DSN yoksa etkisiz)
        import sentry_sdk
        sentry_sdk.capture_exception(e)
    except ImportError:
        pass
    return jsonify({"error": "Sunucu tarafında bir hata oluştu"}), 500
